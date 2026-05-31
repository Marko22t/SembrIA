import React, { useState } from 'react';

export default function PaymentModal({ plan, onClose, onSuccess }) {
  const [cardNumber, setCardNumber] = useState('');
  const [expiry, setExpiry] = useState('');
  const [cvv, setCvv] = useState('');
  const [cardName, setCardName] = useState('');
  const [loading, setLoading] = useState(false);

  const formatCardNumber = (val) =>
    val
      .replace(/\D/g, '')
      .replace(/(.{4})/g, '$1 ')
      .trim()
      .slice(0, 19);

  const formatExpiry = (val) =>
    val
      .replace(/\D/g, '')
      .replace(/^(\d{2})(\d)/, '$1/$2')
      .slice(0, 5);

  const handlePay = async () => {
    setLoading(true);
    await new Promise((r) => setTimeout(r, 1500));
    setLoading(false);
    onSuccess();
  };

  if (!plan) return null;

  return (
    <div className="fixed inset-0 bg-black/60 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-md p-6 shadow-2xl">
        <div className="flex justify-between items-center mb-6">
          <h2 className="text-xl font-bold text-gray-800">
            Pago — Plan {plan.name || plan.nombre}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 text-2xl leading-none"
          >
            ×
          </button>
        </div>

        <div className="bg-green-50 rounded-xl p-4 mb-6 text-center">
          <p className="text-3xl font-bold text-green-700">
            Bs {plan.price ?? plan.precio}
            <span className="text-base font-normal text-gray-500">/mes</span>
          </p>
        </div>

        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Nombre en la tarjeta</label>
            <input
              type="text"
              value={cardName}
              onChange={(e) => setCardName(e.target.value)}
              placeholder="Juan Perez"
              className="w-full border border-gray-200 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">Número de tarjeta</label>
            <input
              type="text"
              value={cardNumber}
              onChange={(e) => setCardNumber(formatCardNumber(e.target.value))}
              placeholder="1234 5678 9012 3456"
              maxLength={19}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 font-mono focus:outline-none focus:ring-2 focus:ring-green-500"
            />
          </div>
          <div className="flex gap-4">
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">Vencimiento</label>
              <input
                type="text"
                value={expiry}
                onChange={(e) => setExpiry(formatExpiry(e.target.value))}
                placeholder="MM/AA"
                maxLength={5}
                className="w-full border border-gray-200 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-500"
              />
            </div>
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-700 mb-1">CVV</label>
              <input
                type="password"
                value={cvv}
                onChange={(e) => setCvv(e.target.value.replace(/\D/g, '').slice(0, 4))}
                placeholder="•••"
                maxLength={4}
                className="w-full border border-gray-200 rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-green-500"
              />
            </div>
          </div>
        </div>

        <button
          type="button"
          onClick={handlePay}
          disabled={loading || !cardNumber || !expiry || !cvv || !cardName}
          className="mt-6 w-full bg-green-600 hover:bg-green-700 disabled:opacity-50 text-white font-bold py-4 rounded-xl transition-all"
        >
          {loading ? 'Procesando pago...' : `Pagar Bs ${plan.price ?? plan.precio}/mes`}
        </button>

        <p className="text-xs text-center text-gray-400 mt-3">
          🔒 Pago simulado para demo hackathon — sin cargo real
        </p>
      </div>
    </div>
  );
}
