import agriculturaImg from './videos/raphael-rychetsky-li9JfUHQfOY-unsplash.jpg';
import React, { useState, useEffect } from 'react';
import video2 from './videos/17642556-uhd_4096_2160_24fps.mp4';
import { motion } from 'framer-motion';
import axios from 'axios';
import {
  Scan,
  ShoppingBag,
  ShieldCheck,
  Truck,
  Coins,
  ArrowRight,
  Bot,
  CloudSun,
  Thermometer,
  Droplets,
  Wind,
  RefreshCw
} from 'lucide-react';
import ImpactCounters from '../components/ImpactCounters.jsx';

const P2P_EMOJI = {
  Cosecha: '🌾',
  Semillas: '🌱',
  Herramientas: '🔧',
  Animales: '🐄',
  Terrenos: '🗺️',
  Servicios: '👨‍🌾',
  Otros: '📦'
};

export default function Home({ onNavigate, clima, climaCargando, onRefreshClima }) {
  const videos = [video2];
  const [currentVideo, setCurrentVideo] = useState(0);
  const [publicacionesRecientes, setPublicacionesRecientes] = useState([]);
  const [loadingP2P, setLoadingP2P] = useState(false);
  const [statsP2P, setStatsP2P] = useState({ total: 0 });

  useEffect(() => {
    const interval = setInterval(() => {
      setCurrentVideo((prev) => (prev + 1) % videos.length);
    }, 9000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const fetchP2P = async () => {
      setLoadingP2P(true);
      try {
        const res = await axios.get('/api/p2p?limit=50');
        const data = res.data || [];
        setPublicacionesRecientes(data.slice(0, 6));
        setStatsP2P({ total: data.length });
      } catch (_) {
        setPublicacionesRecientes([]);
      } finally {
        setLoadingP2P(false);
      }
    };
    fetchP2P();
  }, []);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: { opacity: 1, transition: { staggerChildren: 0.15 } }
  };

  const itemVariants = {
    hidden: { y: 20, opacity: 0 },
    visible: { y: 0, opacity: 1, transition: { duration: 0.6, ease: 'easeOut' } }
  };

  return (
    <div className="pb-24 bg-[#e8f5e9] overflow-hidden">

      {/* 1. HERO SECTION CON VIDEO */}
      <section className="relative w-full min-h-[100vh] flex items-center justify-center text-white overflow-hidden py-32 px-6 sm:px-16">
        <video
          autoPlay
          loop
          muted
          playsInline
          className="absolute inset-0 w-full h-full object-cover"
        >
          <source src={videos[currentVideo]} type="video/mp4" />
        </video>

        {/* Fallback gradient */}
        <div className="absolute inset-0 -z-10" style={{
          background: 'linear-gradient(135deg, #1b3a1f 0%, #2e7d32 40%, #43a047 70%, #1b3a1f 100%)',
        }} />

        {/* Overlays */}
        <div className="absolute inset-0 z-[1]" style={{
          background: 'linear-gradient(to bottom, rgba(0,0,0,0.15), rgba(0,0,0,0.30))',
        }} />
        <div className="absolute inset-0 z-[1] pointer-events-none" style={{
          backgroundImage: 'repeating-linear-gradient(0deg, transparent, transparent 2px, rgba(255,255,255,0.012) 2px, rgba(255,255,255,0.012) 4px)',
        }} />

        {/* Blobs */}
        <div className="absolute top-1/4 left-1/5 w-[500px] h-[500px] rounded-full pointer-events-none z-[2]"
          style={{ background: 'radial-gradient(circle, rgba(46,125,50,0.20) 0%, transparent 70%)', filter: 'blur(60px)' }}
        />
        <div className="absolute bottom-1/3 right-1/5 w-[600px] h-[600px] rounded-full pointer-events-none z-[2]"
          style={{ background: 'radial-gradient(circle, rgba(27,58,31,0.14) 0%, transparent 70%)', filter: 'blur(80px)' }}
        />

        {/* Hero Content */}
        <motion.div
          variants={containerVariants}
          initial="hidden"
          animate="visible"
          className="max-w-5xl mx-auto text-center relative z-10 space-y-8"
        >
          <motion.div variants={itemVariants} className="inline-flex items-center gap-2 bg-white/10 backdrop-blur-md border border-white/15 px-4 py-2 rounded-full text-xs font-bold tracking-wide text-[#a5d6a7]">
            <span className="w-2 h-2 rounded-full bg-primary animate-pulse"></span>
            Hackathon Build With AI 2026 · Santa Cruz
          </motion.div>

          <motion.h1
            variants={itemVariants}
            className="text-5xl sm:text-7xl lg:text-8xl font-black tracking-tight leading-[0.9] text-white"
          >
            Detecta plagas.
            <br />
            <span className="text-[#66bb6a]">Antes de perder dinero.</span>
          </motion.h1>

          <motion.p
            variants={itemVariants}
            className="text-base sm:text-xl text-gray-200/90 max-w-3xl mx-auto font-light leading-relaxed"
          >
            Detecta plagas y enfermedades antes de perder tu cosecha utilizando inteligencia artificial
            entrenada en los cultivos y el clima del oriente cruceño.
          </motion.p>

          <motion.div variants={itemVariants} className="flex flex-wrap justify-center gap-5 pt-4">
            <button
              onClick={() => onNavigate('diagnose')}
              className="bg-primary hover:bg-[#43a047] text-white font-extrabold px-8 py-4 rounded-2xl shadow-[0_10px_25px_rgba(46,125,50,0.35)] hover:shadow-[0_15px_30px_rgba(67,160,71,0.5)] transition-all duration-300 flex items-center gap-3 transform hover:-translate-y-1 active:scale-95"
            >
              <Scan className="w-5 h-5" /> Diagnosticar mi cultivo
            </button>
            <button
              onClick={() => onNavigate('marketplace')}
              className="bg-white/10 hover:bg-white/20 backdrop-blur-md text-white font-extrabold px-8 py-4 rounded-2xl border border-white/20 hover:border-white/40 shadow-lg transition-all duration-300 flex items-center gap-3 transform hover:-translate-y-1 active:scale-95"
            >
              <ShoppingBag className="w-5 h-5 text-[#a5d6a7]" /> Explorar marketplace
            </button>
          </motion.div>

          {/* Stats bar glassmorphic */}
          <motion.div
            variants={itemVariants}
            className="grid grid-cols-1 sm:grid-cols-4 gap-8 max-w-4xl mx-auto mt-20 bg-[#1b3a1f]/40 backdrop-blur-md rounded-3xl p-8 border border-white/10 shadow-[0_20px_50px_rgba(0,0,0,0.15)]"
          >
            <div className="text-center py-2 sm:border-r border-white/10">
              <div className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#66bb6a] to-[#a5d6a7]">10K+</div>
              <div className="text-[10px] text-gray-300 font-extrabold uppercase tracking-widest mt-1">Agricultores Cruceños</div>
            </div>
            <div className="text-center py-2 sm:border-r border-white/10">
              <div className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#66bb6a] to-[#a5d6a7]">93%</div>
              <div className="text-[10px] text-gray-300 font-extrabold uppercase tracking-widest mt-1">Precisión de IA</div>
            </div>
            <div className="text-center py-2 sm:border-r border-white/10">
              <div className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#66bb6a] to-[#a5d6a7]">500+</div>
              <div className="text-[10px] text-gray-300 font-extrabold uppercase tracking-widest mt-1">Enfermedades Identificadas</div>
            </div>
            <div className="text-center py-2">
              <div className="text-4xl font-black text-transparent bg-clip-text bg-gradient-to-r from-[#66bb6a] to-[#a5d6a7]">
                {statsP2P.total > 0 ? `${statsP2P.total}+` : '50+'}
              </div>
              <div className="text-[10px] text-gray-300 font-extrabold uppercase tracking-widest mt-1">Publicaciones Activas</div>
            </div>
          </motion.div>
        </motion.div>

        {/* Scroll indicator */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 z-10 flex flex-col items-center gap-2 opacity-60">
          <span className="text-[10px] text-white/60 font-bold uppercase tracking-[0.2em]">Explorar</span>
          <div className="w-[1px] h-10 bg-gradient-to-b from-white/60 to-transparent animate-pulse" />
        </div>
      </section>

      {/* 2. WIDGET CLIMA (del hackaton1, con datos reales) */}
      {clima && (
        <section className="max-w-7xl mx-auto px-6 sm:px-16 -mt-10 relative z-20">
          <div className="bg-white border border-emerald-950/5 rounded-3xl p-6 sm:p-10 shadow-[0_15px_40px_rgba(4,47,31,0.04)] flex flex-col lg:flex-row items-center justify-between gap-8">
            <div className="space-y-3 max-w-2xl text-left">
              <div className="flex flex-wrap items-center gap-3">
                <span className="bg-[#43a047]/10 text-primary border border-[#43a047]/25 font-black text-xs uppercase tracking-widest px-3.5 py-1.5 rounded-full flex items-center gap-1.5">
                  <CloudSun className="w-3.5 h-3.5" /> AgroClima Santa Cruz
                </span>
                <span className="text-xs text-gray-400 font-bold">
                  Actualizado: {new Date().toLocaleDateString('es-BO', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                </span>
                {onRefreshClima && (
                  <button onClick={onRefreshClima} disabled={climaCargando}
                    className="text-primary hover:text-primary-dark transition-all disabled:opacity-50"
                    title="Actualizar clima">
                    <RefreshCw className={`w-4 h-4 ${climaCargando ? 'animate-spin' : ''}`} />
                  </button>
                )}
              </div>
              {clima.alerta_fitosanitaria && (
                <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
                  <p className="text-sm font-bold text-amber-800">{clima.alerta_fitosanitaria.titulo}</p>
                  <p className="text-xs text-amber-700 mt-1 italic">{clima.recomendacion_agronomica}</p>
                </div>
              )}
              {!clima.alerta_fitosanitaria && clima.recomendacion_agronomica && (
                <p className="text-sm text-gray-500 leading-relaxed italic border-l-2 border-primary/30 pl-4 py-1">
                  "{clima.recomendacion_agronomica}"
                </p>
              )}
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-5 w-full lg:w-auto bg-[#c8e6c9]/40 border border-[#a5d6a7]/30 p-5 rounded-2xl">
              <div className="text-center px-4 space-y-1">
                <Thermometer className="w-5 h-5 mx-auto text-[#2e7d32]" />
                <div className="text-2xl font-black text-primary-dark">{clima.clima_actual?.temperatura_celsius}°C</div>
                <div className="text-[10px] text-gray-400 font-extrabold uppercase tracking-wider">Temperatura</div>
              </div>
              <div className="text-center px-4 sm:border-l border-[#a5d6a7]/50 space-y-1">
                <Droplets className="w-5 h-5 mx-auto text-[#2e7d32]" />
                <div className="text-2xl font-black text-primary-dark">
                  {clima.clima_actual?.humedad_relative_porcentaje || clima.clima_actual?.humedad_relativa_porcentaje}%
                </div>
                <div className="text-[10px] text-gray-400 font-extrabold uppercase tracking-wider">Humedad</div>
              </div>
              <div className="text-center px-4 sm:border-l border-[#a5d6a7]/50 space-y-1">
                <CloudSun className="w-5 h-5 mx-auto text-[#2e7d32]" />
                <div className="text-2xl font-black text-primary-dark">{clima.clima_actual?.precipitacion_mm}mm</div>
                <div className="text-[10px] text-gray-400 font-extrabold uppercase tracking-wider">Lluvia</div>
              </div>
              <div className="text-center px-4 sm:border-l border-[#a5d6a7]/50 space-y-1">
                <Wind className="w-5 h-5 mx-auto text-[#2e7d32]" />
                <div className="text-2xl font-black text-primary-dark">{clima.clima_actual?.viento_kmh} km/h</div>
                <div className="text-[10px] text-gray-400 font-extrabold uppercase tracking-wider">Viento</div>
              </div>
            </div>
          </div>
        </section>
      )}

      {/* 3. IMPACT COUNTERS */}
      <div className="mt-16">
        <ImpactCounters />
      </div>

      {/* 4. MERCADO P2P (del hackaton1) */}
      <section className="max-w-7xl mx-auto px-6 sm:px-16 mt-16">
        <div className="flex items-center justify-between mb-6">
          <div>
            <h2 className="text-2xl font-extrabold text-primary-dark">🤝 Mercado entre Agricultores</h2>
            <p className="text-sm text-gray-500 mt-1">Lo que tus vecinos de Santa Cruz están vendiendo ahora</p>
          </div>
          <button
            type="button"
            onClick={() => onNavigate('marketplace')}
            className="text-sm font-bold text-primary hover:underline flex items-center gap-1"
          >
            Ver todo <ArrowRight className="w-4 h-4" />
          </button>
        </div>

        {loadingP2P ? (
          <div className="text-center py-10 text-gray-400 text-sm">Cargando publicaciones...</div>
        ) : publicacionesRecientes.length === 0 ? (
          <div className="text-center py-10 bg-amber-50 rounded-2xl border border-amber-100">
            <p className="text-amber-700 font-semibold text-sm">Aún no hay publicaciones. ¡Sé el primero en vender!</p>
            <button type="button" onClick={() => onNavigate('marketplace')}
              className="mt-3 bg-amber-500 hover:bg-amber-600 text-white font-bold px-5 py-2 rounded-xl text-xs transition-all">
              Publicar mi producto
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-4">
            {publicacionesRecientes.map((pub) => (
              <button type="button" key={pub.id} onClick={() => onNavigate('marketplace')}
                className="bg-white rounded-xl border border-gray-100 p-3 text-left cursor-pointer hover:shadow-md hover:border-amber-200 transition-all group">
                <div className="h-24 bg-amber-50 rounded-lg flex items-center justify-center text-3xl mb-2 overflow-hidden">
                  {pub.imagen_url ? (
                    <img src={pub.imagen_url} alt={pub.titulo} className="w-full h-full object-cover rounded-lg" />
                  ) : (P2P_EMOJI[pub.categoria] || '📦')}
                </div>
                <p className="text-xs font-bold text-gray-800 line-clamp-2 group-hover:text-amber-700 transition-colors leading-tight">
                  {pub.titulo}
                </p>
                <p className="text-xs font-black text-amber-600 mt-1">
                  {pub.es_gratis ? 'Gratis' : `${pub.precio_bob} BOB`}
                </p>
                <p className="text-[10px] text-gray-400 mt-0.5">📍 {pub.zona_santa_cruz}</p>
              </button>
            ))}
          </div>
        )}
      </section>

      {/* 5. FEATURES CARDS (diseño hackaton2) */}
      <section className="max-w-7xl mx-auto px-6 sm:px-16 mt-28">
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-3">
          <span className="text-[#2e7d32] font-extrabold text-xs uppercase tracking-widest">Startup AgTech Destacada</span>
          <h2 className="text-3xl sm:text-5xl font-black text-primary-dark tracking-tight leading-tight">
            Ecosistema de Precisión Digital
          </h2>
          <p className="text-gray-500 font-medium max-w-xl mx-auto">
            Integramos biotecnología, inteligencia satelital y soluciones financieras directas en una sola plataforma.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="bg-white rounded-3xl border border-emerald-950/5 p-8 shadow-soft hover:shadow-card hover:border-primary/20 transition-all duration-300 group flex flex-col justify-between">
            <div>
              <div className="bg-[#c8e6c9] p-4 rounded-2xl w-14 h-14 flex items-center justify-center text-[#2e7d32] mb-8 group-hover:bg-primary group-hover:text-white transition-all duration-300 shadow-inner">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <h3 className="text-2xl font-black text-primary-dark mb-4">Diagnóstico Fitosanitario</h3>
              <p className="text-sm text-gray-500 leading-relaxed font-medium">
                Escanea hojas enfermas de soya, caña, maíz y girasol. Nuestra IA evalúa severidad, causas específicas en zonas cruceñas y prescribe recetas agrónomas inmediatas.
              </p>
            </div>
            <button onClick={() => onNavigate('diagnose')}
              className="text-primary hover:text-[#43a047] font-extrabold text-sm flex items-center gap-2 mt-8 outline-none">
              Iniciar diagnóstico <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </button>
          </div>

          <div className="bg-white rounded-3xl border border-emerald-950/5 p-8 shadow-soft hover:shadow-card hover:border-primary/20 transition-all duration-300 group flex flex-col justify-between">
            <div>
              <div className="bg-[#c8e6c9] p-4 rounded-2xl w-14 h-14 flex items-center justify-center text-primary mb-8 group-hover:bg-primary group-hover:text-white transition-all duration-300 shadow-inner">
                <Truck className="w-6 h-6" />
              </div>
              <h3 className="text-2xl font-black text-primary-dark mb-4">Marketplace & Distribución</h3>
              <p className="text-sm text-gray-500 leading-relaxed font-medium">
                Adquiere pesticidas, fungicidas y fertilizantes certificados directamente de los distribuidores oficiales. Entregas express a Montero, Warnes y Pailón en 24hs.
              </p>
            </div>
            <button onClick={() => onNavigate('marketplace')}
              className="text-primary hover:text-[#43a047] font-extrabold text-sm flex items-center gap-2 mt-8 outline-none">
              Explorar agroinsumos <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </button>
          </div>

          <div className="bg-white rounded-3xl border border-emerald-950/5 p-8 shadow-soft hover:shadow-card hover:border-primary/20 transition-all duration-300 group flex flex-col justify-between">
            <div>
              <div className="bg-[#c8e6c9] p-4 rounded-2xl w-14 h-14 flex items-center justify-center text-primary mb-8 group-hover:bg-primary group-hover:text-white transition-all duration-300 shadow-inner">
                <Coins className="w-6 h-6" />
              </div>
              <h3 className="text-2xl font-black text-primary-dark mb-4">Financiamiento Fitosanitario</h3>
              <p className="text-sm text-gray-500 leading-relaxed font-medium">
                Tu bitácora digital de diagnósticos califica a tu parcela para microcréditos instantáneos pre-aprobados en Bs. Compra tus insumos a plazos y sin burocracia bancaria.
              </p>
            </div>
            <div className="mt-8">
              <span className="text-[#43a047] bg-[#43a047]/10 border border-[#43a047]/20 text-[10px] font-extrabold uppercase tracking-wider px-3.5 py-1.5 rounded-xl">
                Línea de Crédito Activa
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* 6. IMAGEN CINEMATOGRÁFICA */}
      <section className="relative h-[85vh] overflow-hidden w-full mt-24">
        <div className="absolute inset-0 bg-cover bg-center"
          style={{ backgroundImage: `url(${agriculturaImg})` }}
        />
        <div className="absolute inset-0" style={{
          background: 'linear-gradient(to bottom, rgba(0,0,0,0.20), rgba(0,0,0,0.40))'
        }} />
        <div className="relative z-10 h-full flex flex-col items-center justify-center text-center px-6">
          <span className="text-[#66bb6a] font-black tracking-[0.25em] uppercase text-sm">
            Inteligencia Agrícola
          </span>
          <h2 className="mt-6 text-white text-5xl md:text-7xl font-black leading-[0.95] max-w-5xl">
            Detecta plagas antes<br />de perder tu cosecha.
          </h2>
          <p className="mt-8 text-gray-300 text-lg max-w-3xl">
            CropDoctor combina inteligencia artificial, monitoreo climático y marketplace agrícola
            para productores del oriente boliviano.
          </p>
          <button onClick={() => onNavigate('diagnose')}
            className="mt-12 border border-white/30 bg-white/5 backdrop-blur-md hover:bg-white/10 hover:border-[#66bb6a] text-white font-bold px-8 py-4 rounded-full transition-all duration-300">
            Diagnosticar mi cultivo
          </button>
        </div>
      </section>

      {/* 7. CULTIVOS SOPORTADOS */}
      <section className="max-w-7xl mx-auto px-6 sm:px-16 mt-28 bg-primary-dark text-white rounded-[40px] py-16 relative overflow-hidden shadow-2xl">
        <div className="absolute top-0 right-0 w-[400px] h-[400px] rounded-full bg-[#43a047]/10 blur-[100px] pointer-events-none"></div>
        <div className="absolute bottom-0 left-0 w-[300px] h-[300px] rounded-full bg-primary/10 blur-[80px] pointer-events-none"></div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center relative z-10">
          <div className="space-y-6">
            <span className="text-[#66bb6a] font-extrabold text-xs uppercase tracking-widest">Soporte Biotecnológico</span>
            <h3 className="text-3xl sm:text-4xl font-black tracking-tight leading-tight">
              Entrenado para el Agro del Oriente Boliviano
            </h3>
            <p className="text-sm text-[#a5d6a7]/80 leading-relaxed font-light">
              Nuestra base de datos de IA se actualiza en tiempo real con las plagas y enfermedades más críticas
              que atacan a los cultivos cruceños, considerando las condiciones de temperatura e inundaciones.
            </p>
            <div className="grid grid-cols-2 gap-4 pt-4">
              {['Soya (Zonas Norte, Este, Sur)', 'Caña de Azúcar (Warnes, Montero)', 'Maíz (Todo el departamento)', 'Girasol y Trigo (Campañas invierno)'].map(c => (
                <div key={c} className="flex items-center gap-3 text-sm font-semibold">
                  <div className="w-2.5 h-2.5 bg-[#66bb6a] rounded-full flex-shrink-0"></div> {c}
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-md border border-white/10 rounded-3xl p-6 sm:p-8 space-y-6 shadow-2xl">
            <div className="flex items-center justify-between border-b border-white/10 pb-4">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-full bg-[#43a047]/25 flex items-center justify-center text-[#a5d6a7]">
                  <Bot className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-extrabold text-sm text-white">Escáner CropDoctor</h4>
                  <p className="text-[10px] text-[#a5d6a7]/80 font-semibold uppercase tracking-wider">Listo para analizar</p>
                </div>
              </div>
              <span className="text-[10px] bg-primary text-white font-black px-2.5 py-1 rounded-md">100% ONLINE</span>
            </div>
            <div className="space-y-4 text-xs font-medium text-emerald-100/90">
              <div className="bg-white/5 border border-white/5 p-4 rounded-2xl space-y-2">
                <div className="flex justify-between items-center text-[10px] font-extrabold uppercase text-[#a5d6a7]">
                  <span>Diagnóstico Sugerido</span>
                  <span className="text-red-400 font-black">CRÍTICO</span>
                </div>
                <h5 className="font-bold text-sm text-white">Roya Asiática de la Soya</h5>
                <p className="leading-relaxed">Causado por Phakopsora pachyrhizi, favorecido por lluvias seguidas en el Norte Integrado.</p>
              </div>
              <button onClick={() => onNavigate('diagnose')}
                className="w-full bg-primary hover:bg-[#43a047] text-white font-extrabold py-3.5 rounded-xl text-center shadow-lg transition-all">
                Probar Escáner IA
              </button>
            </div>
          </div>
        </div>
      </section>

    </div>
  );
}
