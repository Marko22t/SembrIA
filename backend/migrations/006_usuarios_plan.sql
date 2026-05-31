-- Plan de suscripción en usuarios
ALTER TABLE usuarios
  ADD COLUMN IF NOT EXISTS plan varchar(20) DEFAULT 'gratuito';

-- Normalizar valores legacy
UPDATE usuarios SET plan = 'gratuito' WHERE plan IS NULL OR plan = 'gratis';
