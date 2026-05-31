import axios from 'axios';
import { supabase } from '../lib/supabase.js';

/**
 * Un solo INSERT al finalizar el diagnóstico.
 * Intenta Supabase directo; si falla (RLS), usa el API con service role.
 */
export async function guardarDiagnosticoEnSupabase({
  usuarioId,
  imagenUrl,
  descripcionTexto,
  conversacion,
  respuestaIa,
  tieneImagen,
  resultadoJson,
  cultivo,
  zona,
  token
}) {
  if (!usuarioId) {
    throw new Error('Inicia sesión para guardar tu diagnóstico.');
  }

  // API con service role: INSERT único + contador mensual
  if (token) {
    const { data } = await axios.post(
      '/api/diagnose/record',
      {
        descripcion_texto: descripcionTexto,
        conversacion,
        respuesta_ia: respuestaIa,
        imagen_url: imagenUrl,
        tiene_imagen: tieneImagen,
        resultado_json: resultadoJson || {},
        cultivo,
        zona
      },
      { headers: { Authorization: `Bearer ${token}` }, timeout: 120000 }
    );

    return {
      diagnostico_id: data.diagnostico_id,
      numero_diagnostico: data.numero_diagnostico,
      diagnosticos_mes: data.diagnosticos_mes ?? data.diagnosticos_hoy,
      diagnosticos_hoy: data.diagnosticos_mes ?? data.diagnosticos_hoy,
      via: 'api'
    };
  }

  // Respaldo: insert directo (requiere políticas RLS en Supabase)
  if (supabase) {
    const { data, error } = await supabase
      .from('diagnosticos')
      .insert({
        usuario_id: usuarioId,
        imagen_url: imagenUrl || null,
        descripcion_texto: descripcionTexto,
        conversacion,
        respuesta_ia: respuestaIa,
        tiene_imagen: Boolean(tieneImagen),
        resultado_json: resultadoJson || {},
        ...(cultivo ? { cultivo } : {}),
        ...(zona ? { zona } : {})
      })
      .select('id, created_at')
      .single();

    if (!error && data) {
      return { diagnostico_id: data.id, created_at: data.created_at, via: 'supabase' };
    }
    console.warn('Insert Supabase:', error?.message);
  }

  throw new Error('No se pudo guardar el diagnóstico.');
}

export function buildTextoUsuario({ cultivo, zona, descripcion, esImagen }) {
  const base = esImagen
    ? descripcion?.trim() || 'Análisis de imagen del cultivo'
    : descripcion?.trim() || '';
  return `[${cultivo} · ${zona}] ${base}`.trim();
}

export function buildRespuestaDesdeResultado(resultado) {
  if (!resultado) return '';
  if (resultado.respuesta_ia) return resultado.respuesta_ia;
  const partes = [
    resultado.problema ? `**${resultado.problema}**` : '',
    resultado.causa || resultado.descripcion_visual || '',
    resultado.nivel_urgencia || resultado.urgencia
      ? `Urgencia: ${resultado.nivel_urgencia || resultado.urgencia}`
      : '',
    (resultado.tratamiento || []).length
      ? `Tratamiento:\n${resultado.tratamiento.map((t, i) => `${i + 1}. ${t}`).join('\n')}`
      : ''
  ];
  return partes.filter(Boolean).join('\n\n');
}
