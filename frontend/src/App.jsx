import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { ShoppingCart, Menu, X, LogIn, LogOut, UserCheck } from 'lucide-react';
import logoNavbarBlanco from './assets/LogoHorizontalBlanco__1_.png';
import logoNavbarVerde from './assets/LogoHorizontalVerde.png';

// Importar Pantallas
import Home from './pages/Home.jsx';
import Diagnosis from './pages/Diagnosis.jsx';
import Marketplace from './pages/Marketplace.jsx';
import History from './pages/History.jsx';
import Plans from './pages/Plans.jsx';
import PlagueMap from './pages/PlagueMap.jsx';

// Importar Componentes
import AuthModal from './components/AuthModal.jsx';
import ChatBot from './components/ChatBot.jsx';
import LimitModal from './components/LimitModal.jsx';
import UsageBar from './components/UsageBar.jsx';
import PlanBadge from './components/PlanBadge.jsx';
import { isFreePlan } from './utils/planUtils.js';

export default function App() {
  const [activeTab, setActiveTab] = useState('home'); // 'home' | 'diagnose' | 'marketplace' | 'history'
  const [usuario, setUsuario] = useState(null);
  const [token, setToken] = useState('');
  const [cart, setCart] = useState([]);
  const [clima, setClima] = useState(null);
  const [climaCargando, setClimaCargando] = useState(false);
  const [authModalOpen, setAuthModalOpen] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [subStatus, setSubStatus] = useState(null);
  const [limitModalOpen, setLimitModalOpen] = useState(false);
  const [historyRefreshKey, setHistoryRefreshKey] = useState(0);
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY > 10) {
        setScrolled(true);
      } else {
        setScrolled(false);
      }
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const fetchSubStatus = async () => {
    if (!token) {
      setSubStatus(null);
      return;
    }
    try {
      const r = await axios.get('/api/subscription/status', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setSubStatus(r.data);
    } catch {
      setSubStatus(null);
    }
  };

  const fetchWeather = async () => {
    setClimaCargando(true);
    try {
      const response = await axios.get('/api/weather/santa-cruz', {
        params: { _: Date.now() },
        headers: { 'Cache-Control': 'no-cache', Pragma: 'no-cache' }
      });
      setClima(response.data);
    } catch (err) {
      console.warn('Error al conectar con la API de clima local:', err);
    } finally {
      setClimaCargando(false);
    }
  };

  // Cargar sesión persistente de localStorage al montar
  useEffect(() => {
    const savedToken = localStorage.getItem('cropdoctor_token');
    const savedUser = localStorage.getItem('cropdoctor_user');

    if (savedToken && savedUser) {
      setToken(savedToken);
      setUsuario(JSON.parse(savedUser));
    }

    fetchWeather();
    const intervalo = setInterval(fetchWeather, 60 * 60 * 1000);
    return () => clearInterval(intervalo);
  }, []);

  useEffect(() => {
    if (token) fetchSubStatus();
  }, [token]);

  useEffect(() => {
    const handler = () => setHistoryRefreshKey((k) => k + 1);
    window.addEventListener('stats-actualizar', handler);
    return () => window.removeEventListener('stats-actualizar', handler);
  }, []);

  useEffect(() => {
    if (activeTab === 'history' && usuario?.id) {
      setHistoryRefreshKey((k) => k + 1);
    }
  }, [activeTab, usuario?.id]);

  // Al volver a Inicio, refrescar clima (por si estuvo mucho en otra pestaña)
  useEffect(() => {
    if (activeTab === 'home') {
      fetchWeather();
    }
  }, [activeTab]);

  const handleAuthSuccess = (user, jwtToken) => {
    setUsuario(user);
    setToken(jwtToken);
    localStorage.setItem('cropdoctor_user', JSON.stringify(user));
    localStorage.setItem('cropdoctor_token', jwtToken);
    setTimeout(() => fetchSubStatus(), 100);
  };

  const handlePlanUpdated = (updatedUser) => {
    if (updatedUser) {
      setUsuario(updatedUser);
      localStorage.setItem('cropdoctor_user', JSON.stringify(updatedUser));
    }
    fetchSubStatus();
  };

  const handleSignOut = () => {
    localStorage.removeItem('cropdoctor_token');
    localStorage.removeItem('cropdoctor_user');
    setUsuario(null);
    setToken('');
    setActiveTab('home');
  };

  // Carrito de compras
  const handleAddCartItem = (product) => {
    setCart(prev => {
      const exists = prev.find(item => item.id === product.id);
      if (exists) {
        return prev.map(item => 
          item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
        );
      }
      return [...prev, { ...product, quantity: 1 }];
    });
  };

  const handleRemoveCartItem = (productId) => {
    setCart(prev => prev.filter(item => item.id !== productId));
  };

  const handleChangeCartQty = (productId, delta) => {
    setCart(prev => prev.map(item => {
      if (item.id === productId) {
        const newQty = item.quantity + delta;
        return newQty > 0 ? { ...item, quantity: newQty } : item;
      }
      return item;
    }).filter(item => item.quantity > 0));
  };

  const handleClearCart = () => {
    setCart([]);
  };

  const handleRecommendRedirect = (category) => {
    // Redirige al marketplace y aplica filtro por categoría (ej. Fungicidas)
    setActiveTab('marketplace');
  };

  return (
    <div className="flex flex-col min-h-screen bg-bg">
      
      {/* 5. NAVBAR (Fijo superior) */}
      <nav className={`fixed z-40 flex items-center justify-between px-6 sm:px-12 transition-all duration-500 ease-in-out ${
        scrolled
          ? 'top-4 left-4 right-4 sm:left-6 sm:right-6 md:left-12 md:right-12 h-18 bg-white/90 backdrop-blur-lg border border-gray-200/80 shadow-lg rounded-2xl'
          : activeTab === 'home'
          ? 'top-0 left-0 right-0 h-20 bg-transparent border-transparent'
          : 'top-0 left-0 right-0 h-20 bg-white/80 backdrop-blur-md border-b border-gray-100'
      }`}>
        <a 
          href="#" 
          onClick={() => setActiveTab('home')}
          className="flex items-center outline-none hover:opacity-80 transition-all duration-300"
        >
          <img
            src={scrolled || activeTab !== 'home' ? logoNavbarVerde : logoNavbarBlanco}
            alt="SembrIA"
            className="h-9 w-auto transition-all duration-500"
          />
        </a>

        {/* Desktop links */}
        <ul className="hidden md:flex items-center gap-8 font-bold text-sm text-gray-500">
          <li>
            <button 
              onClick={() => setActiveTab('home')}
              className={`hover:text-primary transition-all outline-none py-2 relative ${
                activeTab === 'home' ? 'text-primary after:content-[""] after:absolute after:bottom-0 after:left-0 after:w-full after:height-[2px] after:bg-primary after:h-0.5' : ''
              }`}
            >
              Inicio
            </button>
          </li>
          <li>
            <button 
              onClick={() => setActiveTab('diagnose')}
              className={`hover:text-primary transition-all outline-none py-2 relative ${
                activeTab === 'diagnose' ? 'text-primary after:content-[""] after:absolute after:bottom-0 after:left-0 after:w-full after:height-[2px] after:bg-primary after:h-0.5' : ''
              }`}
            >
              Diagnosticar
            </button>
          </li>
          <li>
            <button 
              onClick={() => setActiveTab('marketplace')}
              className={`hover:text-primary transition-all outline-none py-2 relative ${
                activeTab === 'marketplace' ? 'text-primary after:content-[""] after:absolute after:bottom-0 after:left-0 after:w-full after:height-[2px] after:bg-primary after:h-0.5' : ''
              }`}
            >
              Marketplace
            </button>
          </li>
          <li>
            <button 
              onClick={() => setActiveTab('mapa')}
              className={`hover:text-primary transition-all outline-none py-2 relative ${
                activeTab === 'mapa' ? 'text-primary after:content-[""] after:absolute after:bottom-0 after:left-0 after:w-full after:height-[2px] after:bg-primary after:h-0.5' : ''
              }`}
            >
              🗺️ Mapa
            </button>
          </li>
          <li>
            <button 
              onClick={() => setActiveTab('history')}
              className={`hover:text-primary transition-all outline-none py-2 relative ${
                activeTab === 'history' ? 'text-primary after:content-[""] after:absolute after:bottom-0 after:left-0 after:w-full after:height-[2px] after:bg-primary after:h-0.5' : ''
              }`}
            >
              Mi Campo
            </button>
          </li>
          <li>
            <button 
              onClick={() => setActiveTab('planes')}
              className={`hover:text-primary transition-all outline-none py-2 relative ${
                activeTab === 'planes' ? 'text-primary after:content-[""] after:absolute after:bottom-0 after:left-0 after:w-full after:height-[2px] after:bg-primary after:h-0.5' : ''
              }`}
            >
              Planes
            </button>
          </li>
        </ul>

        {/* Right actions */}
        <div className="flex items-center gap-4">
          
          {/* Shopping Cart button trigger */}
          <button 
            onClick={() => setActiveTab('marketplace')}
            className="relative p-2 text-gray-500 hover:text-primary hover:bg-green-50 rounded-full transition-all"
            aria-label="Carrito"
          >
            <ShoppingCart className="w-5.5 h-5.5" />
            <div className="absolute -top-1.5 -right-1.5 bg-accent-amber border-2 border-white text-gray-900 font-extrabold text-[10px] min-w-[18px] h-[18px] px-1 rounded-full flex items-center justify-center transition-all duration-300">
              {cart.reduce((sum, item) => sum + item.quantity, 0)}
            </div>
          </button>

          {/* User auth action */}
          {usuario ? (
            <div className="hidden md:flex items-center gap-3">
              <span className="text-xs text-gray-500 font-bold flex items-center gap-1 bg-green-50 border border-green-100 rounded-lg px-3 py-1.5">
                <UserCheck className="w-3.5 h-3.5 text-primary" /> {usuario.nombre}
                <PlanBadge plan={usuario.plan} />
              </span>
              <button 
                onClick={handleSignOut}
                className="p-2 text-gray-400 hover:text-accent-red hover:bg-red-50 rounded-full transition-all"
                title="Cerrar sesión"
              >
                <LogOut className="w-5 h-5" />
              </button>
            </div>
          ) : (
            <button
              onClick={() => setAuthModalOpen(true)}
              className="hidden md:flex bg-primary hover:bg-primary-dark text-white font-bold py-2.5 px-5 rounded-xl text-xs shadow-md flex items-center gap-2 transition-all duration-300"
            >
              <LogIn className="w-4 h-4" /> Iniciar Sesión
            </button>
          )}

          {/* Hamburger toggle mobile menu */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 text-gray-500 hover:text-primary rounded-full transition-all"
            aria-label="Menú móvil"
          >
            {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>
      </nav>

      {/* Mobile menu panel dropdown */}
      {mobileMenuOpen && (
        <div className="md:hidden fixed top-20 left-0 w-full bg-white border-b border-gray-150 shadow-xl z-35 flex flex-col font-bold text-sm text-gray-500 animate-in slide-in-from-top-6 duration-200">
          <button 
            onClick={() => { setActiveTab('home'); setMobileMenuOpen(false); }}
            className={`py-4 px-6 text-left border-b border-gray-50 hover:bg-green-50 hover:text-primary ${activeTab === 'home' ? 'text-primary bg-green-50 bg-opacity-50' : ''}`}
          >
            Inicio
          </button>
          <button 
            onClick={() => { setActiveTab('diagnose'); setMobileMenuOpen(false); }}
            className={`py-4 px-6 text-left border-b border-gray-50 hover:bg-green-50 hover:text-primary ${activeTab === 'diagnose' ? 'text-primary bg-green-50 bg-opacity-50' : ''}`}
          >
            Diagnosticar
          </button>
          <button 
            onClick={() => { setActiveTab('marketplace'); setMobileMenuOpen(false); }}
            className={`py-4 px-6 text-left border-b border-gray-50 hover:bg-green-50 hover:text-primary ${activeTab === 'marketplace' ? 'text-primary bg-green-50 bg-opacity-50' : ''}`}
          >
            Marketplace
          </button>
          <button 
            onClick={() => { setActiveTab('mapa'); setMobileMenuOpen(false); }}
            className={`py-4 px-6 text-left border-b border-gray-50 hover:bg-green-50 hover:text-primary ${activeTab === 'mapa' ? 'text-primary bg-green-50 bg-opacity-50' : ''}`}
          >
            Mapa de Plagas
          </button>
          <button 
            onClick={() => { setActiveTab('history'); setMobileMenuOpen(false); }}
            className={`py-4 px-6 text-left border-b border-gray-50 hover:bg-green-50 hover:text-primary ${activeTab === 'history' ? 'text-primary bg-green-50 bg-opacity-50' : ''}`}
          >
            Mi Campo
          </button>
          <button 
            onClick={() => { setActiveTab('planes'); setMobileMenuOpen(false); }}
            className={`py-4 px-6 text-left border-b border-gray-50 hover:bg-green-50 hover:text-primary ${activeTab === 'planes' ? 'text-primary bg-green-50 bg-opacity-50' : ''}`}
          >
            Planes
          </button>

          {usuario ? (
            <div className="p-4 border-t border-gray-100 flex items-center justify-between bg-gray-50">
              <span className="text-xs font-bold text-gray-700 flex items-center">
                {usuario.nombre}
                <PlanBadge plan={usuario.plan} />
              </span>
              <button 
                onClick={() => { handleSignOut(); setMobileMenuOpen(false); }}
                className="text-xs text-accent-red font-bold flex items-center gap-1.5"
              >
                <LogOut className="w-4 h-4" /> Cerrar Sesión
              </button>
            </div>
          ) : (
            <button
              onClick={() => { setAuthModalOpen(true); setMobileMenuOpen(false); }}
              className="m-4 bg-primary hover:bg-primary-dark text-white font-bold py-3 px-6 rounded-xl text-center shadow-md flex items-center justify-center gap-2"
            >
              <LogIn className="w-4 h-4" /> Iniciar Sesión
            </button>
          )}
        </div>
      )}

      {/* Main Pages viewport body (Adjusted for Fixed top header margin) */}
      <main className={`flex-1 ${activeTab === 'home' ? 'pt-0' : 'pt-20'}`}>
        {activeTab !== 'home' && subStatus && isFreePlan(subStatus.plan) && !subStatus?.ilimitado && (
          <UsageBar
            usados={subStatus.diagnosticos_mes ?? subStatus.diagnosticos_hoy}
            limite={subStatus.limite_gratis || 10}
            onUpgrade={() => setActiveTab('planes')}
          />
        )}
        {activeTab === 'home' && (
          <Home
            onNavigate={setActiveTab}
            clima={clima}
            climaCargando={climaCargando}
            onRefreshClima={fetchWeather}
          />
        )}
        {activeTab === 'diagnose' && (
          <Diagnosis
            usuario={usuario}
            token={token}
            onRecommendRedirect={handleRecommendRedirect}
            onLimitReached={() => setLimitModalOpen(true)}
            onDiagnosisDone={() => {
              fetchSubStatus();
              setHistoryRefreshKey((k) => k + 1);
            }}
          />
        )}
        {activeTab === 'mapa' && <PlagueMap />}
        {activeTab === 'planes' && (
          <Plans
            usuario={usuario}
            token={token}
            onAuthRedirect={() => setAuthModalOpen(true)}
            onPlanUpdated={handlePlanUpdated}
          />
        )}
        {activeTab === 'marketplace' && (
          <Marketplace
            usuario={usuario}
            cart={cart}
            token={token}
            onAddCartItem={handleAddCartItem}
            onRemoveCartItem={handleRemoveCartItem}
            onChangeCartQty={handleChangeCartQty}
            onClearCart={handleClearCart}
            onAuthRedirect={() => setAuthModalOpen(true)}
          />
        )}
        {activeTab === 'history' && (
          <History
            usuario={usuario}
            token={token}
            subStatus={subStatus}
            clima={clima}
            climaCargando={climaCargando}
            onRefreshClima={fetchWeather}
            refreshKey={historyRefreshKey}
            onAuthRedirect={() => setAuthModalOpen(true)}
          />
        )}
      </main>

      {/* FOOTER */}
      <footer className="bg-green-950 text-green-200 border-t border-green-900 mt-auto">
        <div className="max-w-6xl mx-auto px-6 py-12 space-y-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            <div className="space-y-4">
              <img src={logoNavbarBlanco} alt="SembrIA" className="h-8 w-auto" />
              <p className="text-xs text-green-300 leading-relaxed">
                Potenciando la soberanía alimentaria del oriente boliviano mediante tecnología de IA, logística de insumos justa y créditos agrícolas rápidos.
              </p>
            </div>
            <div>
              <h5 className="font-bold text-white text-xs uppercase tracking-wider mb-4">Navegación</h5>
              <ul className="space-y-2 text-xs">
                <li><button onClick={() => setActiveTab('home')} className="hover:text-white transition-all">Inicio</button></li>
                <li><button onClick={() => setActiveTab('diagnose')} className="hover:text-white transition-all">Diagnosticar</button></li>
                <li><button onClick={() => setActiveTab('marketplace')} className="hover:text-white transition-all">Marketplace</button></li>
                <li><button onClick={() => setActiveTab('history')} className="hover:text-white transition-all">Mi Campo</button></li>
              </ul>
            </div>
            <div>
              <h5 className="font-bold text-white text-xs uppercase tracking-wider mb-4">Comunidad</h5>
              <ul className="space-y-2 text-xs">
                <li><a href="#" className="hover:text-white">Casos de Éxito</a></li>
                <li><a href="#" className="hover:text-white">Asociaciones Agro</a></li>
                <li><a href="#" className="hover:text-white">Calendario de Siembras</a></li>
              </ul>
            </div>
            <div>
              <h5 className="font-bold text-white text-xs uppercase tracking-wider mb-4">Soporte</h5>
              <ul className="space-y-2 text-xs">
                <li><a href="#" className="hover:text-white">Términos Legales</a></li>
                <li><a href="#" className="hover:text-white">Contacto Agrónomos</a></li>
                <li><a href="#" className="hover:text-white">Santa Cruz, Bolivia</a></li>
              </ul>
            </div>
          </div>
          <div className="border-t border-green-900 pt-6 text-center text-[10px] text-green-400 flex flex-col sm:flex-row items-center justify-between gap-4">
            <p>&copy; 2026 SembrIA S.A. Todos los derechos reservados. Hackathon Build With AI 2026.</p>
            <div>Santa Cruz de la Sierra, Bolivia</div>
          </div>
        </div>
      </footer>

      {/* FLOATING VIRTUAL AGRONOMIST */}
      <ChatBot />

      {/* MODAL AUTHENTICATION GATE */}
      <AuthModal 
        isOpen={authModalOpen} 
        onClose={() => setAuthModalOpen(false)}
        onAuthSuccess={handleAuthSuccess}
      />

      <LimitModal
        open={limitModalOpen}
        onClose={() => setLimitModalOpen(false)}
        onUpgrade={() => {
          setLimitModalOpen(false);
          setActiveTab('planes');
        }}
      />

    </div>
  );
}
