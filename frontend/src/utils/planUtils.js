/** Plan helpers compartidos frontend/backend logic */
export function normalizePlan(plan) {
  if (!plan || plan === 'gratis') return 'gratuito';
  return plan;
}

export function isFreePlan(plan) {
  return normalizePlan(plan) === 'gratuito';
}
