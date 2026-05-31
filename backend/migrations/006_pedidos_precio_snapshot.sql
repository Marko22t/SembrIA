-- Migration to add snapshot columns to pedidos for offline/resilient storage
ALTER TABLE pedidos
  ADD COLUMN IF NOT EXISTS precio_unitario numeric(10, 2),
  ADD COLUMN IF NOT EXISTS nombre_producto varchar(200);
