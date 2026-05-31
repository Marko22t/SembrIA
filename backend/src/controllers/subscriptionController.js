import { supabase } from '../config/supabase.js';
import {
  getUserPlanState,
  LIMITE_GRATUITO,
  formatUsuarioPlan,
  normalizePlanId,
  isFreePlan,
  PLANES_VALIDOS
} from '../services/planService.js';

function resolveUsuarioId(req) {
  return req.user?.id || req.query?.userId || req.body?.userId || null;
}

function planResponse(usuarioId, state, user) {
  const plan = normalizePlanId(state?.plan || user?.plan);
  return {
    success: true,
    plan,
    diagnosticos_mes: state?.diagnosticos_mes ?? 0,
    diagnosticos_hoy: state?.diagnosticos_mes ?? 0,
    limite_mensual: state?.limite_mensual ?? (isFreePlan(plan) ? LIMITE_GRATUITO : null),
    limite_diario: state?.limite_mensual ?? (isFreePlan(plan) ? LIMITE_GRATUITO : null),
    restantes_mes: state?.restantes_mes ?? null,
    restantes_hoy: state?.restantes_mes ?? null,
    ilimitado: state?.ilimitado ?? !isFreePlan(plan),
    limite_gratis: LIMITE_GRATUITO,
    usuario: formatUsuarioPlan(user),
    beneficios: getBeneficiosPlan(plan)
  };
}

// GET /api/subscription/status — JWT o ?userId=
export const getStatus = async (req, res) => {
  try {
    const usuarioId = resolveUsuarioId(req);

    if (!usuarioId) {
      return res.status(200).json({ plan: 'gratuito', success: true });
    }

    const { data: user, error } = await supabase
      .from('usuarios')
      .select('id, nombre, email, plan, zona_santa_cruz, cultivo_principal, diagnosticos_hoy, fecha_reset_contador, created_at')
      .eq('id', usuarioId)
      .maybeSingle();

    if (error) throw error;

    if (!user) {
      return res.status(200).json({ plan: 'gratuito', success: true });
    }

    const state = await getUserPlanState(usuarioId);
    return res.status(200).json(planResponse(usuarioId, state, user));
  } catch (err) {
    console.error('getStatus:', err.message);
    return res.status(200).json({ plan: 'gratuito', success: true });
  }
};

// Alias completo (compatibilidad App.jsx)
export const getSubscriptionStatus = getStatus;

// POST /api/subscription/change
export const changePlan = async (req, res) => {
  try {
    const usuarioId = resolveUsuarioId(req);
    const nuevoPlan = normalizePlanId(req.body?.nuevoPlan || req.body?.plan);

    if (!usuarioId) {
      return res.status(401).json({ success: false, message: 'Debes iniciar sesión.' });
    }

    if (!PLANES_VALIDOS.includes(nuevoPlan)) {
      return res.status(400).json({
        success: false,
        message: 'Plan inválido. Usa: gratuito, pro o empresa.'
      });
    }

    await new Promise((r) => setTimeout(r, 500));

    const { data, error } = await supabase
      .from('usuarios')
      .update({ plan: nuevoPlan })
      .eq('id', usuarioId)
      .select('id, nombre, email, plan, zona_santa_cruz, cultivo_principal, diagnosticos_hoy, fecha_reset_contador, created_at')
      .single();

    if (error) throw error;

    const state = await getUserPlanState(usuarioId);

    return res.status(200).json({
      success: true,
      plan: nuevoPlan,
      message: `¡Plan ${nuevoPlan.toUpperCase()} activado correctamente!`,
      usuario: formatUsuarioPlan(data),
      diagnosticos_mes: state?.diagnosticos_mes ?? 0,
      diagnosticos_hoy: state?.diagnosticos_mes ?? 0,
      restantes_mes: state?.restantes_mes ?? null,
      restantes_hoy: state?.restantes_mes ?? null,
      ilimitado: state?.ilimitado ?? false
    });
  } catch (err) {
    console.error('changePlan:', err.message);
    return res.status(500).json({ success: false, message: err.message || 'No se pudo cambiar el plan.' });
  }
};

// POST /api/subscription/upgrade — alias
export const upgradeSubscription = changePlan;

function getBeneficiosPlan(plan) {
  const p = normalizePlanId(plan);
  const base = {
    gratuito: [
      '10 diagnósticos por mes',
      'Historial de últimos 10 diagnósticos',
      'Marketplace completo',
      'Clima agrícola',
      'Mapa de plagas (lectura)'
    ],
    pro: [
      'Diagnósticos ilimitados',
      'Historial completo',
      'Alertas climáticas personalizadas',
      'Exportar historial PDF',
      'Badge Agricultor Pro 👑',
      'Soporte WhatsApp'
    ],
    empresa: [
      'Todo lo de Pro',
      'Panel vendedor marketplace',
      'Analítica de campo',
      'Hasta 10 usuarios',
      'API key propia',
      'Badge Empresa 🏢'
    ]
  };
  return base[p] || base.gratuito;
}
