-- Esquema actual de diagnosticos (CropDoctor hackathon)
-- Ejecutar si la tabla aún tiene columnas antiguas (cultivo, resultado_json, etc.)

ALTER TABLE diagnosticos
  ADD COLUMN IF NOT EXISTS conversacion JSONB DEFAULT '[]'::jsonb;

ALTER TABLE diagnosticos
  ADD COLUMN IF NOT EXISTS respuesta_ia TEXT;

ALTER TABLE diagnosticos
  ADD COLUMN IF NOT EXISTS tiene_imagen BOOLEAN DEFAULT false;

-- Opcional: quitar columnas legacy si ya no se usan
-- ALTER TABLE diagnosticos DROP COLUMN IF EXISTS resultado_json;
-- ALTER TABLE diagnosticos DROP COLUMN IF EXISTS cultivo;
-- ALTER TABLE diagnosticos DROP COLUMN IF EXISTS zona;
