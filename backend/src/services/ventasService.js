import { supabase } from '../config/supabase.js';

/**
 * Ventas del vendedor vía pedidos.vendedor_id + productos.precio_bob
 */
export async function obtenerVentasDelVendedor(usuario_id) {
  const { data: pedidos, error } = await supabase
    .from('pedidos')
    .select(
      `
      id,
      cantidad,
      estado,
      created_at,
      producto_id,
      precio_unitario,
      nombre_producto,
      productos (
        nombre,
        precio_bob
      )
    `
    )
    .eq('vendedor_id', usuario_id)
    .order('created_at', { ascending: false });

  if (error) throw error;

  const ventas = (pedidos || []).map((p) => {
    const prod = Array.isArray(p.productos) ? p.productos[0] : p.productos;
    const precioUnitario = Number(p.precio_unitario ?? prod?.precio_bob ?? 0);
    const cantidad = p.cantidad || 1;
    return {
      id: p.id,
      producto: p.nombre_producto ?? prod?.nombre ?? 'Producto',
      cantidad,
      precio_unitario: precioUnitario,
      fecha: p.created_at,
      total: cantidad * precioUnitario,
      estado: p.estado
    };
  });

  const totalBs = ventas.reduce((acc, v) => acc + Number(v.total || 0), 0);

  return { ventas, totalBs };
}
