import React, { useState, useRef, useEffect } from 'react';
import axios from 'axios';
import { MessageSquare, X, Send, Bot, Sparkles } from 'lucide-react';

const WELCOME =
  '¡Hola! Soy CropBot, tu agrónomo virtual de Santa Cruz. ¿En qué puedo ayudarte hoy? Consultame sobre plagas, roya, envíos de insumos o microcréditos.';

export default function ChatBot() {
  const [isOpen, setIsOpen] = useState(false);
  const [notify, setNotify] = useState(true);
  const [messages, setMessages] = useState([
    { id: 1, sender: 'bot', text: WELCOME }
  ]);
  const [apiHistory, setApiHistory] = useState([]);
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const messagesEndRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages, isOpen]);

  const toggleChat = () => {
    setIsOpen(!isOpen);
    setNotify(false);
  };

  const handleSend = async (textToSend) => {
    const text = (textToSend || input).trim();
    if (!text || loading) return;

    const userMsg = { id: Date.now(), sender: 'user', text };
    setMessages((prev) => [...prev, userMsg]);
    setInput('');
    setLoading(true);

    try {
      const { data } = await axios.post(
        '/api/chat',
        {
          message: text,
          history: apiHistory
        },
        { timeout: 120000 }
      );

      const reply =
        data.reply ||
        'No pude generar una respuesta. Intenta preguntar de forma más específica sobre tu cultivo.';

      setApiHistory((prev) => {
        if (data.history && Array.isArray(data.history) && data.history.length > 0) {
          return data.history;
        }
        return [
          ...prev,
          { role: 'user', content: text },
          { role: 'assistant', content: reply }
        ];
      });

      setMessages((prev) => [
        ...prev,
        {
          id: Date.now() + 1,
          sender: 'bot',
          text: reply
        }
      ]);
    } catch (err) {
      console.error('ChatBot:', err);
      const fallback =
        err.response?.data?.reply ||
        'Lo siento, no pude procesar tu consulta agrícola. Verifica tu conexión e intenta de nuevo.';
      setMessages((prev) => [
        ...prev,
        { id: Date.now() + 1, sender: 'bot', text: fallback }
      ]);
    } finally {
      setLoading(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter') {
      handleSend();
    }
  };

  return (
    <div className="fixed bottom-6 right-6 z-40 flex flex-col items-end">
      {isOpen && (
        <div className="bg-white rounded-2xl border border-gray-200 shadow-2xl w-80 sm:w-96 h-[460px] flex flex-col overflow-hidden mb-4 animate-in slide-in-from-bottom-6 duration-300">
          <div className="bg-primary-dark p-4 text-white flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="bg-white bg-opacity-20 p-2 rounded-full">
                <Bot className="w-5 h-5 text-white" />
              </div>
              <div>
                <h4 className="font-bold text-sm leading-tight">CropBot Asistente</h4>
                <p className="text-xs text-green-200 flex items-center gap-1.5 mt-0.5">
                  <span className="w-2 h-2 rounded-full bg-green-400 inline-block animate-pulse" />
                  Agrónomo IA en Línea
                </p>
              </div>
            </div>
            <button
              type="button"
              onClick={toggleChat}
              className="text-white opacity-85 hover:opacity-100 hover:bg-white hover:bg-opacity-10 p-1.5 rounded-full transition-all"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-gray-50">
            {messages.map((msg) => (
              <div
                key={msg.id}
                className={`flex ${msg.sender === 'user' ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-4 py-2.5 text-sm whitespace-pre-wrap ${
                    msg.sender === 'user'
                      ? 'bg-primary text-white rounded-br-none shadow-sm'
                      : 'bg-white text-gray-800 border border-gray-200 rounded-bl-none shadow-sm'
                  }`}
                >
                  {msg.text}
                </div>
              </div>
            ))}
            {loading && (
              <div className="flex justify-start">
                <div className="bg-white text-gray-400 border border-gray-100 rounded-2xl rounded-bl-none px-4 py-3 text-xs flex items-center gap-2 shadow-sm">
                  <div className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce" />
                  <div className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce [animation-delay:0.2s]" />
                  <div className="w-1.5 h-1.5 bg-gray-400 rounded-full animate-bounce [animation-delay:0.4s]" />
                </div>
              </div>
            )}
            <div ref={messagesEndRef} />
          </div>

          <div className="px-4 py-2 bg-gray-50 border-t border-gray-100 flex flex-wrap gap-1.5">
            <button
              type="button"
              onClick={() => handleSend('¿Cómo prevengo la Roya de la Soya?')}
              className="text-xs bg-white hover:bg-primary hover:text-white border border-green-200 text-primary px-2.5 py-1 rounded-full transition-all duration-300 font-semibold"
            >
              Prevenir Roya Soya
            </button>
            <button
              type="button"
              onClick={() => handleSend('¿Tienen envíos express a Montero?')}
              className="text-xs bg-white hover:bg-primary hover:text-white border border-green-200 text-primary px-2.5 py-1 rounded-full transition-all duration-300 font-semibold"
            >
              Envíos a Montero
            </button>
            <button
              type="button"
              onClick={() => handleSend('¿Cómo financio la compra de insumos?')}
              className="text-xs bg-white hover:bg-primary hover:text-white border border-green-200 text-primary px-2.5 py-1 rounded-full transition-all duration-300 font-semibold"
            >
              Microcréditos Agro
            </button>
          </div>

          <div className="p-3 border-t border-gray-100 flex items-center gap-2 bg-white">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyPress}
              placeholder="Escribe tu consulta agrícola aquí..."
              disabled={loading}
              className="flex-1 bg-gray-50 border border-gray-200 rounded-xl px-4 py-2 outline-none text-sm focus:bg-white focus:border-primary transition-all disabled:opacity-60"
            />
            <button
              type="button"
              onClick={() => handleSend()}
              disabled={loading}
              className="p-2 text-primary hover:bg-green-50 rounded-xl transition-all disabled:opacity-50"
              aria-label="Enviar"
            >
              <Send className="w-5 h-5" />
            </button>
          </div>
        </div>
      )}

      <button
        type="button"
        onClick={toggleChat}
        className="w-14 h-14 bg-primary hover:bg-primary-dark text-white rounded-full flex items-center justify-center shadow-xl hover:shadow-2xl hover:scale-105 transition-all duration-300 relative"
        aria-label="Abrir asistente agronómico"
      >
        <MessageSquare className="w-6 h-6" />
        {notify && (
          <span className="absolute top-0.5 right-0.5 bg-accent-amber border-2 border-white w-4 h-4 rounded-full flex items-center justify-center animate-pulse">
            <Sparkles className="w-2.5 h-2.5 text-white" />
          </span>
        )}
      </button>
    </div>
  );
}
