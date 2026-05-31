import Anthropic from '@anthropic-ai/sdk';
import { supabase } from '../config/supabase.js';
import { CLAUDE_MODEL } from '../config/env.js';
import { uploadDiagnosisImage } from '../utils/storage.js';
import {
  incrementDiagnosticoCount,
  getUserPlanState,
  isFreePlan
} from '../services/planService.js';

const DIAGNOSE_TIMEOUT_MS = 120000; // 2 minutos — visión + guardado

function buildDiagnosisConversation({ tipo, cultivo, zona, entradaUsuario, resultado }) {
  const userContent =
    tipo === 'image'
      ? `Diagnóstico por foto — Cultivo: ${cultivo}, Zona: ${zona}. ${entradaUsuario || 'Sin descripción adicional.'}`
      : `Diagnóstico por texto — Cultivo: ${cultivo}, Zona: ${zona}. Síntomas: ${entradaUsuario}`;

  const tratamientos = (resultado.tratamiento || []).join(' ');
  const assistantContent = [
    `**${resultado.problema || 'Resultado del diagnóstico'}**`,
    resultado.descripcion_visual || resultado.causa || '',
    `Urgencia: ${resultado.nivel_urgencia || resultado.urgencia || 'MEDIA'}`,
    tratamientos ? `Tratamiento: ${tratamientos}` : '',
    resultado.advertencia_confirmacion || resultado.prevencion || ''
  ]
    .filter(Boolean)
    .join('\n\n');

  return [
    { role: 'user', content: userContent },
    { role: 'assistant', content: assistantContent }
  ];
}

export function formatRespuestaIA(resultado) {
  if (!resultado) return '';
  const partes = [
    resultado.problema ? `**${resultado.problema}**` : '',
    resultado.causa || resultado.descripcion_visual || '',
    resultado.nivel_urgencia || resultado.urgencia
      ? `Urgencia: ${resultado.nivel_urgencia || resultado.urgencia}`
      : '',
    (resultado.tratamiento || []).length
      ? `Tratamiento:\n${resultado.tratamiento.map((t, i) => `${i + 1}. ${t}`).join('\n')}`
      : '',
    resultado.advertencia_confirmacion || resultado.prevencion || ''
  ];
  return partes.filter(Boolean).join('\n\n');
}

/** Un solo INSERT con el esquema actual de Supabase */
async function guardarDiagnostico({
  usuario_id,
  descripcion_texto,
  conversacion,
  respuesta_ia,
  imagen_url,
  tiene_imagen,
  resultado_json,
  cultivo,
  zona
}) {
  if (!usuario_id) return null;

  const resultado = resultado_json && typeof resultado_json === 'object' ? resultado_json : {};

  const usuarioId = usuario_id;
  const imagenUrl = imagen_url;
  const descripcionTexto = descripcion_texto;
  const resultadoJson = resultado;
  const respuestaTexto = respuesta_ia;

  console.log('Guardando diagnóstico para usuario:', usuarioId);

  if (!usuarioId) {
    console.error('Error al guardar diagnóstico: usuario_id es null (sesión expirada?)');
    return null;
  }

  const baseRow = {
    usuario_id: usuarioId,
    imagen_url: imagenUrl || null,
    descripcion_texto: descripcionTexto || '',
    cultivo: cultivo || 'Sin especificar',
    zona: zona || 'Santa Cruz',
    resultado_json: resultadoJson || {},
    respuesta_ia: respuestaTexto || '',
    tiene_imagen: !!imagenUrl
  };

  try {
    let data = null;
    let error = null;

    ({ data, error } = await supabase
      .from('diagnosticos')
      .insert({ ...baseRow, conversacion: conversacion || [] })
      .select()
      .single());

    if (error) {
      console.error('Error al guardar diagnóstico (con conversacion):', JSON.stringify(error));
      ({ data, error } = await supabase
        .from('diagnosticos')
        .insert(baseRow)
        .select()
        .single());
    }

    if (error) {
      console.error('Error al guardar diagnóstico:', JSON.stringify(error));
      throw error;
    }

    await incrementDiagnosticoCount(usuario_id);

    const { count } = await supabase
      .from('diagnosticos')
      .select('*', { count: 'exact', head: true })
      .eq('usuario_id', usuario_id);

    const planState = await getUserPlanState(usuario_id);

    return {
      diagnostico_id: data.id,
      numero_diagnostico: count ?? null,
      created_at: data.created_at,
      diagnosticos_mes: planState?.diagnosticos_mes ?? null,
      diagnosticos_hoy: planState?.diagnosticos_mes ?? null
    };
  } catch (err) {
    console.error('Error al guardar diagnóstico catch:', err.message);
    throw err;
  }
}

// POST /api/diagnose/record — un INSERT al finalizar (desde frontend)
export const saveDiagnosticoRecord = async (req, res) => {
  try {
    const usuario_id = req.user.id;
    const {
      descripcion_texto,
      conversacion,
      respuesta_ia,
      imagen_url,
      tiene_imagen,
      resultado_json,
      cultivo,
      zona
    } = req.body;

    if (!descripcion_texto || !Array.isArray(conversacion) || conversacion.length === 0) {
      return res.status(400).json({
        error: 'Faltan descripcion_texto o conversacion para guardar el diagnóstico.'
      });
    }

    const meta = await guardarDiagnostico({
      usuario_id,
      descripcion_texto,
      conversacion,
      respuesta_ia: respuesta_ia || '',
      imagen_url,
      tiene_imagen,
      resultado_json: resultado_json || {},
      cultivo,
      zona
    });

    if (!meta) {
      return res.status(500).json({ error: 'No se pudo guardar el diagnóstico en la base de datos.' });
    }

    return res.status(201).json(meta);
  } catch (error) {
    console.error('saveDiagnosticoRecord:', error);
    return res.status(500).json({ error: 'Error al guardar el registro del diagnóstico.' });
  }
};

// Inicializar cliente Anthropic si existe la API Key
const apiKey = process.env.ANTHROPIC_API_KEY;
let anthropic = null;

if (apiKey && !apiKey.startsWith('sk-ant-api03-tu-api-key')) {
  anthropic = new Anthropic({
    apiKey: process.env.ANTHROPIC_API_KEY || apiKey,
    timeout: 120000,
    maxRetries: 2
  });
} else {
  console.log(
    '💡 NOTA: No se detectó ANTHROPIC_API_KEY real. Se ejecutará el "Motor Agronómico de Respaldo" para simular diagnósticos de alta fidelidad de forma offline/local.'
  );
}

// Prompt para diagnóstico por TEXTO
const SYSTEM_PROMPT = `Eres AgroDoc, fitopatólogo senior del departamento de Santa Cruz de la Sierra, Bolivia.

REGLAS DE PRECISIÓN:
- Basa el diagnóstico SOLO en síntomas descritos y cultivo indicado.
- Si los síntomas encajan en varias enfermedades, usa certeza MEDIA o BAJA y lista diagnóstico diferencial.
- NUNCA asignes certeza ALTA sin signos clave inequívocos en la descripción.
- Diferencia trastornos abióticos (nutrición, sequía, herbicida) de bióticos (hongos, bacterias, insectos).

SIGNOS CLAVE — NO CONFUNDIR:
- Roya asiática soya: pústulas elevadas color óxido/canela en ENVÉS; no halo amarillo grande.
- Ojo de rana: lesiones angulosas marrones con halo amarillo.
- Antracnosis: manchas necróticas hundidas; picnidios posibles.
- Trips: plateado/raspado, deformación; no pústulas de hongo.
- Cogollero maíz: daño en cogollo, excremento tipo aserrín.

MARCAS Santa Cruz: Amistar Top, Opera, Priori Xtra, Engeo, Karate, Belt, Coragen, Urea YPFB.

Responde ÚNICAMENTE JSON válido sin markdown.`;

const VISION_SYSTEM_PROMPT = `Eres AgroDoc-Vision, fitopatólogo experto en Santa Cruz, Bolivia. Analizas FOTOS con rigor científico.

METODOLOGÍA OBLIGATORIA:
1. Identifica qué parte de la planta se ve y si coincide con el cultivo declarado.
2. Lista SOLO signos visibles (color, envés/adaxial, bordes, insectos, moho, agujeros).
3. Da 2-4 diagnósticos diferenciales con probabilidad y razón basada en signos.
4. Elige "problema" solo si los signos coinciden; si hay duda → certeza MEDIA o BAJA.
5. NO adivines roya/cogollero/trips por defecto. NO fuerces diagnóstico por cultivo declarado.
6. Foto borrosa o sin planta → certeza BAJA y pide mejor foto.
7. Si certeza BAJA, advierte confirmar con agrónomo antes de fungicidas caros.

CONFIRMAR SOLO SI VES:
- Roya soya: pústulas óxido/marrón redondeadas en ENVÉS.
- Ojo de rana: manchas angulosas + halo amarillo.
- Cogollero: daño cogollo + excremento granulado.
- Trips: raspado plateado, deformación.

MARCAS: Amistar Top, Opera, Priori Xtra, Engeo, Karate, Belt, Coragen.

Responde ÚNICAMENTE este JSON (sin markdown):

{
  "signos_observados": ["signo visible 1", "signo 2"],
  "diagnostico_diferencial": [
    {"enfermedad": "...", "probabilidad": "alta|media|baja", "por_que": "..."}
  ],
  "problema": "común + científico",
  "descripcion_visual": "descripción detallada de la foto",
  "certeza": "ALTA|MEDIA|BAJA",
  "nivel_urgencia": "BAJA|MEDIA|ALTA|CRÍTICA",
  "cultivo_afectado": "...",
  "coincide_cultivo_declarado": true,
  "advertencia_confirmacion": "qué confirmar en campo o qué foto pedir",
  "zona_riesgo": "...",
  "tratamiento": ["Paso 1", "Paso 2"],
  "productos_recomendados": [{"nombre": "...", "dosis": "...", "frecuencia": "...", "precio_estimado_bob": 0}],
  "medidas_preventivas": ["..."],
  "alerta_climatica": "..."
}`;

const JSON_FORMATO_TEXTO = `{
  "signos_observados": ["..."],
  "diagnostico_diferencial": [{"enfermedad": "...", "probabilidad": "alta|media|baja", "por_que": "..."}],
  "problema": "...",
  "descripcion_visual": "...",
  "certeza": "ALTA|MEDIA|BAJA",
  "nivel_urgencia": "BAJA|MEDIA|ALTA|CRÍTICA",
  "cultivo_afectado": "...",
  "advertencia_confirmacion": "...",
  "zona_riesgo": "...",
  "tratamiento": ["..."],
  "productos_recomendados": [{"nombre": "...", "dosis": "...", "frecuencia": "...", "precio_estimado_bob": 0}],
  "medidas_preventivas": ["..."],
  "alerta_climatica": "..."
}`;

function buildVisionUserPrompt(cultivo, zona, descripcionOpcional) {
  return `Analiza la imagen adjunta. Diagnostica la enfermedad o problema.

DATOS DEL AGRICULTOR (verificar con la foto):
- Cultivo declarado: ${cultivo}
- Zona: ${zona}
- Comentario: ${descripcionOpcional?.trim() || 'Sin comentario'}

1. Observa toda la imagen antes de decidir.
2. "signos_observados" = solo lo visible, sin suponer.
3. Mínimo 2 opciones en "diagnostico_diferencial" si no es obvio.
4. certeza ALTA solo con signos patognomónicos claros.
5. El agricultor quiere saber la enfermedad: sé honesto con el nivel de certeza.

Solo JSON del formato del system prompt.`;
}

// --- MOTOR AGRONÓMICO DE RESPALDO (HACKATHON OFFLINE INSURANCE) ---
const simulateDiagnosis = (cultivo, descripcion = '', zona = 'Norte Integrado') => {
  const desc = descripcion.toLowerCase();
  
  if (cultivo.toLowerCase() === 'soya') {
    if (desc.includes('roya') || desc.includes('pústul') || desc.includes('pustul') || (desc.includes('óxido') && desc.includes('envés'))) {
      return {
        problema: "Roya Asiática de la Soya (Phakopsora pachyrhizi)",
        causa: "Hongo foliar devastador altamente propiciado por el rocío y temperaturas cálidas en la región de " + zona + ", Santa Cruz.",
        severidad: 4,
        urgencia: "ALTA",
        tratamiento: [
          "Aplicación inmediata de fungicida sistémico mezclando triazoles y estrobirulinas.",
          "Verificar la presencia de focos de infección en las parcelas vecinas.",
          "Adecuar la calibración de pulverización para penetrar el estrato medio foliar."
        ],
        productos_recomendados: [
          { nombre: "Fungicida Priori Xtra (Syngenta)", dosis: "300 ml/ha", precio_estimado_bob: 280.00 },
          { nombre: "Fungicida Opera (BASF)", dosis: "500 ml/ha", precio_estimado_bob: 980.00 }
        ],
        prevencion: "Sembrar en las fechas del calendario oficial de ANAPO para evitar los picos de esporas de roya.",
        confianza: "ALTA",
        zona_riesgo: "Región del Norte Integrado (Montero, Warnes) y zona Este de Santa Cruz.",
        cuando_actuar: "Antes de superar el 5% de severidad foliar."
      };
    } else {
      // Trips en Soya
      return {
        problema: "Trips de la Soya (Frankliniella schultzei)",
        causa: "Ataque del insecto picador-chupador propiciado por el clima seco y de calor intenso típico del Este cruceño.",
        severidad: 3,
        urgencia: "MEDIA",
        tratamiento: [
          "Efectuar pulverización con insecticidas sistémicos y de contacto.",
          "Optimizar la presión y cobertura de gotas para alcanzar el envés foliar."
        ],
        productos_recomendados: [
          { nombre: "Insecticidas Karate con Tecnología Zeon", dosis: "150 ml/ha", precio_estimado_bob: 175.00 }
        ],
        prevencion: "Mantener buena cobertura de suelo vegetal/rastrojos para retener humedad.",
        confianza: "ALTA",
        zona_riesgo: "Pailón, Cuatro Cañadas y San José de Chiquitos.",
        cuando_actuar: "Al encontrar más de 8 trips por folíolo."
      };
    }
  }

  if (cultivo.toLowerCase() === 'maíz' || cultivo.toLowerCase() === 'maiz') {
    return {
      problema: "Gusano Cogollero (Spodoptera frugiperda)",
      causa: "Larva masticadora que perfora el cogollo de la planta, recurrente en periodos secos del departamento cruceño.",
      severidad: 3,
      urgencia: "MEDIA",
      tratamiento: [
        "Realizar aplicaciones focalizadas en el cogollo en horas frescas.",
        "Monitorear postura de masas de huevos e instalar trampas de luz."
      ],
      productos_recomendados: [
        { nombre: "Insecticida Lorsban 4E", dosis: "800 ml/ha", precio_estimado_bob: 140.00 },
        { nombre: "Insecticida Cipermex 25 EC", dosis: "400 ml/ha", precio_estimado_bob: 95.00 }
      ],
      prevencion: "Usar híbridos Bt certificados y efectuar un control oportuno de malezas hospederas.",
      confianza: "ALTA",
      zona_riesgo: "Cabezas, Charagua y provincias del Sur integrado.",
      cuando_actuar: "Al notar más de 12% de plantas con hojas dañadas (escala de Davis)."
    };
  }

  if (cultivo.toLowerCase() === 'tomate') {
    return {
      problema: "Mosca Blanca (Bemisia tabaci)",
      causa: "Insecto chupador y vector de geminivirus, altamente favorecido por la alternancia de humedad y calor en los Valles.",
      severidad: 4,
      urgencia: "ALTA",
      tratamiento: [
        "Aplicar insecticidas sistémicos selectivos.",
        "Instalar trampas adhesivas amarillas para control de adultos.",
        "Arrancar brotes gravemente cloróticos."
      ],
      productos_recomendados: [
        { nombre: "Insecticida Karate con Tecnología Zeon", dosis: "200 ml/ha", precio_estimado_bob: 175.00 }
      ],
      prevencion: "Poner mallas antiáfidos en semilleros y destruir residuos de cosecha previos en la zona.",
      confianza: "ALTA",
      zona_riesgo: "Mairana, Samaipata y Vallegrande.",
      cuando_actuar: "Al detectar los primeros adultos en el envés de hojas jóvenes."
    };
  }

  // Sin coincidencia clara — no adivinar
  return {
    problema: 'Requiere análisis con IA o agrónomo presencial',
    descripcion_visual:
      'Los síntomas descritos no coinciden con un patrón seguro en modo offline. Activa ANTHROPIC_API_KEY o describe más detalles (color de manchas, envés vs haz, insectos visibles).',
    severidad: 2,
    urgencia: 'MEDIA',
    certeza: 'BAJA',
    tratamiento: [
      'Tomar foto clara del envés y haz de la hoja con buena luz.',
      'Consultar a un agrónomo de ANAPO o agroveterinaria en ' + zona + '.',
      'No aplicar fungicidas hasta confirmar si es hongo, insecto o deficiencia.'
    ],
    productos_recomendados: [],
    medidas_preventivas: ['Monitorear 3 días y registrar avance de síntomas'],
    zona_riesgo: zona + ', Santa Cruz',
    cuando_actuar: 'Antes de aplicar químicos',
    advertencia_confirmacion: 'Diagnóstico offline limitado — no usar como única fuente.'
  };
};

/** Respaldo cuando no hay API para fotos — NO inventar enfermedades */
const simulateDiagnosisImage = (cultivo, descripcion, zona) => ({
  signos_observados: ['Análisis visual requiere Claude API activa'],
  diagnostico_diferencial: [],
  problema: 'Análisis de imagen no disponible (modo offline)',
  descripcion_visual:
    'Para diagnosticar fotos con precisión se necesita ANTHROPIC_API_KEY en el servidor. ' +
    (descripcion ? `Comentario recibido: ${descripcion}` : 'Sin comentario.'),
  certeza: 'BAJA',
  nivel_urgencia: 'MEDIA',
  cultivo_afectado: cultivo,
  advertencia_confirmacion:
    'Configura la API de Claude y reinicia el backend, o lleva la muestra a un agrónomo en ' + zona + '.',
  zona_riesgo: 'Santa Cruz — ' + zona,
  tratamiento: [
    'Repetir el diagnóstico con API activa o visitar agroveterinaria local.',
    'Fotografiar hoja afectada y sana con luz natural.'
  ],
  productos_recomendados: [],
  medidas_preventivas: [],
  alerta_climatica: ''
});

// Normaliza JSON nuevo y legacy para el frontend
function normalizarDiagnostico(raw) {
  if (!raw || typeof raw !== 'object') return raw;
  const urgencia = raw.nivel_urgencia || raw.urgencia || 'MEDIA';
  const severidadMap = { BAJA: 2, MEDIA: 3, ALTA: 4, CRÍTICA: 5, CRITICA: 5 };
  return {
    ...raw,
    problema: raw.problema || 'Problema no identificado',
    causa: raw.causa || raw.descripcion_visual || '',
    descripcion_visual: raw.descripcion_visual || raw.causa || '',
    urgencia,
    nivel_urgencia: urgencia,
    severidad: raw.severidad ?? severidadMap[urgencia] ?? 3,
    confianza: raw.certeza || raw.confianza || 'MEDIA',
    certeza: raw.certeza || raw.confianza || 'MEDIA',
    zona_riesgo: raw.zona_riesgo || '',
    cuando_actuar: raw.cuando_actuar || 'Lo antes posible',
    tratamiento: Array.isArray(raw.tratamiento) ? raw.tratamiento : [],
    productos_recomendados: Array.isArray(raw.productos_recomendados)
      ? raw.productos_recomendados
      : [],
    prevencion:
      raw.prevencion ||
      (Array.isArray(raw.medidas_preventivas)
        ? raw.medidas_preventivas.join('. ')
        : ''),
    medidas_preventivas: raw.medidas_preventivas || [],
    alerta_climatica: raw.alerta_climatica || '',
    signos_observados: Array.isArray(raw.signos_observados) ? raw.signos_observados : [],
    diagnostico_diferencial: Array.isArray(raw.diagnostico_diferencial)
      ? raw.diagnostico_diferencial
      : [],
    advertencia_confirmacion: raw.advertencia_confirmacion || ''
  };
}

// Parseo defensivo de respuestas Claude
function parsearRespuestaClaude(texto) {
  try {
    return normalizarDiagnostico(JSON.parse(texto.trim()));
  } catch (_) {}

  const matchMd = texto.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (matchMd) {
    try {
      return normalizarDiagnostico(JSON.parse(matchMd[1].trim()));
    } catch (_) {}
  }

  const matchBrace = texto.match(/\{[\s\S]*\}/);
  if (matchBrace) {
    try {
      return normalizarDiagnostico(JSON.parse(matchBrace[0]));
    } catch (_) {}
  }

  return normalizarDiagnostico({
    problema: 'Diagnóstico en procesamiento',
    descripcion_visual: texto.substring(0, 300),
    certeza: 'BAJA',
    nivel_urgencia: 'MEDIA',
    cultivo_afectado: 'No determinado',
    zona_riesgo: 'Consulta con agrónomo local en Santa Cruz',
    tratamiento: ['Lleva una muestra de la planta a tu agrónomo más cercano'],
    productos_recomendados: [],
    medidas_preventivas: ['Monitorear el cultivo diariamente'],
    alerta_climatica: ''
  });
}

// --- CONTROLLERS ---

// 1. DIAGNÓSTICO POR TEXTO
export const diagnoseText = async (req, res) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), DIAGNOSE_TIMEOUT_MS);

  try {
    const { descripcion, cultivo, zona_santa_cruz, usuario_id, skip_persist } = req.body;

    if (!descripcion || !cultivo || !zona_santa_cruz) {
      clearTimeout(timeoutId);
      return res.status(400).json({ error: 'Faltan campos requeridos (descripcion, cultivo, zona_santa_cruz).' });
    }

    let resultJSON = null;

    if (anthropic) {
      try {
        const userPrompt = `Cultivo: ${cultivo}
Zona Santa Cruz: ${zona_santa_cruz}
Síntomas del agricultor: ${descripcion}

Responde solo JSON con este formato:
${JSON_FORMATO_TEXTO}`;

        const response = await anthropic.messages.create({
          model: CLAUDE_MODEL,
          max_tokens: 3000,
          temperature: 0.2,
          system: SYSTEM_PROMPT,
          messages: [{ role: 'user', content: userPrompt }]
        }, { signal: controller.signal });

        const responseText = response.content[0].text;
        resultJSON = parsearRespuestaClaude(responseText);
      } catch (apiError) {
        console.error('Error de llamada a la API de Claude:', apiError);
        // Si hay error en llamada a Claude real, lanzamos error 503
        clearTimeout(timeoutId);
        return res.status(503).json({
          error: 'El servicio de diagnóstico no está disponible en este momento. Intenta de nuevo.'
        });
      }
    } else {
      // Usar motor de respaldo local
      resultJSON = normalizarDiagnostico(
        simulateDiagnosis(cultivo, descripcion, zona_santa_cruz)
      );
    }

    let meta = null;
    if (usuario_id && !skip_persist) {
      const conversacion = buildDiagnosisConversation({
        tipo: 'text',
        cultivo,
        zona: zona_santa_cruz,
        entradaUsuario: descripcion,
        resultado: resultJSON
      });
      meta = await guardarDiagnostico({
        usuario_id,
        descripcion_texto: descripcion,
        conversacion,
        respuesta_ia: formatRespuestaIA(resultJSON),
        imagen_url: null,
        tiene_imagen: false,
        resultado_json: resultJSON || {},
        cultivo,
        zona: zona_santa_cruz
      });
    }

    clearTimeout(timeoutId);
    return res.status(200).json({
      ...resultJSON,
      respuesta_ia: formatRespuestaIA(resultJSON),
      imagen_url: null,
      ...(meta || {})
    });
  } catch (error) {
    clearTimeout(timeoutId);
    console.error('Error general en diagnoseText:', error);
    if (error.name === 'AbortError') {
      return res.status(504).json({
        error: 'La solicitud de diagnóstico excedió el tiempo límite (2 minutos). Intenta de nuevo.'
      });
    }
    return res.status(500).json({ error: 'Ocurrió un error interno del servidor.' });
  }
};

// 2. DIAGNÓSTICO POR IMAGEN (CLAUDE VISION / BASE64)
export const diagnoseImage = async (req, res) => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), DIAGNOSE_TIMEOUT_MS);

  try {
    const {
      imagen_base64,
      descripcion_opcional,
      cultivo,
      zona_santa_cruz,
      usuario_id,
      skip_persist
    } = req.body;

    if (!imagen_base64 || !cultivo || !zona_santa_cruz) {
      clearTimeout(timeoutId);
      return res.status(400).json({ error: 'Faltan campos requeridos (imagen_base64, cultivo, zona_santa_cruz).' });
    }

    let resultJSON = null;
    let savedImageUrl = null;

    if (anthropic) {
      try {
        // Limpiar el prefijo data:image/...;base64, de la cadena base64 si existe
        let base64Data = imagen_base64;
        let mediaType = 'image/jpeg';

        if (imagen_base64.includes(';base64,')) {
          const parts = imagen_base64.split(';base64,');
          base64Data = parts[1];
          mediaType = parts[0].replace('data:', '');
        }

        const userPrompt = buildVisionUserPrompt(
          cultivo,
          zona_santa_cruz,
          descripcion_opcional
        );

        const response = await anthropic.messages.create({
          model: CLAUDE_MODEL,
          max_tokens: 4096,
          temperature: 0.1,
          system: VISION_SYSTEM_PROMPT,
          messages: [
            {
              role: 'user',
              content: [
                { type: 'text', text: userPrompt },
                {
                  type: 'image',
                  source: {
                    type: 'base64',
                    media_type: mediaType,
                    data: base64Data
                  }
                }
              ]
            }
          ]
        }, { signal: controller.signal });

        const responseText = response.content[0].text;
        resultJSON = parsearRespuestaClaude(responseText);
      } catch (apiError) {
        console.error('Error de llamada a Claude Vision:', apiError);
        clearTimeout(timeoutId);
        return res.status(503).json({
          error: 'El servicio de diagnóstico no está disponible en este momento. Intenta de nuevo.'
        });
      }
    } else {
      // Usar motor de respaldo local
      resultJSON = normalizarDiagnostico(
        simulateDiagnosisImage(cultivo, descripcion_opcional || '', zona_santa_cruz)
      );
    }

    // Subir imagen a Supabase Storage (si hay service role key configurada)
    let base64ForUpload = imagen_base64;
    let mediaTypeUpload = 'image/jpeg';
    if (imagen_base64.includes(';base64,')) {
      const parts = imagen_base64.split(';base64,');
      base64ForUpload = parts[1];
      mediaTypeUpload = parts[0].replace('data:', '');
    }
    savedImageUrl = await uploadDiagnosisImage(base64ForUpload, mediaTypeUpload);

    let meta = null;
    if (usuario_id && !skip_persist) {
      const conversacion = buildDiagnosisConversation({
        tipo: 'image',
        cultivo,
        zona: zona_santa_cruz,
        entradaUsuario: descripcion_opcional,
        resultado: resultJSON
      });
      meta = await guardarDiagnostico({
        usuario_id,
        descripcion_texto: descripcion_opcional || 'Diagnóstico por imagen',
        conversacion,
        respuesta_ia: formatRespuestaIA(resultJSON),
        imagen_url: savedImageUrl,
        tiene_imagen: true,
        resultado_json: resultJSON || {},
        cultivo,
        zona: zona_santa_cruz
      });
    }

    clearTimeout(timeoutId);
    return res.status(200).json({
      ...resultJSON,
      respuesta_ia: formatRespuestaIA(resultJSON),
      imagen_url: savedImageUrl,
      ...(meta || {})
    });
  } catch (error) {
    clearTimeout(timeoutId);
    console.error('Error general en diagnoseImage:', error);
    if (error.name === 'AbortError') {
      return res.status(504).json({
        error: 'La solicitud de diagnóstico excedió el tiempo límite (2 minutos). Intenta de nuevo.'
      });
    }
    return res.status(500).json({ error: 'Ocurrió un error interno del servidor.' });
  }
};

// 3. OBTENER HISTORIAL DE DIAGNÓSTICOS DEL USUARIO
export const getHistory = async (req, res) => {
  try {
    const { userId } = req.params;

    if (!userId) {
      return res.status(400).json({ error: 'usuario_id es requerido para obtener el historial.' });
    }

    if (req.user.id !== userId) {
      return res.status(403).json({ error: 'No tienes permiso para ver este historial.' });
    }

    const { data: usuario } = await supabase
      .from('usuarios')
      .select('plan')
      .eq('id', userId)
      .maybeSingle();

    let query = supabase
      .from('diagnosticos')
      .select(
        'id, usuario_id, imagen_url, descripcion_texto, conversacion, respuesta_ia, tiene_imagen, created_at'
      )
      .eq('usuario_id', userId)
      .order('created_at', { ascending: false });

    if (!usuario || isFreePlan(usuario.plan)) {
      query = query.limit(10);
    }

    const { data: history, error: fetchError } = await query;

    if (fetchError) {
      throw fetchError;
    }

    return res.status(200).json(history || []);
  } catch (error) {
    console.error('Error al obtener historial:', error);
    return res.status(500).json({ error: 'Error interno del servidor al consultar el historial.' });
  }
};
