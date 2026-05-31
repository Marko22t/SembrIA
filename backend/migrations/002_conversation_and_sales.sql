-- Migración: conversación en diagnósticos + fecha de venta P2P
-- Ejecutar en Supabase SQL Editor

ALTER TABLE diagnosticos
  ADD COLUMN IF NOT EXISTS conversation JSONB DEFAULT '[]'::jsonb;

ALTER TABLE publicaciones_p2p
  ADD COLUMN IF NOT EXISTS fecha_venta TIMESTAMP WITH TIME ZONE;

CREATE INDEX IF NOT EXISTS idx_diagnosticos_usuario ON diagnosticos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_p2p_vendedor_estado ON publicaciones_p2p(usuario_id, estado);
