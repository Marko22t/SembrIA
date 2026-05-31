import React from 'react';

export default function UsageBar({ usados, limite = 10, onUpgrade }) {
  if (usados < 7) return null;

  const pct = Math.min(100, (usados / limite) * 100);

  return (
    <div className="max-w-4xl mx-auto px-4 pt-4">
      <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="flex-1">
          <p className="text-sm font-bold text-amber-900">
            Has usado {usados} de {limite} diagnósticos gratuitos del mes
          </p>
          <div className="mt-2 h-2 bg-amber-100 rounded-full overflow-hidden">
            <div
              className="h-full bg-amber-500 transition-all duration-500"
              style={{ width: `${pct}%` }}
            />
          </div>
        </div>
        {usados >= limite && (
          <button
            type="button"
            onClick={onUpgrade}
            className="text-xs font-bold text-white bg-primary px-4 py-2 rounded-lg whitespace-nowrap"
          >
            Ir a Pro
          </button>
        )}
      </div>
    </div>
  );
}
