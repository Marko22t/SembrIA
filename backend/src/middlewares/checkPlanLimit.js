import {
  getUserPlanState,
  isFreePlan,
  LIMITE_GRATUITO,
  countDiagnosticosMes
} from '../services/planService.js';

/**
 * Verifica límite de 10 diagnósticos/mes para plan gratuito.
 * Si no hay usuario_id en el body, deja pasar (visitante sin cuenta).
 */
export const checkPlanLimit = async (req, res, next) => {
  try {
    const usuario_id = req.body?.usuario_id;
    if (!usuario_id) {
      return next();
    }

    const state = await getUserPlanState(usuario_id);
    if (!state) {
      return next();
    }

    const count =
      state.diagnosticos_mes ?? (await countDiagnosticosMes(usuario_id));

    if (isFreePlan(state.plan) && count >= LIMITE_GRATUITO) {
      return res.status(403).json({
        error: 'Límite del plan gratuito alcanzado',
        mensaje:
          'Has usado tus 10 diagnósticos del mes. Cambia a Pro para tener acceso ilimitado.',
        upgrade_url: '/planes',
        diagnosticos_mes: count,
        limite: LIMITE_GRATUITO
      });
    }

    req.planState = state;
    next();
  } catch (err) {
    console.error('Error en checkPlanLimit:', err);
    next();
  }
};
