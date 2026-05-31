-- Vincular pedidos al vendedor del producto
ALTER TABLE pedidos
  ADD COLUMN IF NOT EXISTS vendedor_id uuid REFERENCES usuarios(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_pedidos_vendedor ON pedidos(vendedor_id);

-- Productos: dueño del catálogo B2C
ALTER TABLE productos
  ADD COLUMN IF NOT EXISTS usuario_id uuid REFERENCES usuarios(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_productos_usuario ON productos(usuario_id);
