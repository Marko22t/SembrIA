import React, { useEffect, useRef, useState } from 'react';

const STATS = [
  { icon: '🌿', value: 1247, label: 'Diagnósticos realizados', prefix: '', suffix: '' },
  { icon: '🗺️', value: 6, label: 'Zonas de Santa Cruz cubiertas', prefix: '', suffix: '' },
  { icon: '⚡', value: 93, label: 'Precisión en diagnósticos', prefix: '', suffix: '%' },
  { icon: '💰', value: 2.3, label: 'En pérdidas prevenidas estimadas', prefix: 'Bs ', suffix: 'M', decimals: 1 }
];

function useCountUp(target, duration, start) {
  const [count, setCount] = useState(0);
  useEffect(() => {
    if (!start) return;
    let startTime = null;
    const step = (timestamp) => {
      if (!startTime) startTime = timestamp;
      const progress = Math.min((timestamp - startTime) / duration, 1);
      setCount(target * progress);
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }, [target, duration, start]);
  return count;
}

function StatItem({ stat, active }) {
  const raw = useCountUp(stat.value, 2000, active);
  const display =
    stat.decimals !== undefined
      ? raw.toFixed(stat.decimals)
      : Math.floor(raw).toLocaleString('es-BO');

  return (
    <div className="text-center py-6 px-4">
      <div className="text-3xl mb-2">{stat.icon}</div>
      <div className="text-3xl sm:text-4xl font-extrabold text-green-400">
        {stat.prefix}
        {display}
        {stat.suffix}
      </div>
      <div className="text-xs text-green-200 font-bold uppercase tracking-wider mt-2">
        {stat.label}
      </div>
    </div>
  );
}

export default function ImpactCounters() {
  const ref = useRef(null);
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const obs = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setVisible(true);
          obs.disconnect();
        }
      },
      { threshold: 0.3 }
    );
    obs.observe(el);
    return () => obs.disconnect();
  }, []);

  return (
    <section ref={ref} className="bg-[#14532d] text-white py-16 px-4">
      <div className="max-w-6xl mx-auto text-center space-y-4">
        <h2 className="text-2xl sm:text-3xl font-extrabold">
          Protegiendo las cosechas de Santa Cruz con Inteligencia Artificial
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mt-8">
          {STATS.map((s) => (
            <StatItem key={s.label} stat={s} active={visible} />
          ))}
        </div>
        <p className="text-[10px] text-green-400 mt-6 opacity-80">
          * Datos proyectados basados en tasas de adopción estimadas
        </p>
      </div>
    </section>
  );
}
