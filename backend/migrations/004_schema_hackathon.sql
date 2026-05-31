-- Ejecutar en Supabase SQL Editor antes de desplegar fixes

ALTER TABLE diagnosticos ALTER COLUMN resultado_json DROP NOT NULL;

ALTER TABLE diagnosticos ADD COLUMN IF NOT EXISTS conversacion jsonb DEFAULT '[]'::jsonb;

ALTER TABLE diagnosticos ADD COLUMN IF NOT EXISTS respuesta_ia text;

ALTER TABLE diagnosticos ADD COLUMN IF NOT EXISTS tiene_imagen boolean DEFAULT false;

-- Vendedor en marketplace B2C (si aún no existe)
ALTER TABLE productos ADD COLUMN IF NOT EXISTS usuario_id uuid REFERENCES usuarios(id) ON DELETE SET NULL;
