import { supabase } from '../config/supabase.js';
import { obtenerVentasDelVendedor } from '../services/ventasService.js';

/**
 * Estadísticas Mi Campo — solo usuario autenticado (JWT).
 * Diagnósticos: diagnosticos.usuario_id
 * Ventas: pedidos de productos donde productos.usuario_id = vendedor
 */
export const getDashboardStats = async (req, res) => {
  try {
    const usuario_id = req.user.id;

    const { count: totalDiagnosticos, error: errDiag } = await supabase
      .from('diagnosticos')
      .select('*', { count: 'exact', head: true })
      .eq('usuario_id', usuario_id);

    if (errDiag) throw errDiag;

    const { ventas, totalBs } = await obtenerVentasDelVendedor(usuario_id);

    return res.status(200).json({
      diagnosticos: totalDiagnosticos ?? 0,
      productosVendidos: ventas.length,
      totalVentas: totalBs,
      ventas
    });
  } catch (err) {
    console.error('getDashboardStats:', err.message);
    return res.status(200).json({
      diagnosticos: 0,
      productosVendidos: 0,
      totalVentas: 0,
      ventas: []
    });
  }
};
