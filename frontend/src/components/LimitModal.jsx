import React from 'react';

export default function LimitModal({ open, onClose, onUpgrade }) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-3xl max-w-md w-full p-8 shadow-2xl text-center space-y-4">
        <div className="text-5xl">🌿</div>
        <h3 className="text-xl font-extrabold text-primary-dark">
          ¡Límite mensual alcanzado!
        </h3>
        <p className="text-gray-600 text-sm leading-relaxed">
          Has usado tus 10 diagnósticos gratuitos de este mes. Activa{' '}
          <strong>Pro</strong> para seguir diagnosticando sin límites.
        </p>
        <div className="flex flex-col gap-2 pt-2">
          <button
            type="button"
            onClick={onUpgrade}
            className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-3 rounded-xl"
          >
            Ver planes Pro — 49 BOB/mes
          </button>
          <button
            type="button"
            onClick={onClose}
            className="w-full border border-gray-200 text-gray-600 font-semibold py-3 rounded-xl"
          >
            Entendido, vuelvo el próximo mes
          </button>
        </div>
      </div>
    </div>
  );
}
