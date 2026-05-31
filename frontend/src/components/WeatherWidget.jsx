import React from 'react';
import { Cloud, Droplets, Wind, Thermometer, RefreshCw } from 'lucide-react';

const nivelStyles = {
  NORMAL: 'bg-green-100 border-green-200 text-green-800',
  PRECAUCION: 'bg-amber-100 border-amber-200 text-amber-900',
  ALERTA: 'bg-red-100 border-red-200 text-red-800'
};

export default function WeatherWidget({ clima, cargando, onRefresh, compact }) {
  if (!clima && !cargando) {
    return (
      <div className="text-sm text-gray-500 bg-gray-50 rounded-xl p-4 border border-gray-100">
        Clima no disponible en este momento.
      </div>
    );
  }

  if (cargando && !clima) {
    return (
      <div className="text-sm text-gray-400 animate-pulse p-4">Cargando clima de Santa Cruz...</div>
    );
  }

  const nivel = clima.nivel || 'NORMAL';
  const bannerClass = nivelStyles[nivel] || nivelStyles.NORMAL;

  if (compact) {
    return (
      <div className={`rounded-xl border p-3 text-xs ${bannerClass}`}>
        <div className="flex justify-between items-start gap-2">
          <span className="font-bold">{clima.alerta || clima.recomendacion_agronomica}</span>
          {onRefresh && (
            <button type="button" onClick={onRefresh} className="opacity-70 hover:opacity-100">
              <RefreshCw className={`w-3.5 h-3.5 ${cargando ? 'animate-spin' : ''}`} />
            </button>
          )}
        </div>
        <p className="italic mt-1 opacity-90">{clima.consejo}</p>
      </div>
    );
  }

  return (
    <div className="bg-gradient-to-r from-emerald-50 to-green-50 rounded-2xl border border-green-100 p-6 shadow-sm space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="bg-green-600 text-white font-bold text-xs uppercase tracking-widest px-2.5 py-1 rounded-full">
          AgroClima Santa Cruz
        </span>
        <div className="flex items-center gap-2 text-xs text-gray-500">
          {clima.actualizado_hora_local && <span>Actualizado: {clima.actualizado_hora_local}</span>}
          {onRefresh && (
            <button
              type="button"
              onClick={onRefresh}
              className="text-primary font-bold flex items-center gap-1"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${cargando ? 'animate-spin' : ''}`} />
            </button>
          )}
        </div>
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <div className="bg-white rounded-xl p-3 text-center border border-gray-100">
          <Thermometer className="w-5 h-5 text-primary mx-auto mb-1" />
          <div className="text-xl font-black">{clima.clima_actual?.temperatura_celsius}°C</div>
        </div>
        <div className="bg-white rounded-xl p-3 text-center border border-gray-100">
          <Droplets className="w-5 h-5 text-blue-500 mx-auto mb-1" />
          <div className="text-xl font-black">{clima.clima_actual?.humedad_relativa_porcentaje}%</div>
        </div>
        <div className="bg-white rounded-xl p-3 text-center border border-gray-100">
          <Cloud className="w-5 h-5 text-gray-500 mx-auto mb-1" />
          <div className="text-xl font-black">{clima.clima_actual?.precipitacion_mm}mm</div>
        </div>
        <div className="bg-white rounded-xl p-3 text-center border border-gray-100">
          <Wind className="w-5 h-5 text-sky-500 mx-auto mb-1" />
          <div className="text-xl font-black">{clima.clima_actual?.viento_kmh}</div>
        </div>
      </div>

      <div className={`rounded-xl border p-4 ${bannerClass}`}>
        <p className="font-bold text-sm">{clima.alerta}</p>
        <p className="text-sm italic mt-2 opacity-90">{clima.consejo}</p>
      </div>
    </div>
  );
}
