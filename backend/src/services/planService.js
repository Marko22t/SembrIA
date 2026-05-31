import { supabase } from '../config/supabase.js';

export const LIMITE_GRATUITO = 10;
/** @deprecated usar LIMITE_GRATUITO */
export const LIMITE_GRATIS_DIARIO = LIMITE_GRATUITO;
export const LIMITE_HISTORIAL_GRATIS = 10;
export const PLANES_VALIDOS = ['gratuito', 'gratis', 'pro', 'empresa'];

/** Canonical plan id for API/UI */
export function normalizePlanId(plan) {
  if (!plan || plan === 'gratis') return 'gratuito';
  return plan;
}

export function isFreePlan(plan) {
  const p = normalizePlanId(plan);
  return p === 'gratuito';
}

/** Coordenadas aproximadas por zona de Santa Cruz */
export function getZonaCoords(zona) {
  const z = (zona || '').toLowerCase().trim();
  const map = {
    'norte integrado': { lat: -16.5, lon: -63.2 },
    'sur integrado': { lat: -18.2, lon: -63.5 },
    sur: { lat: -18.2, lon: -63.5 },
    este: { lat: -17.5, lon: -61.8 },
    chiquitanía: { lat: -16.8, lon: -61.0 },
    chiquitania: { lat: -16.8, lon: -61.0 },
    valles: { lat: -18.5, lon: -64.2 },
    ciudad: { lat: -17.78, lon: -63.18 }
  };
  return map[z] || { lat: -17.78, lon: -63.18 };
}

export function inicioMesActual() {
  const inicioMes = new Date();
  inicioMes.setDate(1);
  inicioMes.setHours(0, 0, 0, 0);
  return inicioMes;
}

/** Cuenta diagnósticos del mes calendario actual */
export async function countDiagnosticosMes(usuarioId) {
  const { count, error } = await supabase
    .from('diagnosticos')
    .select('*', { count: 'exact', head: true })
    .eq('usuario_id', usuarioId)
    .gte('created_at', inicioMesActual().toISOString());

  if (error) {
    console.error('countDiagnosticosMes:', error.message);
    return 0;
  }
  return count ?? 0;
}

export function formatUsuarioPlan(row) {
  if (!row) return null;
  return {
    id: row.id,
    nombre: row.nombre,
    email: row.email,
    zona_santa_cruz: row.zona_santa_cruz,
    cultivo_principal: row.cultivo_principal,
    created_at: row.created_at,
    plan: normalizePlanId(row.plan)
  };
}

/** Obtiene plan del usuario y uso mensual de diagnósticos */
export async function getUserPlanState(usuarioId) {
  const { data: user, error } = await supabase
    .from('usuarios')
    .select('id, plan, nombre, email')
    .eq('id', usuarioId)
    .maybeSingle();

  if (error || !user) return null;

  const plan = normalizePlanId(user.plan);
  const diagnosticos_mes = await countDiagnosticosMes(usuarioId);
  const limite = isFreePlan(plan) ? LIMITE_GRATUITO : null;

  return {
    plan,
    diagnosticos_mes,
    /** alias legacy para compatibilidad con clientes antiguos */
    diagnosticos_hoy: diagnosticos_mes,
    limite_mensual: limite,
    limite_diario: limite,
    restantes_mes: limite !== null ? Math.max(0, limite - diagnosticos_mes) : null,
    restantes_hoy: limite !== null ? Math.max(0, limite - diagnosticos_mes) : null,
    ilimitado: plan === 'pro' || plan === 'empresa'
  };
}

/** Ya no incrementa contador en usuarios; el conteo es por filas en diagnosticos */
export async function incrementDiagnosticoCount() {}
