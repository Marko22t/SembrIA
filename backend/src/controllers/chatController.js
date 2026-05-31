import Anthropic from '@anthropic-ai/sdk';
import { CLAUDE_MODEL } from '../config/env.js';

const apiKey = process.env.ANTHROPIC_API_KEY;
let anthropic = null;

const CHAT_SYSTEM_PROMPT =
  'Eres un asistente agrícola experto. Responde SIEMPRE en español. Sé conciso y específico sobre cultivos, plagas y enfermedades agrícolas de Bolivia.';

if (apiKey && !apiKey.startsWith('sk-ant-api03-tu-api-key')) {
  anthropic = new Anthropic({
    apiKey,
    timeout: 120000,
    maxRetries: 2
  });
}

function respuestaLocal(message, history) {
  const lower = message.toLowerCase();
  const ctx = history
    .filter((m) => m.role === 'user')
    .slice(-2)
    .map((m) => m.content)
    .join(' ')
    .toLowerCase();

  if (lower.includes('roya') || lower.includes('soya') || ctx.includes('roya')) {
    return 'Para la roya asiática en soya del oriente boliviano, aplica fungicida triazol+estrobilurina (Opera, Priori Xtra) al ver los primeros pústulas en el envés. En Santa Cruz el riesgo sube con humedad y noches frescas; monitorea cada 5-7 días desde floración.';
  }
  if (lower.includes('tizón') || lower.includes('papa') || lower.includes('tomate')) {
    return 'El tizón tardío en papa/tomate se dispara con humedad. Suspende riego por aspersión, mejora ventilación del follaje y aplica fungicida sistémico en las primeras 48 h de síntomas.';
  }
  if (lower.includes('envío') || lower.includes('envio') || lower.includes('montero')) {
    return 'En CropDoctor coordinamos entregas a zonas del departamento. Compra insumos en el marketplace antes del mediodía para despacho prioritario según tu zona.';
  }
  if (lower.includes('crédito') || lower.includes('credito')) {
    return 'Tu historial de diagnósticos en Mi Campo genera una bitácora fitosanitaria para evaluar microcréditos en BOB. Mantén registros actualizados de tus parcelas.';
  }
  return `Sobre tu consulta agrícola en Santa Cruz: identifica si el problema es biótico (plaga/enfermedad) o abiótico (nutrición, riego). ¿Puedes describir síntomas en hojas, tallo o fruto y el cultivo exacto?`;
}

// POST /api/chat
export const chatMessage = async (req, res) => {
  try {
    const { message, history = [] } = req.body;

    if (!message || !String(message).trim()) {
      return res.status(400).json({ error: 'El mensaje no puede estar vacío.' });
    }

    const userMessage = String(message).trim();

    const conversationHistory = (Array.isArray(history) ? history : [])
      .filter((m) => m && (m.role === 'user' || m.role === 'assistant') && m.content)
      .slice(-18)
      .map((m) => ({
        role: m.role,
        content: String(m.content).trim()
      }));

    const messagesForApi = [...conversationHistory, { role: 'user', content: userMessage }];

    if (process.env.NODE_ENV !== 'production') {
      console.log('[ChatBot] historial:', conversationHistory.length, 'mensajes + usuario');
    }

    let reply = '';

    if (anthropic) {
      const response = await anthropic.messages.create({
        model: CLAUDE_MODEL,
        max_tokens: 800,
        temperature: 0.4,
        system: CHAT_SYSTEM_PROMPT,
        messages: messagesForApi
      });
      reply = response.content[0]?.text?.trim() || respuestaLocal(userMessage, conversationHistory);
    } else {
      reply = respuestaLocal(userMessage, conversationHistory);
    }

    const updatedHistory = [
      ...conversationHistory,
      { role: 'user', content: userMessage },
      { role: 'assistant', content: reply }
    ];

    return res.status(200).json({ reply, history: updatedHistory });
  } catch (err) {
    console.error('chatMessage:', err.message);
    return res.status(200).json({
      reply:
        'Lo siento, hubo un problema técnico. ¿Puedes reformular tu consulta agrícola?',
      history: []
    });
  }
};
