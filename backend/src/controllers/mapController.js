import { supabase } from '../config/supabase.js';
import { MAPA_DEMO_POINTS } from '../data/mapaDemoPoints.js';

function extraerUrgencia(resultado_json) {
  if (!resultado_json) return 'MEDIA';
  return (
    resultado_json.nivel_urgencia ||
    resultado_json.urgencia ||
    'MEDIA'
  ).toUpperCase();
}

function extraerProblema(resultado_json) {
  if (!resultado_json) return 'Diagnóstico fitosanitario';
  return resultado_json.problema || 'Problema no especificado';
}

// GET /api/map/diagnosticos — puntos anónimos para mapa
export const getMapaDiagnosticos = async (req, res) => {
  try {
    const { data: rows, error } = await supabase
      .from('diagnosticos')
      .select('lat, lon, cultivo, zona, created_at, resultado_json')
      .not('lat', 'is', null)
      .not('lon', 'is', null)
      .order('created_at', { ascending: false })
      .limit(200);

    if (error) throw error;

    const desdeDb = (rows || []).map((r) => ({
      lat: parseFloat(r.lat),
      lon: parseFloat(r.lon),
      problema: extraerProblema(r.resultado_json),
      urgencia: extraerUrgencia(r.resultado_json),
      cultivo: r.cultivo,
      zona: r.zona,
      fecha: r.created_at
        ? new Date(r.created_at).toISOString().split('T')[0]
        : null
    }));

    const puntos = desdeDb.length >= 5 ? desdeDb : [...desdeDb, ...MAPA_DEMO_POINTS];

    const unaSemanaAtras = Date.now() - 7 * 24 * 60 * 60 * 1000;
    const estaSemana = puntos.filter((p) => {
      if (!p.fecha) return true;
      return new Date(p.fecha).getTime() >= unaSemanaAtras;
    });

    return res.status(200).json({
      total: puntos.length,
      esta_semana: estaSemana.length || puntos.length,
      puntos
    });
  } catch (err) {
    console.error('getMapaDiagnosticos:', err);
    return res.status(200).json({
      total: MAPA_DEMO_POINTS.length,
      esta_semana: MAPA_DEMO_POINTS.length,
      puntos: MAPA_DEMO_POINTS,
      fuente: 'demo'
    });
  }
};
