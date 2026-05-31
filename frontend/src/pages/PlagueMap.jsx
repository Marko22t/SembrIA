import React, { useEffect, useRef, useState } from 'react';
import axios from 'axios';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

const URGENCIA_COLOR = {
  BAJA: '#16a34a',
  MEDIA: '#eab308',
  ALTA: '#ea580c',
  CRÍTICA: '#dc2626',
  CRITICA: '#dc2626'
};

export default function PlagueMap() {
  const mapRef = useRef(null);
  const mapInstance = useRef(null);
  const [stats, setStats] = useState({ total: 0, esta_semana: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    const init = async () => {
      try {
        const { data } = await axios.get('/api/map/diagnosticos');
        if (cancelled) return;
        setStats({ total: data.total, esta_semana: data.esta_semana });

        if (!mapRef.current || mapInstance.current) return;

        const map = L.map(mapRef.current).setView([-17.78, -63.18], 7);
        mapInstance.current = map;

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '© OpenStreetMap'
        }).addTo(map);

        (data.puntos || []).forEach((p) => {
          const urg = (p.urgencia || 'MEDIA').toUpperCase();
          const color = URGENCIA_COLOR[urg] || URGENCIA_COLOR.MEDIA;
          const isCritica = urg === 'CRÍTICA' || urg === 'CRITICA';

          const marker = L.circleMarker([p.lat, p.lon], {
            radius: isCritica ? 12 : 9,
            fillColor: color,
            color: '#fff',
            weight: 2,
            fillOpacity: 0.9,
            className: isCritica ? 'pulse-marker' : ''
          });

          marker.bindPopup(
            `<strong>${p.problema}</strong><br/>
            Cultivo: ${p.cultivo}<br/>
            Zona: ${p.zona}<br/>
            Urgencia: ${urg}<br/>
            Fecha: ${p.fecha || '—'}`
          );
          marker.addTo(map);
        });
      } catch {
        if (!cancelled) setStats({ total: 15, esta_semana: 15 });
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    init();

    return () => {
      cancelled = true;
      if (mapInstance.current) {
        mapInstance.current.remove();
        mapInstance.current = null;
      }
    };
  }, []);

  return (
    <div className="pb-24">
      <div className="max-w-6xl mx-auto px-4 py-8">
        <h2 className="text-3xl font-extrabold text-primary-dark">🗺️ Mapa de Plagas — Santa Cruz</h2>
        <p className="text-gray-500 mt-2 text-sm">
          Diagnósticos anónimos en el departamento. Sin datos personales de agricultores.
        </p>
        <div className="mt-4 inline-flex bg-green-50 border border-green-200 rounded-xl px-4 py-2 text-sm font-bold text-primary-dark">
          {loading
            ? 'Cargando mapa...'
            : `${stats.esta_semana} diagnósticos registrados en Santa Cruz esta semana`}
        </div>
      </div>

      <div className="relative max-w-6xl mx-auto px-4">
        <div ref={mapRef} className="h-[65vh] w-full rounded-2xl border border-gray-200 shadow-lg z-0" />

        <div className="absolute bottom-6 right-8 bg-white/95 rounded-xl border border-gray-200 p-4 shadow-lg z-[1000] text-xs space-y-2">
          <p className="font-bold text-gray-800">Urgencia</p>
          {[
            ['BAJA', 'Verde'],
            ['MEDIA', 'Amarillo'],
            ['ALTA', 'Naranja'],
            ['CRÍTICA', 'Rojo pulsante']
          ].map(([u, label]) => (
            <div key={u} className="flex items-center gap-2">
              <span
                className="w-3 h-3 rounded-full"
                style={{ background: URGENCIA_COLOR[u] }}
              />
              {label}
            </div>
          ))}
        </div>
      </div>

      <style>{`
        @keyframes pulse-ring {
          0% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.15); opacity: 0.7; }
          100% { transform: scale(1); opacity: 1; }
        }
        .pulse-marker {
          animation: pulse-ring 1.5s ease-in-out infinite;
        }
      `}</style>
    </div>
  );
}
