import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { ShoppingCart, Award, Check, Plus, Minus, Trash2, Shield, Sparkles, Search, Megaphone, Upload, Camera, X } from 'lucide-react';
import TarjetaP2P from '../components/TarjetaP2P.jsx';
import { abrirWhatsApp } from '../utils/whatsapp.js';
import { supabase } from '../lib/supabase.js';

const P2P_CATEGORIAS = ['Todos', 'Cosecha', 'Semillas', 'Herramientas', 'Animales', 'Terrenos', 'Servicios', 'Otros'];
const ZONAS_SC = ['Norte Integrado', 'Sur', 'Este', 'Valles', 'Chiquitanía', 'Ciudad'];

export default function Marketplace({
  usuario,
  cart,
  onAddCartItem,
  onRemoveCartItem,
  onChangeCartQty,
  onClearCart,
  token,
  onAuthRedirect
}) {
  const [marketTab, setMarketTab] = useState('tienda');
  const [products, setProducts] = useState([]);
  const [activeCategory, setActiveCategory] = useState('Todos');
  const [loading, setLoading] = useState(false);
  const [checkoutModalOpen, setCheckoutModalOpen] = useState(false);
  const [successModalOpen, setSuccessModalOpen] = useState(false);
  const [orderDetail, setOrderDetail] = useState(null);

  // P2P
  const [publicaciones, setPublicaciones] = useState([]);
  const [loadingP2P, setLoadingP2P] = useState(false);
  const [p2pSearch, setP2pSearch] = useState('');
  const [p2pCategoria, setP2pCategoria] = useState('Todos');
  const [showPublicarModal, setShowPublicarModal] = useState(false);
  const [publicarError, setPublicarError] = useState('');
  const [publicarLoading, setPublicarLoading] = useState(false);
  const [imagenPreview, setImagenPreview] = useState('');
  const [imagenBase64, setImagenBase64] = useState('');
  const imagenInputRef = useRef(null);
  const [nuevaPublicacion, setNuevaPublicacion] = useState({
    titulo: '',
    descripcion: '',
    precio_bob: '',
    es_gratis: false,
    categoria: 'Cosecha',
    zona_santa_cruz: '',
    whatsapp_numero: '',
    imagen_url: ''
  });

  // Fetch products from API on mount/filter change
  useEffect(() => {
    const fetchProducts = async () => {
      setLoading(true);
      try {
        const endpoint = activeCategory === 'Todos' 
          ? '/api/products' 
          : `/api/products?categoria=${activeCategory}`;
        const response = await axios.get(endpoint);
        setProducts(response.data);
      } catch (err) {
        console.error('Error fetching products:', err);
      } finally {
        setLoading(false);
      }
    };
    fetchProducts();
  }, [activeCategory]);

  useEffect(() => {
    if (usuario?.zona_santa_cruz) {
      setNuevaPublicacion((prev) => ({
        ...prev,
        zona_santa_cruz: prev.zona_santa_cruz || usuario.zona_santa_cruz
      }));
    }
  }, [usuario]);

  useEffect(() => {
    if (marketTab !== 'p2p') return;
    const fetchP2P = async () => {
      setLoadingP2P(true);
      try {
        const params = new URLSearchParams();
        if (p2pCategoria !== 'Todos') params.set('categoria', p2pCategoria);
        if (p2pSearch.trim()) params.set('q', p2pSearch.trim());
        const res = await axios.get(`/api/p2p?${params.toString()}`);
        setPublicaciones(res.data);
      } catch (err) {
        console.error('Error P2P:', err);
        setPublicaciones([]);
      } finally {
        setLoadingP2P(false);
      }
    };
    fetchP2P();
  }, [marketTab, p2pCategoria, p2pSearch]);

  const categories = ['Todos', 'Fungicidas', 'Fertilizantes', 'Herramientas', 'Semillas'];

  const getCategoryCount = (cat) => {
    // If local products loaded, return count
    if (cat === 'Todos') return products.length;
    return products.filter(p => p.categoria === cat).length;
  };

  const getProductSVGIcon = (cat) => {
    if (cat === 'Fungicidas') {
      return (
        <svg className="w-16 h-16 text-primary opacity-85 group-hover:scale-110 group-hover:rotate-3 transition-all duration-300" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
          <rect x="22" y="10" width="20" height="12" rx="2" fill="#2D7A3A" />
          <path d="M16 22H48V46C48 51.5228 43.5228 56 38 56H26C20.4772 56 16 51.5228 16 46V22Z" fill="#B3D7B9" stroke="#2D7A3A" stroke-width="3" />
          <circle cx="32" cy="38" r="8" fill="#5CB85C" />
          <path d="M32 34V42M28 38H36" stroke="white" stroke-width="2.5" stroke-linecap="round" />
        </svg>
      );
    }
    if (cat === 'Fertilizantes') {
      return (
        <svg className="w-16 h-16 text-primary opacity-85 group-hover:scale-110 group-hover:rotate-3 transition-all duration-300" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M12 12H52V52H12V12Z" fill="#CCE6D1" stroke="#2D7A3A" stroke-width="3" stroke-linejoin="round" />
          <path d="M12 18H52M12 46H52" stroke="#2D7A3A" stroke-width="2" />
          <path d="M32 24C32 24 24 32 28 36C32 40 32 40 32 40C32 40 32 40 36 36C40 32 32 24 32 24Z" fill="#5CB85C" stroke="#2D7A3A" stroke-width="2" />
        </svg>
      );
    }
    return (
      <svg className="w-16 h-16 text-primary opacity-85 group-hover:scale-110 group-hover:rotate-3 transition-all duration-300" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg">
        <circle cx="32" cy="32" r="28" fill="#E2EFE4" stroke="#2D7A3A" stroke-width="2" />
        <path d="M22 42L42 22" stroke="#2D7A3A" stroke-width="4" stroke-linecap="round" />
        <path d="M18 46L24 40M40 24L46 18" stroke="#5CB85C" stroke-width="4" stroke-linecap="round" />
        <circle cx="42" cy="22" r="3" fill="#FFC107" />
      </svg>
    );
  };

  const getCartTotal = () => {
    return cart.reduce(
      (sum, item) => sum + ((item.precio_bob ?? item.price_bob ?? 0) * item.quantity),
      0
    );
  };

  const handleContactarVendedor = async (pub) => {
    try {
      await axios.put(`/api/p2p/${pub.id}/vista`);
    } catch (_) {}
    abrirWhatsApp(pub.whatsapp_numero, pub);
  };

  const limpiarImagenPublicacion = () => {
    setImagenPreview('');
    setImagenBase64('');
    if (imagenInputRef.current) imagenInputRef.current.value = '';
  };

  const handleImagenPublicacion = (file) => {
    if (!file?.type.startsWith('image/')) {
      setPublicarError('Selecciona una imagen válida (JPG o PNG).');
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      setPublicarError('La imagen no debe superar 5 MB.');
      return;
    }
    setPublicarError('');
    const reader = new FileReader();
    reader.onload = (ev) => {
      const dataUrl = ev.target.result;
      setImagenPreview(dataUrl);
      setImagenBase64(dataUrl);
    };
    reader.readAsDataURL(file);
  };

  const handleImagenInputChange = (e) => {
    const file = e.target.files?.[0];
    if (file) handleImagenPublicacion(file);
  };

  const handleAbrirPublicar = () => {
    if (!usuario) {
      onAuthRedirect?.();
      return;
    }
    setPublicarError('');
    limpiarImagenPublicacion();
    setShowPublicarModal(true);
  };

  const handleCerrarPublicar = () => {
    setShowPublicarModal(false);
    limpiarImagenPublicacion();
  };

  const handlePublicarSubmit = async (e) => {
    e.preventDefault();
    if (!usuario || !token) {
      onAuthRedirect?.();
      return;
    }
    setPublicarLoading(true);
    setPublicarError('');
    try {
      const headers = { Authorization: `Bearer ${token}` };
      const payload = {
        ...nuevaPublicacion,
        ...(imagenBase64 ? { imagen_base64: imagenBase64 } : {})
      };
      const { data } = await axios.post('/api/p2p', payload, { headers });
      setPublicaciones((prev) => [data, ...prev]);
      if (data.aviso_imagen) {
        alert(data.aviso_imagen);
      }
      handleCerrarPublicar();
      setNuevaPublicacion({
        titulo: '',
        descripcion: '',
        precio_bob: '',
        es_gratis: false,
        categoria: 'Cosecha',
        zona_santa_cruz: usuario.zona_santa_cruz || '',
        whatsapp_numero: '',
        imagen_url: ''
      });
    } catch (err) {
      setPublicarError(err.response?.data?.error || 'No se pudo publicar. Intenta de nuevo.');
    } finally {
      setPublicarLoading(false);
    }
  };

  const handleMarcarVendido = async (id) => {
    if (!token || !usuario?.id) return;
    try {
      const pub = publicaciones.find((p) => p.id === id);
      const nombreProducto = pub?.titulo || 'Publicación P2P';
      const precioProducto = Number(pub?.precio_bob) || 0;

      // Insertar en pedidos como venta directa P2P con vendedor_id
      console.log('Insertando venta P2P:', { usuario_id: usuario.id, vendedor_id: usuario.id, nombre_producto: nombreProducto, precio_unitario: precioProducto });
      const { data: pedido, error: pedidoError } = await supabase
        .from('pedidos')
        .insert({
          usuario_id: usuario.id,
          producto_id: null,           // P2P no tiene producto_id en la tienda
          cantidad: 1,
          estado: 'completado',
          vendedor_id: usuario.id,
          precio_unitario: precioProducto,
          nombre_producto: nombreProducto
        })
        .select()
        .single();

      if (pedidoError) {
        console.error('Error al guardar venta P2P en pedidos:', pedidoError);
      } else {
        console.log('Venta P2P guardada en pedidos:', pedido);
      }

      // Eliminar la publicación P2P (siempre, independientemente del error en pedidos)
      await axios.delete(`/api/p2p/${id}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      setPublicaciones((prev) => prev.filter((p) => p.id !== id));
      window.dispatchEvent(new CustomEvent('stats-actualizar'));
      alert('¡Venta registrada! Ya aparece en tu historial.');
    } catch (err) {
      alert(err.response?.data?.error || 'Error al marcar como vendido');
    }
  };
  
  const marcarVendido = async (producto) => {
    if (!usuario?.id) return;

    const isObject = typeof producto === 'object' && producto !== null;
    const productoId = isObject ? producto.id : producto;
    const nombreProducto = isObject ? (producto.nombre || producto.titulo) : 'Insumo de Tienda';
    const precioProducto = isObject ? Number(producto.precio_bob) : 0;

    console.log('Insertando venta:', { usuario_id: usuario.id, producto_id: productoId, vendedor_id: usuario.id, nombre_producto: nombreProducto, precio_unitario: precioProducto });
    const { data, error } = await supabase
      .from('pedidos')
      .insert({
        usuario_id: usuario.id,
        producto_id: productoId,
        cantidad: 1,
        estado: 'completado',
        vendedor_id: usuario.id,
        precio_unitario: precioProducto,
        nombre_producto: nombreProducto
      })
      .select()
      .single();

    if (error) {
      console.error('Error al guardar venta:', error);
      alert('Error al registrar la venta: ' + error.message);
    } else {
      console.log('Venta guardada:', data);
      window.dispatchEvent(new CustomEvent('stats-actualizar'));
      alert('¡Venta registrada! Ya aparece en tu historial.');
    }
  };

  // Checkout process simulation with microcredit pre-approval
  const handleCheckoutSubmit = async () => {
    if (!usuario) {
      alert('Por favor inicia sesión para realizar tu pedido y calificar al microcrédito.');
      return;
    }

    try {
      // Simular la compra registrando la orden en la base de datos
      const headers = { Authorization: `Bearer ${token}` };
      
      // Registrar cada artículo en pedidos
      for (const item of cart) {
        await axios.post('/api/orders', {
          usuario_id: usuario.id,
          producto_id: item.id,
          cantidad: item.quantity
        }, { headers });
      }

      setOrderDetail({
        total: getCartTotal(),
        fecha: new Date().toLocaleDateString(),
        destino: `Parcela de ${usuario.nombre}, ${usuario.zona_santa_cruz}`,
        descuento: Math.round(getCartTotal() * 0.1) // 10% credit discount pre-approved!
      });

      setCheckoutModalOpen(false);
      setSuccessModalOpen(true);
      onClearCart();
      window.dispatchEvent(new CustomEvent('stats-actualizar'));
    } catch (err) {
      console.error(err);
      alert('Hubo un error al procesar el pedido. Revisa tu saldo/stock e intenta de nuevo.');
    }
  };

  return (
    <div className="max-w-6xl mx-auto px-4 py-12 pb-24">
      
      <div className="text-center max-w-2xl mx-auto mb-8">
        <h2 className="text-3xl font-extrabold text-primary-dark tracking-tight">
          Marketplace CropDoctor
        </h2>
        <p className="text-gray-500 mt-2">
          Tienda oficial de agroinsumos o compra/venta directa entre agricultores de Santa Cruz.
        </p>
      </div>

      <div className="flex justify-center mb-10">
        <div className="bg-gray-100 p-1 rounded-2xl flex gap-1">
          <button
            type="button"
            onClick={() => setMarketTab('tienda')}
            className={`px-6 sm:px-8 py-3 rounded-xl font-bold text-sm transition-all ${
              marketTab === 'tienda'
                ? 'bg-white text-primary-dark shadow-md'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            🏪 Tienda Oficial
          </button>
          <button
            type="button"
            onClick={() => setMarketTab('p2p')}
            className={`px-6 sm:px-8 py-3 rounded-xl font-bold text-sm transition-all ${
              marketTab === 'p2p'
                ? 'bg-white text-primary-dark shadow-md'
                : 'text-gray-500 hover:text-gray-700'
            }`}
          >
            🤝 Entre Agricultores
          </button>
        </div>
      </div>

      {marketTab === 'tienda' && (
        <>
      {/* Categories Filter list */}
      <div className="flex flex-wrap justify-center gap-3 mb-10">
        {categories.map(cat => (
          <button
            key={cat}
            onClick={() => setActiveCategory(cat)}
            className={`flex items-center gap-2 px-6 py-2.5 rounded-full font-bold text-sm border outline-none transition-all duration-300 ${
              activeCategory === cat
                ? 'bg-primary text-white border-primary shadow-md shadow-green-100'
                : 'bg-white text-gray-500 border-gray-200 hover:bg-green-50 hover:text-primary hover:border-green-300'
            }`}
          >
            {cat} 
            <span className={`text-xs px-2 py-0.5 rounded-full font-extrabold ${
              activeCategory === cat ? 'bg-white bg-opacity-20 text-white' : 'bg-gray-100 text-gray-500'
            }`}>
              {getCategoryCount(cat)}
            </span>
          </button>
        ))}
      </div>

      {/* Products Grid */}
      {loading ? (
        <div className="flex flex-col items-center justify-center py-20 gap-4 text-center">
          <div className="w-10 h-10 border-4 border-gray-200 border-t-primary rounded-full animate-spin"></div>
          <p className="text-sm text-gray-500 font-semibold">Cargando catálogo de agroinsumos...</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
          {products.map(p => (
            <div key={p.id} className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm hover:shadow-md hover:border-green-200 group flex flex-col justify-between transition-all duration-300">
              
              {/* Product illustration */}
              <div className="h-48 bg-gradient-to-br from-emerald-50 to-green-100 flex items-center justify-center relative p-6">
                {getProductSVGIcon(p.categoria)}
                <span className="absolute top-4 left-4 bg-white shadow-sm border border-gray-50 text-[10px] text-primary font-black uppercase tracking-wider px-2.5 py-1 rounded-md">
                  {p.zona_disponible || 'Santa Cruz'}
                </span>
              </div>

              {/* Product detailed body */}
              <div className="p-6 flex-1 flex flex-col justify-between gap-4">
                <div className="space-y-2">
                  <span className="text-[10px] text-gray-400 font-extrabold uppercase tracking-widest block">{p.categoria}</span>
                  <h4 className="font-extrabold text-gray-900 group-hover:text-primary transition-all line-clamp-2" title={p.nombre}>
                    {p.nombre}
                  </h4>
                  <p className="text-xs text-gray-500 line-clamp-2 leading-relaxed">{p.descripcion}</p>
                </div>

                <div className="flex items-center justify-between border-t border-gray-50 pt-4 mt-auto">
                  <div className="flex flex-col">
                    <span className="text-[9px] text-gray-400 font-bold uppercase tracking-wider">Precio Venta</span>
                    <span className="text-xl font-black text-primary-dark">{p.precio_bob} BOB</span>
                  </div>
                  {usuario && p.usuario_id === usuario.id ? (
                    <button
                      onClick={() => marcarVendido(p)}
                      className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-4 rounded-xl text-xs shadow-md flex items-center gap-1.5 transition-all duration-300 transform active:scale-95"
                    >
                      ✓ Marcar como vendido
                    </button>
                  ) : (
                    <button
                      onClick={() => onAddCartItem(p)}
                      className="bg-primary hover:bg-primary-dark text-white font-bold py-2 px-4 rounded-xl text-xs shadow-md flex items-center gap-1.5 transition-all duration-300 transform active:scale-95"
                    >
                      <Plus className="w-3.5 h-3.5" /> Añadir
                    </button>
                  )}
                </div>
              </div>

            </div>
          ))}
        </div>
      )}
        </>
      )}

      {marketTab === 'p2p' && (
        <div className="space-y-8">
          <div className="flex flex-col sm:flex-row gap-4 items-stretch sm:items-center justify-between">
            <div className="relative flex-1 max-w-md">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="search"
                value={p2pSearch}
                onChange={(e) => setP2pSearch(e.target.value)}
                placeholder="Buscar cosechas, herramientas..."
                className="w-full pl-10 pr-4 py-3 rounded-xl border border-gray-200 text-sm focus:border-amber-400 focus:ring-4 focus:ring-amber-50 outline-none"
              />
            </div>
            <button
              type="button"
              onClick={handleAbrirPublicar}
              className="bg-amber-500 hover:bg-amber-600 text-white font-bold px-6 py-3 rounded-xl shadow-md flex items-center justify-center gap-2 transition-all"
            >
              <Megaphone className="w-4 h-4" /> Vende tu Producto
            </button>
          </div>

          <div className="flex flex-wrap gap-2 justify-center">
            {P2P_CATEGORIAS.map((cat) => (
              <button
                key={cat}
                type="button"
                onClick={() => setP2pCategoria(cat)}
                className={`px-4 py-2 rounded-full text-xs font-bold border transition-all ${
                  p2pCategoria === cat
                    ? 'bg-amber-500 text-white border-amber-500'
                    : 'bg-white text-gray-500 border-gray-200 hover:border-amber-300'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {loadingP2P ? (
            <div className="text-center py-16 text-gray-500 text-sm font-semibold">
              Cargando publicaciones de agricultores cruceños...
            </div>
          ) : publicaciones.length === 0 ? (
            <div className="text-center py-16 bg-amber-50 rounded-2xl border border-amber-100">
              <p className="text-amber-800 font-semibold">No hay publicaciones aún en esta categoría.</p>
              <button
                type="button"
                onClick={handleAbrirPublicar}
                className="mt-4 bg-amber-500 text-white font-bold px-6 py-2.5 rounded-xl text-sm"
              >
                Sé el primero en publicar
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
              {publicaciones.map((pub) => (
                <TarjetaP2P
                  key={pub.id}
                  pub={pub}
                  onContactar={handleContactarVendedor}
                  esMio={usuario?.id === pub.usuario_id}
                  onMarcarVendido={handleMarcarVendido}
                />
              ))}
            </div>
          )}
        </div>
      )}

      {/* Floating Cart Panel Trigger when cart has items */}
      {marketTab === 'tienda' && cart.length > 0 && (
        <div className="fixed bottom-6 left-6 z-40">
          <button
            onClick={() => setCheckoutModalOpen(true)}
            className="bg-primary hover:bg-primary-dark text-white font-bold px-6 py-4 rounded-2xl shadow-xl hover:shadow-2xl transition-all duration-300 flex items-center gap-3 hover:scale-105"
          >
            <ShoppingCart className="w-5 h-5" /> 
            <span>Mi Pedido ({cart.reduce((sum, item) => sum + item.quantity, 0)})</span>
            <span className="bg-white bg-opacity-20 text-xs px-2.5 py-1 rounded-md font-extrabold">{getCartTotal()} BOB</span>
          </button>
        </div>
      )}

      {/* --- MOCK CHECKOUT MODAL (CART DRAWER DETAILED) --- */}
      {checkoutModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl w-full max-w-lg shadow-2xl overflow-hidden border border-gray-100 animate-in fade-in zoom-in-95 duration-200 max-h-[90vh] flex flex-col">
            
            <div className="p-6 border-b border-gray-100 flex items-center justify-between bg-primary-dark text-white">
              <h3 className="font-extrabold text-lg flex items-center gap-2">
                <ShoppingCart className="w-5 h-5" /> Confirmar Pedido de Agroinsumos
              </h3>
              <button 
                onClick={() => setCheckoutModalOpen(false)}
                className="text-white opacity-85 hover:opacity-100 hover:bg-white hover:bg-opacity-10 p-1 rounded-full transition-all"
              >
                <CloseIcon className="w-5 h-5" />
              </button>
            </div>

            {/* Cart items list scrollable */}
            <div className="flex-1 overflow-y-auto p-6 space-y-4 bg-gray-50">
              {cart.map(item => (
                <div key={item.id} className="bg-white border border-gray-150 p-4 rounded-xl flex items-center justify-between gap-4 shadow-sm">
                  <div className="flex-1 min-w-0">
                    <h5 className="font-bold text-gray-900 truncate text-sm">{item.name || item.nombre}</h5>
                    <p className="text-xs text-primary font-black mt-1">{item.precio_bob ?? item.price_bob} BOB</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <button 
                      onClick={() => onChangeCartQty(item.id, -1)}
                      className="p-1 border border-gray-200 rounded-md hover:bg-gray-50 text-gray-500"
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="font-bold text-sm w-4 text-center">{item.quantity}</span>
                    <button 
                      onClick={() => onChangeCartQty(item.id, 1)}
                      className="p-1 border border-gray-200 rounded-md hover:bg-gray-50 text-gray-500"
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                    <button 
                      onClick={() => onRemoveCartItem(item.id)}
                      className="text-gray-400 hover:text-accent-red p-1.5"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>

            {/* Pre-approved microcredit details */}
            <div className="p-6 border-t border-gray-150 bg-white space-y-4">
              <div className="bg-gradient-to-r from-green-50 to-emerald-50 border border-green-200 rounded-2xl p-4 flex gap-3.5">
                <Award className="w-6 h-6 text-primary flex-shrink-0" />
                <div className="space-y-1">
                  <h5 className="font-bold text-primary-dark text-xs uppercase tracking-wider">Línea de Crédito Agro Pre-Aprobada</h5>
                  <p className="text-xs text-gray-600 leading-relaxed font-semibold">
                    ¡Felicidades cruceño! Por tus diagnósticos activos en CropDoctor, tienes una línea de financiamiento lista. Este pedido se liquidará con un **10% de descuento directo** financiado por tu bitácora.
                  </p>
                </div>
              </div>

              <div className="space-y-2 text-sm border-b border-gray-50 pb-4">
                <div className="flex justify-between text-gray-500 font-semibold">
                  <span>Subtotal Insumos</span>
                  <span>{getCartTotal()} BOB</span>
                </div>
                <div className="flex justify-between text-gray-500 font-semibold">
                  <span>Envío express parcelas</span>
                  <span className="text-primary font-bold">Gratis</span>
                </div>
                <div className="flex justify-between text-gray-900 font-black text-base pt-2">
                  <span>Total Compra</span>
                  <span>{getCartTotal()} BOB</span>
                </div>
              </div>

              <button
                onClick={handleCheckoutSubmit}
                className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-3.5 rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 flex items-center justify-center gap-2"
              >
                <Shield className="w-4 h-4" /> Autorizar Microcrédito y Cargar Pedido
              </button>
            </div>

          </div>
        </div>
      )}

      {/* --- SUCCESS MODAL --- */}
      {successModalOpen && orderDetail && (
        <div className="fixed inset-0 bg-black bg-opacity-40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl w-full max-w-md shadow-2xl p-8 border border-gray-100 text-center animate-in fade-in zoom-in-95 duration-200">
            <div className="w-16 h-16 bg-green-50 text-primary border border-green-200 rounded-full flex items-center justify-center mx-auto mb-6 shadow-sm">
              <Check className="w-8 h-8" />
            </div>
            
            <h3 className="text-2xl font-black text-primary-dark">¡Pedido Registrado con Éxito!</h3>
            <p className="text-sm text-gray-500 mt-2">
              Se ha emitido tu orden de agroinsumos y tu microcrédito fitosanitario en bolivianos ha sido desembolsado.
            </p>

            <div className="bg-gray-50 border border-gray-150 rounded-2xl p-4 text-left text-xs space-y-2 mt-6">
              <div className="font-bold text-gray-700 text-xs border-b border-gray-200 pb-2 flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-primary" /> Datos del envío express en Santa Cruz:
              </div>
              <div className="grid grid-cols-3 font-semibold text-gray-600">
                <span className="font-bold">Total Factura:</span>
                <span className="col-span-2 text-primary-dark font-black">{orderDetail.total} BOB (Financiado)</span>
              </div>
              <div className="grid grid-cols-3 font-semibold text-gray-600">
                <span className="font-bold">Descuento:</span>
                <span className="col-span-2 text-green-700 font-bold">-{orderDetail.descuento} BOB (Abonado)</span>
              </div>
              <div className="grid grid-cols-3 font-semibold text-gray-600">
                <span className="font-bold">Destino:</span>
                <span className="col-span-2 truncate">{orderDetail.destino}</span>
              </div>
              <div className="grid grid-cols-3 font-semibold text-gray-600">
                <span className="font-bold">Entrega:</span>
                <span className="col-span-2 text-amber-600 font-bold">Menos de 24hs (Express)</span>
              </div>
            </div>

            <button
              onClick={() => setSuccessModalOpen(false)}
              className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-3.5 rounded-xl mt-6 shadow hover:shadow-md transition-all duration-300"
            >
              Volver a mi Campo
            </button>
          </div>
        </div>
      )}

      {showPublicarModal && (
        <div className="fixed inset-0 bg-black bg-opacity-40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl w-full max-w-lg shadow-2xl border border-amber-100 max-h-[90vh] overflow-y-auto">
            <div className="p-6 border-b border-amber-100 bg-gradient-to-r from-amber-50 to-orange-50">
              <h3 className="font-extrabold text-lg text-amber-900">Publicar en el mercado P2P</h3>
              <p className="text-xs text-amber-700 mt-1">Los compradores te contactarán por WhatsApp</p>
            </div>
            <form onSubmit={handlePublicarSubmit} className="p-6 space-y-4">
              {publicarError && (
                <p className="text-sm text-red-600 bg-red-50 border border-red-100 rounded-lg p-3">{publicarError}</p>
              )}
              <div>
                <label className="text-xs font-bold text-gray-600 uppercase">Título</label>
                <input
                  required
                  value={nuevaPublicacion.titulo}
                  onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, titulo: e.target.value })}
                  className="w-full mt-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm"
                  placeholder="Ej. 10 qq de soya cosechada"
                />
              </div>
              <div>
                <label className="text-xs font-bold text-gray-600 uppercase">Descripción</label>
                <textarea
                  required
                  rows={3}
                  value={nuevaPublicacion.descripcion}
                  onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, descripcion: e.target.value })}
                  className="w-full mt-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm"
                />
              </div>

              <div>
                <label className="text-xs font-bold text-gray-600 uppercase block mb-2">
                  Foto del producto (opcional)
                </label>
                <input
                  ref={imagenInputRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  className="hidden"
                  onChange={handleImagenInputChange}
                />
                {!imagenPreview ? (
                  <button
                    type="button"
                    onClick={() => imagenInputRef.current?.click()}
                    className="w-full border-2 border-dashed border-amber-200 rounded-2xl py-8 flex flex-col items-center gap-2 bg-amber-50/50 hover:bg-amber-50 hover:border-amber-400 transition-all"
                  >
                    <div className="w-12 h-12 rounded-full bg-white shadow-sm flex items-center justify-center text-amber-600">
                      <Camera className="w-6 h-6" />
                    </div>
                    <span className="text-sm font-bold text-amber-900">Toca para subir foto</span>
                    <span className="text-[10px] text-amber-700/80">JPG, PNG — máx. 5 MB</span>
                  </button>
                ) : (
                  <div className="relative rounded-2xl overflow-hidden border border-amber-200 bg-amber-50">
                    <img
                      src={imagenPreview}
                      alt="Vista previa"
                      className="w-full h-48 object-cover"
                    />
                    <button
                      type="button"
                      onClick={limpiarImagenPublicacion}
                      className="absolute top-2 right-2 bg-black/60 hover:bg-red-600 text-white p-2 rounded-full transition-all"
                      title="Quitar foto"
                    >
                      <X className="w-4 h-4" />
                    </button>
                    <button
                      type="button"
                      onClick={() => imagenInputRef.current?.click()}
                      className="absolute bottom-2 right-2 bg-white/95 text-amber-800 text-xs font-bold px-3 py-1.5 rounded-lg shadow flex items-center gap-1"
                    >
                      <Upload className="w-3.5 h-3.5" /> Cambiar foto
                    </button>
                  </div>
                )}
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="text-xs font-bold text-gray-600 uppercase">Categoría</label>
                  <select
                    value={nuevaPublicacion.categoria}
                    onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, categoria: e.target.value })}
                    className="w-full mt-1 border border-gray-200 rounded-xl px-3 py-2.5 text-sm"
                  >
                    {P2P_CATEGORIAS.filter((c) => c !== 'Todos').map((c) => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>
                <div>
                  <label className="text-xs font-bold text-gray-600 uppercase">Zona Santa Cruz</label>
                  <select
                    required
                    value={nuevaPublicacion.zona_santa_cruz}
                    onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, zona_santa_cruz: e.target.value })}
                    className="w-full mt-1 border border-gray-200 rounded-xl px-3 py-2.5 text-sm"
                  >
                    <option value="">Seleccionar...</option>
                    {ZONAS_SC.map((z) => (
                      <option key={z} value={z}>{z}</option>
                    ))}
                  </select>
                </div>
              </div>
              <div>
                <label className="text-xs font-bold text-gray-600 uppercase">WhatsApp (con código 591)</label>
                <input
                  required
                  value={nuevaPublicacion.whatsapp_numero}
                  onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, whatsapp_numero: e.target.value })}
                  className="w-full mt-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm"
                  placeholder="59171234567"
                />
              </div>
              <label className="flex items-center gap-2 text-sm font-semibold text-gray-700">
                <input
                  type="checkbox"
                  checked={nuevaPublicacion.es_gratis}
                  onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, es_gratis: e.target.checked })}
                />
                Es gratis / trueque
              </label>
              {!nuevaPublicacion.es_gratis && (
                <div>
                  <label className="text-xs font-bold text-gray-600 uppercase">Precio (BOB)</label>
                  <input
                    type="number"
                    min="0"
                    step="0.01"
                    required={!nuevaPublicacion.es_gratis}
                    value={nuevaPublicacion.precio_bob}
                    onChange={(e) => setNuevaPublicacion({ ...nuevaPublicacion, precio_bob: e.target.value })}
                    className="w-full mt-1 border border-gray-200 rounded-xl px-4 py-2.5 text-sm"
                  />
                </div>
              )}
              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={handleCerrarPublicar}
                  className="flex-1 border border-gray-200 font-bold py-3 rounded-xl text-sm text-gray-600"
                >
                  Cancelar
                </button>
                <button
                  type="submit"
                  disabled={publicarLoading}
                  className="flex-1 bg-amber-500 hover:bg-amber-600 text-white font-bold py-3 rounded-xl text-sm disabled:opacity-60"
                >
                  {publicarLoading
                    ? imagenBase64
                      ? 'Subiendo foto...'
                      : 'Publicando...'
                    : 'Publicar'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

    </div>
  );
}

// Simple absolute wrapper for clean close operations
function CloseIcon({ className, ...props }) {
  return (
    <svg className={className} {...props} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth="2.5">
      <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
    </svg>
  );
}
