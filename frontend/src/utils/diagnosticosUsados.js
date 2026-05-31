export const DIAGNOSTICOS_STORAGE_KEY = 'diagnosticos_usados';
export const LIMITE_DIAGNOSTICOS_MES = 10;

export function getDiagnosticosUsados() {
  if (typeof window === 'undefined') return 0;
  const raw = localStorage.getItem(DIAGNOSTICOS_STORAGE_KEY);
  const n = parseInt(raw, 10);
  return Number.isFinite(n) && n >= 0 ? n : 0;
}

export function incrementDiagnosticosUsados() {
  const next = Math.min(LIMITE_DIAGNOSTICOS_MES, getDiagnosticosUsados() + 1);
  localStorage.setItem(DIAGNOSTICOS_STORAGE_KEY, String(next));
  window.dispatchEvent(new CustomEvent('diagnosticos-usados-actualizar'));
  return next;
}

export function isLimiteDiagnosticosAlcanzado() {
  return getDiagnosticosUsados() >= LIMITE_DIAGNOSTICOS_MES;
}

export function diagnosticosRestantes() {
  return Math.max(0, LIMITE_DIAGNOSTICOS_MES - getDiagnosticosUsados());
}
