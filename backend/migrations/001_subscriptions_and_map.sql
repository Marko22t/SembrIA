-- Ejecutar en Supabase SQL Editor si ya tienes la BD creada
-- Suscripciones + coordenadas para mapa

ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS plan VARCHAR(20) DEFAULT 'gratis';
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS diagnosticos_hoy INTEGER DEFAULT 0;
ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS fecha_reset_contador DATE DEFAULT CURRENT_DATE;

ALTER TABLE diagnosticos ADD COLUMN IF NOT EXISTS lat NUMERIC(9, 6);
ALTER TABLE diagnosticos ADD COLUMN IF NOT EXISTS lon NUMERIC(9, 6);

CREATE INDEX IF NOT EXISTS idx_diagnosticos_coords ON diagnosticos(lat, lon) WHERE lat IS NOT NULL;

-- Usuario demo para modo presentación
-- Contraseña: 123456 (mismo hash que seed si ya lo ejecutaste)
UPDATE usuarios SET plan = 'pro' WHERE email = 'juan.mamani@agro.bo';
