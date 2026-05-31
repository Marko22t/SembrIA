import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import {
  Activity,
  PiggyBank,
  History as HistoryIcon,
  LineChart,
  Shield,
  Lock,
  ShoppingBag
} from 'lucide-react';
import WeatherWidget from '../components/WeatherWidget.jsx';
import PlanBadge from '../components/PlanBadge.jsx';
import { supabase } from '../lib/supabase.js';

function truncar(texto, max = 40) {
  if (!texto) return 'Diagnóstico';
  return texto.length > max ? `${texto.slice(0, max)}…` : texto;
}

function getConversacionLista(diag) {
  if (Array.isArray(diag.conversacion) && diag.conversacion.length > 0) {
    return diag.conversacion;
  }
  if (Array.isArray(diag.conversation) && diag.conversation.length > 0) {
    return diag.conversation;
  }
  const userLine = diag.descripcion_texto || 'Consulta agrícola';
  const assistantLine =
    diag.respuesta_ia ||
    (diag.resultado_json?.problema
      ? `**${diag.resultado_json.problema}**`
      : 'Diagnóstico registrado en SembrIA.');

  return [
    { role: 'user', content: userLine, hasImage: diag.tiene_imagen },
    { role: 'assistant', content: assistantLine }
  ];
}

function contarIntercambios(conversacion) {
  if (!conversacion?.length) return 0;
  const paresUsuario = conversacion.filter((m) => m.role === 'user').length;
  return Math.max(1, paresUsuario);
}

function StatSkeleton() {
  return (
    <span className="inline-block h-8 w-14 bg-gray-200 rounded animate-pulse" aria-hidden />
  );
}

export default function History({
  usuario,
  token,
  subStatus,
  clima,
  climaCargando,
  onRefreshClima,
  onAuthRedirect,
  refreshKey
}) {
  const [history, setHistory] = useState([]);
  const [ventas, setVentas] = useState([]);
  const [stats, setStats] = useState({
    diagnosticos: 0,
    productosVendidos: 0,
    totalVentas: 0
  });
  const [loading, setLoading] = useState(true);
  const [loadingStats, setLoadingStats] = useState(true);
  const [activeChartDot, setActiveChartDot] = useState(null);
  const [selectedDiagnosis, setSelectedDiagnosis] = useState(null);
  const [showDiagnosisModal, setShowDiagnosisModal] = useState(false);

  const cargarDatos = useCallback(async () => {
    if (!usuario?.id) return;

    setLoading(true);
    setLoadingStats(true);

    try {
      // 1. Conteo de diagnósticos
      const { count: totalDiagnosticos, error: errDiag } = await supabase
        .from('diagnosticos')
        .select('*', { count: 'exact', head: true })
        .eq('usuario_id', usuario.id);

      if (errDiag) throw errDiag;

      // 2. Pedidos/ventas del vendedor
      const { data: ventasData, error: errVentas } = await supabase
        .from('pedidos')
        .select(`
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
        `)
        .eq('vendedor_id', usuario.id)
        .eq('estado', 'completado')
        .order('created_at', { ascending: false });

      console.log('Ventas encontradas:', ventasData, 'Error:', errVentas);
      if (errVentas) throw errVentas;

      // 3. Historial de diagnósticos
      const { data: diagData, error: errDiagHist } = await supabase
        .from('diagnosticos')
        .select('id, usuario_id, imagen_url, descripcion_texto, conversacion, respuesta_ia, tiene_imagen, created_at')
        .eq('usuario_id', usuario.id)
        .order('created_at', { ascending: false });

      if (errDiagHist) throw errDiagHist;

      const totalProductosVendidos = ventasData?.length || 0;
      const totalBs = ventasData?.reduce((acc, v) => {
        const prod = Array.isArray(v.productos) ? v.productos[0] : v.productos;
        const precio = Number(v.precio_unitario ?? prod?.precio_bob ?? 0);
        return acc + (v.cantidad * precio);
      }, 0) || 0;

      setStats({
        diagnosticos: totalDiagnosticos || 0,
        productosVendidos: totalProductosVendidos,
        totalVentas: totalBs
      });
      setVentas(ventasData || []);
      setHistory(diagData || []);
    } catch (err) {
      console.error('Error cargando Mi Campo:', err);
      setStats({ diagnosticos: 0, productosVendidos: 0, totalVentas: 0 });
      setVentas([]);
      setHistory([]);
    } finally {
      setLoading(false);
      setLoadingStats(false);
    }
  }, [usuario?.id]);

  useEffect(() => {
    if (!usuario?.id) {
      setLoading(false);
      setLoadingStats(false);
      return;
    }
    cargarDatos();
  }, [usuario?.id, token, refreshKey, cargarDatos]);

  useEffect(() => {
    const handler = () => {
      if (usuario?.id && token) cargarDatos();
    };
    window.addEventListener('stats-actualizar', handler);
    return () => window.removeEventListener('stats-actualizar', handler);
  }, [usuario?.id, token, cargarDatos]);

  if (!usuario) {
    return (
      <div className="max-w-4xl mx-auto px-4 py-20 text-center space-y-6">
        <div className="w-16 h-16 bg-green-50 border border-green-200 text-primary rounded-full flex items-center justify-center mx-auto shadow-sm">
          <Lock className="w-6 h-6" />
        </div>
        <div className="max-w-md mx-auto space-y-2">
          <h2 className="text-2xl font-extrabold text-primary-dark">Monitoreo Fitosanitario y Dashboard</h2>
          <p className="text-gray-500 text-sm">
            Para ver tu historial de diagnósticos, ventas en el marketplace y el rendimiento de tu
            campo, inicia sesión en SembrIA.
          </p>
        </div>
        <button
          type="button"
          onClick={onAuthRedirect}
          className="bg-primary hover:bg-primary-dark text-white font-bold px-8 py-3.5 rounded-xl shadow-md hover:shadow-lg transition-all duration-300"
        >
          Iniciar Sesión
        </button>
      </div>
    );
  }

  if (loading && loadingStats) {
    return (
      <div className="max-w-6xl mx-auto px-4 py-24 text-center space-y-4">
        <div className="w-10 h-10 border-4 border-gray-200 border-t-primary rounded-full animate-spin mx-auto" />
        <p className="text-sm text-gray-500 font-semibold">Consultando base de datos de tu campo...</p>
      </div>
    );
  }

  const diagnosesList = history || [];
  const ventasList = ventas || [];
  const totalVendido = ventasList?.reduce((acc, v) => {
    const prod = Array.isArray(v.productos) ? v.productos[0] : v.productos;
    const precio = Number(v.precio_unitario ?? prod?.precio_bob ?? 0);
    return acc + (v.cantidad * precio);
  }, 0) || 0;

  const chartData = [
    { month: 'Ene', count: 1 },
    { month: 'Feb', count: 2 },
    { month: 'Mar', count: 5 },
    { month: 'Abr', count: 7 },
    { month: 'May', count: Math.max(stats.diagnosticos, 1) },
    { month: 'Jun', count: stats.diagnosticos }
  ];

  const openDiagnosis = (diag) => {
    setSelectedDiagnosis({
      ...diag,
      conversacion: getConversacionLista(diag)
    });
    setShowDiagnosisModal(true);
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-12 pb-24 space-y-12">
      <div className="bg-white border border-gray-100 p-6 sm:p-8 rounded-3xl shadow-sm flex flex-col sm:flex-row items-start sm:items-center justify-between gap-6">
        <div className="space-y-1">
          <h2 className="text-2xl sm:text-3xl font-extrabold text-primary-dark flex items-center flex-wrap gap-1">
            Hola, {usuario.nombre}
            <PlanBadge plan={usuario.plan} />
          </h2>
          <p className="text-sm text-gray-500">
            Monitoreo agronómico activo para tu parcela en{' '}
            <strong className="text-gray-700">{usuario.zona_santa_cruz}</strong>.
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center gap-2 bg-green-50 border border-green-150 text-primary text-xs font-black uppercase tracking-wider px-3.5 py-1.5 rounded-full">
            <Shield className="w-4 h-4" /> Productor Verificado
          </div>
          {subStatus && (subStatus.plan === 'gratis' || subStatus.plan === 'gratuito') && (
            <span className="text-xs text-gray-500 font-semibold">
              {(subStatus.diagnosticos_mes ?? subStatus.diagnosticos_hoy)}/{subStatus.limite_gratis} diagnósticos este mes
            </span>
          )}
        </div>
      </div>

      <WeatherWidget
        clima={clima}
        cargando={climaCargando}
        onRefresh={onRefreshClima}
        compact={false}
      />

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
        <div className="bg-white border border-gray-100 p-6 rounded-2xl shadow-sm flex items-center gap-4">
          <div className="bg-green-50 p-3 rounded-xl text-primary flex-shrink-0">
            <Activity className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-2xl font-black text-gray-900">
              {loadingStats ? <StatSkeleton /> : stats.diagnosticos}
            </h3>
            <p className="text-xs text-gray-400 font-bold uppercase tracking-wider mt-0.5">
              Diagnósticos Realizados
            </p>
          </div>
        </div>

        <div className="bg-white border border-gray-100 p-6 rounded-2xl shadow-sm flex items-center gap-4">
          <div className="bg-green-50 p-3 rounded-xl text-primary flex-shrink-0">
            <ShoppingBag className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-2xl font-black text-gray-900">
              {loadingStats ? <StatSkeleton /> : stats.productosVendidos}
            </h3>
            <p className="text-xs text-gray-400 font-bold uppercase tracking-wider mt-0.5">
              Productos Vendidos
            </p>
          </div>
        </div>

        <div className="bg-white border border-gray-100 p-6 rounded-2xl shadow-sm flex items-center gap-4">
          <div className="bg-green-50 p-3 rounded-xl text-primary flex-shrink-0">
            <PiggyBank className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-2xl font-black text-gray-900">
              {loadingStats ? (
                <StatSkeleton />
              ) : (
                <>Bs {stats.totalVentas.toFixed(2)}</>
              )}
            </h3>
            <p className="text-xs text-gray-400 font-bold uppercase tracking-wider mt-0.5">
              Total en Ventas
            </p>
          </div>
        </div>
      </div>

      <div className="bg-white border border-gray-100 rounded-3xl p-6 sm:p-8 shadow-sm space-y-6">
        <h4 className="font-extrabold text-gray-900 flex items-center gap-2.5">
          <ShoppingBag className="w-5 h-5 text-primary" /> Historial de Ventas
        </h4>

        {ventasList.length === 0 ? (
          <p className="text-sm text-gray-500 text-center py-8 bg-gray-50 rounded-xl border border-dashed border-gray-200">
            Aún no tienes ventas registradas
          </p>
        ) : (
          <>
            <div className="overflow-x-auto w-full">
              <table className="min-w-full text-left text-sm">
                <thead>
                  <tr className="border-b-2 border-gray-100 text-gray-400 text-xs font-bold uppercase tracking-wider">
                    <th className="py-3 px-2">Producto</th>
                    <th className="py-3 px-2">Cantidad</th>
                    <th className="py-3 px-2">Precio unit. (Bs)</th>
                    <th className="py-3 px-2">Fecha</th>
                    <th className="py-3 px-2 text-right">Total (Bs)</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-50">
                  {ventasList.map((v) => {
                    const prod = Array.isArray(v.productos) ? v.productos[0] : v.productos;
                    const nombreProd = v.nombre_producto ?? prod?.nombre ?? 'Sin nombre';
                    const precioProd = Number(v.precio_unitario ?? prod?.precio_bob ?? 0);
                    return (
                      <tr key={v.id} className="text-gray-700 hover:bg-gray-50 transition-colors">
                        <td className="py-4 px-2 font-bold text-gray-900">{nombreProd}</td>
                        <td className="py-4 px-2">{v.cantidad}</td>
                        <td className="py-4 px-2">Bs {precioProd.toFixed(2)}</td>
                        <td className="py-4 px-2 text-xs text-gray-500">
                          {new Date(v.created_at).toLocaleDateString('es-BO')}
                        </td>
                        <td className="py-4 px-2 text-right font-bold text-primary">
                          Bs {(v.cantidad * precioProd).toFixed(2)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            <div className="mt-4 p-4 bg-green-50 rounded-xl border border-green-200">
              <p className="text-lg font-bold text-green-800">
                Total vendido: Bs {totalVendido.toFixed(2)}
              </p>
              <p className="text-xs text-green-600 mt-1">
                Pedidos de compradores sobre tus productos del marketplace (filtrado por tu cuenta).
              </p>
            </div>
          </>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 bg-white border border-gray-100 rounded-3xl p-6 sm:p-8 shadow-sm space-y-6">
          <h4 className="font-extrabold text-gray-900 flex items-center gap-2.5">
            <HistoryIcon className="w-5 h-5 text-primary" /> Historial de Diagnósticos
          </h4>

          {diagnosesList.length === 0 ? (
            <p className="text-sm text-gray-500 text-center py-8 bg-gray-50 rounded-xl border border-dashed border-gray-200">
              Aún no tienes diagnósticos realizados. Ve a Diagnosticar para analizar tu cultivo.
            </p>
          ) : (
            <div className="space-y-3">
              {diagnosesList.map((diag, index) => {
                const conv = getConversacionLista(diag);
                const intercambios = contarIntercambios(conv);
                return (
                  <div
                    key={diag.id || index}
                    role="button"
                    tabIndex={0}
                    className="cursor-pointer hover:bg-green-50 transition-colors p-4 rounded-xl border border-gray-100"
                    onClick={() => openDiagnosis(diag)}
                    onKeyDown={(e) => e.key === 'Enter' && openDiagnosis(diag)}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex-1 min-w-0">
                        <p className="font-semibold text-gray-900 flex items-center gap-2 flex-wrap">
                          <span className="truncate">{diag.descripcion_texto || 'Diagnóstico'}</span>
                          {diag.tiene_imagen && (
                            <span className="text-base shrink-0" title="Incluye imagen">
                              📷
                            </span>
                          )}
                        </p>
                        <p className="text-sm text-gray-500 mt-1">
                          {new Date(diag.created_at).toLocaleDateString('es-BO', {
                            day: 'numeric',
                            month: 'short',
                            year: 'numeric'
                          })}
                        </p>
                        <p className="text-xs text-gray-400 mt-1">
                        {Math.floor((diag.conversacion?.length || conv.length || 0) / 2)}{' '}
                        intercambio
                        {Math.floor((diag.conversacion?.length || conv.length || 0) / 2) !== 1
                          ? 's'
                          : ''}
                      </p>
                        <p className="text-xs text-green-600 font-semibold mt-2">
                          Ver conversación →
                        </p>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        <div className="bg-white border border-gray-100 rounded-3xl p-6 sm:p-8 shadow-sm space-y-6 flex flex-col justify-between">
          <h4 className="font-extrabold text-gray-900 flex items-center gap-2.5">
            <LineChart className="w-5 h-5 text-primary" /> Incidencia de Plagas por Mes
          </h4>

          <div className="relative pt-4 h-48 w-full flex items-end">
            <svg
              className="w-full h-full overflow-visible"
              viewBox="0 0 300 150"
              preserveAspectRatio="none"
            >
              <defs>
                <linearGradient id="curveGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#16a34a" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#16a34a" stopOpacity="0" />
                </linearGradient>
              </defs>
              <line x1="0" y1="30" x2="300" y2="30" stroke="#f1f5f9" strokeWidth="1.5" strokeDasharray="4" />
              <line x1="0" y1="75" x2="300" y2="75" stroke="#f1f5f9" strokeWidth="1.5" strokeDasharray="4" />
              <line x1="0" y1="120" x2="300" y2="120" stroke="#f1f5f9" strokeWidth="1.5" strokeDasharray="4" />
              <path
                d="M 10 135 Q 60 120, 110 80 T 210 50 T 290 30 L 290 135 Z"
                fill="url(#curveGrad)"
              />
              <path
                d="M 10 135 Q 60 120, 110 80 T 210 50 T 290 30"
                fill="none"
                stroke="#16a34a"
                strokeWidth="3"
                strokeLinecap="round"
              />
              {chartData.map((d, idx) => {
                const cx =
                  idx === 0 ? 10 : idx === 1 ? 66 : idx === 2 ? 122 : idx === 3 ? 178 : idx === 4 ? 234 : 290;
                const cy =
                  idx === 0 ? 135 : idx === 1 ? 122 : idx === 2 ? 78 : idx === 3 ? 62 : idx === 4 ? 46 : 30;
                return (
                  <circle
                    key={d.month}
                    cx={cx}
                    cy={cy}
                    r="5.5"
                    fill="#FFFFFF"
                    stroke="#16a34a"
                    strokeWidth="2.5"
                    className="cursor-pointer"
                    onMouseEnter={() =>
                      setActiveChartDot({ month: d.month, count: d.count, x: cx, y: cy })
                    }
                    onMouseLeave={() => setActiveChartDot(null)}
                  />
                );
              })}
            </svg>
            {activeChartDot && (
              <div
                className="absolute bg-gray-900 text-white rounded-lg px-2.5 py-1 text-[10px] font-black pointer-events-none shadow-lg -translate-x-1/2 -translate-y-[135%]"
                style={{
                  left: `${(activeChartDot.x / 300) * 100}%`,
                  top: `${(activeChartDot.y / 150) * 100}%`
                }}
              >
                {activeChartDot.month}: {activeChartDot.count} plagas
              </div>
            )}
          </div>

          <div className="flex justify-between text-[10px] text-gray-400 font-bold uppercase tracking-wider px-2">
            {chartData.map((d) => (
              <span key={d.month}>{d.month}</span>
            ))}
          </div>
        </div>
      </div>

      {showDiagnosisModal && selectedDiagnosis && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full max-h-[85vh] overflow-hidden flex flex-col shadow-2xl">
            <div className="flex justify-between items-start gap-3 p-4 border-b shrink-0">
              <div>
                <h3 className="font-bold text-lg text-primary-dark">
                  Diagnóstico — {truncar(selectedDiagnosis.descripcion_texto, 40)}
                </h3>
                <p className="text-xs text-gray-500 mt-1">
                  {new Date(selectedDiagnosis.created_at).toLocaleDateString('es-BO', {
                    weekday: 'long',
                    day: 'numeric',
                    month: 'long',
                    year: 'numeric'
                  })}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setShowDiagnosisModal(false)}
                className="text-gray-500 hover:text-gray-800 text-2xl leading-none p-1"
                aria-label="Cerrar"
              >
                ×
              </button>
            </div>

            {selectedDiagnosis.tiene_imagen && selectedDiagnosis.imagen_url && (
              <div className="px-4 pt-3 shrink-0">
                <img
                  src={selectedDiagnosis.imagen_url}
                  alt="Muestra del cultivo"
                  className="w-full max-h-40 object-cover rounded-xl border border-gray-200"
                />
              </div>
            )}

            <div className="overflow-y-auto p-4 flex flex-col gap-3 flex-1 min-h-0">
              {(selectedDiagnosis.conversacion || []).map((msg, i) => (
                <div
                  key={i}
                  className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
                >
                  <div
                    className={`max-w-[85%] p-3 rounded-xl text-sm whitespace-pre-wrap ${
                      msg.role === 'user'
                        ? 'bg-green-600 text-white rounded-br-none'
                        : 'bg-gray-100 text-gray-800 rounded-bl-none'
                    }`}
                  >
                    {msg.role === 'user' && msg.hasImage && (
                      <span className="block text-xs opacity-90 mb-1">📷 Con foto</span>
                    )}
                    {msg.content}
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
