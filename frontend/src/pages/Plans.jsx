import React, { useState, useEffect } from 'react';
import axios from 'axios';
import PaymentModal from '../components/PaymentModal.jsx';
import PlanBadge from '../components/PlanBadge.jsx';

const PLANES = [
  {
    id: 'gratuito',
    name: 'Gratuito',
    nombre: 'Gratuito',
    price: 0,
    precio: 0,
    badge: null,
    features: [
      '10 diagnósticos por mes',
      'Marketplace básico',
      'Clima en tiempo real',
      'Mapa de plagas (lectura)'
    ]
  },
  {
    id: 'pro',
    name: 'Pro',
    nombre: 'Pro',
    price: 49,
    precio: 49,
    badge: '👑',
    features: [
      'Diagnósticos ilimitados',
      'Historial completo',
      'Soporte prioritario',
      'Coronita en tu perfil 👑'
    ]
  },
  {
    id: 'empresa',
    name: 'Empresa',
    nombre: 'Empresa',
    price: 149,
    precio: 149,
    badge: '🏢',
    features: [
      'Todo lo de Pro',
      'Múltiples usuarios',
      'API access',
      'Logo empresa en perfil 🏢',
      'Reportes avanzados'
    ]
  }
];

function normalizePlan(plan) {
  if (!plan || plan === 'gratis') return 'gratuito';
  return plan;
}

export default function Plans({ usuario, token, onAuthRedirect, onPlanUpdated }) {
  const [planActual, setPlanActual] = useState(normalizePlan(usuario?.plan));
  const [showPayment, setShowPayment] = useState(false);
  const [planSeleccionado, setPlanSeleccionado] = useState(null);
  const [procesando, setProcesando] = useState(false);
  const [exito, setExito] = useState(false);
  const [mensaje, setMensaje] = useState('');

  useEffect(() => {
    const cargarPlan = async () => {
      if (!token || !usuario?.id) return;
      try {
        const { data } = await axios.get('/api/subscription/status', {
          headers: { Authorization: `Bearer ${token}` },
          params: { userId: usuario.id }
        });
        setPlanActual(normalizePlan(data.plan));
      } catch {
        setPlanActual(normalizePlan(usuario?.plan));
      }
    };
    cargarPlan();
  }, [token, usuario?.id, usuario?.plan]);

  const cambiarPlan = async (nuevoPlan) => {
    if (!usuario || !token) {
      onAuthRedirect?.();
      return;
    }

    setProcesando(true);
    setMensaje('');
    try {
      const { data } = await axios.post(
        '/api/subscription/change',
        { userId: usuario.id, nuevoPlan: normalizePlan(nuevoPlan) },
        { headers: { Authorization: `Bearer ${token}` } }
      );

      if (data.success) {
        const planNorm = normalizePlan(data.plan);
        setPlanActual(planNorm);
        onPlanUpdated?.(data.usuario || { ...usuario, plan: planNorm });
        setShowPayment(false);
        setPlanSeleccionado(null);
        setExito(true);
        setTimeout(() => setExito(false), 3000);
      } else {
        setMensaje(data.message || 'No se pudo cambiar el plan.');
      }
    } catch (err) {
      setMensaje(err.response?.data?.message || err.response?.data?.error || 'Error al cambiar plan.');
    } finally {
      setProcesando(false);
    }
  };

  const handleSeleccionarPlan = (plan) => {
    if (!usuario || !token) {
      onAuthRedirect?.();
      return;
    }
    if (plan.id === planActual) return;

    if (plan.id === 'gratuito') {
      cambiarPlan('gratuito');
      return;
    }

    setPlanSeleccionado(plan);
    setShowPayment(true);
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-12 pb-24 relative">
      {exito && (
        <div className="fixed top-24 right-4 bg-green-600 text-white px-6 py-3 rounded-xl shadow-lg z-50 animate-in slide-in-from-top-4">
          ✓ Plan cambiado exitosamente
        </div>
      )}

      <div className="text-center mb-12">
        <h2 className="text-3xl font-extrabold text-primary-dark">Planes CropDoctor</h2>
        <p className="text-gray-500 mt-2 max-w-xl mx-auto">
          El plan gratuito incluye lo esencial. Pro y Empresa desbloquean superpoderes para tu campo.
        </p>
        <div className="mt-3 flex items-center justify-center gap-2 text-sm text-gray-600">
          Tu plan:
          <span className="font-bold capitalize">{planActual}</span>
          <PlanBadge plan={planActual} />
        </div>
      </div>

      {mensaje && (
        <p className="text-center text-sm text-red-600 bg-red-50 border border-red-100 rounded-xl p-3 mb-8">
          {mensaje}
        </p>
      )}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
        {PLANES.map((plan) => {
          const esActual = planActual === plan.id;
          const isPro = plan.id === 'pro';
          const isEmpresa = plan.id === 'empresa';

          return (
            <div
              key={plan.id}
              className={`rounded-2xl p-6 border-2 transition-all flex flex-col ${
                esActual
                  ? 'border-green-500 bg-green-50 shadow-lg scale-[1.02] md:scale-105'
                  : isEmpresa
                    ? 'border-blue-200 hover:border-blue-400 bg-gradient-to-b from-blue-50/80 to-white'
                    : isPro
                      ? 'border-green-200 hover:border-green-400 bg-gradient-to-b from-green-50/80 to-white'
                      : 'border-gray-200 hover:border-green-300 bg-white'
              }`}
            >
              {plan.badge && <div className="text-4xl mb-2">{plan.badge}</div>}

              <div className="flex items-center gap-2 flex-wrap">
                <h3 className="text-xl font-bold text-gray-900">{plan.name}</h3>
                {esActual && (
                  <span className="bg-green-500 text-white text-xs px-2 py-1 rounded-full font-bold">
                    ✓ Tu plan actual
                  </span>
                )}
              </div>

              <p className="text-3xl font-bold mt-3 text-gray-900">
                {plan.price === 0 ? (
                  'Gratis'
                ) : (
                  <>
                    Bs {plan.price}
                    <span className="text-sm font-normal text-gray-500">/mes</span>
                  </>
                )}
              </p>

              <ul className="mt-4 space-y-2 flex-1">
                {plan.features.map((f) => (
                  <li key={f} className="flex items-center gap-2 text-sm text-gray-700">
                    <span className="text-green-500 font-bold">✓</span>
                    {f}
                  </li>
                ))}
              </ul>

              <button
                type="button"
                onClick={() => handleSeleccionarPlan(plan)}
                disabled={esActual || procesando}
                className={`mt-6 w-full py-3 rounded-xl font-bold transition-all disabled:opacity-60 disabled:cursor-not-allowed ${
                  esActual
                    ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                    : isEmpresa
                      ? 'bg-blue-600 hover:bg-blue-700 text-white'
                      : isPro
                        ? 'bg-green-600 hover:bg-green-700 text-white'
                        : 'bg-gray-800 hover:bg-gray-900 text-white'
                }`}
              >
                {esActual ? 'Plan actual' : procesando ? 'Procesando...' : `Cambiar a ${plan.name}`}
              </button>
            </div>
          );
        })}
      </div>

      <p className="text-center text-xs text-gray-400 mt-10">
        Pago simulado para demo hackathon — sin cargo real en tarjeta.
      </p>

      {showPayment && planSeleccionado && (
        <PaymentModal
          plan={planSeleccionado}
          onClose={() => {
            setShowPayment(false);
            setPlanSeleccionado(null);
          }}
          onSuccess={() => cambiarPlan(planSeleccionado.id)}
        />
      )}
    </div>
  );
}
