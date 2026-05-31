import React, { useState } from 'react';
import axios from 'axios';
import { X, Phone, Lock, User, MapPin, Sprout } from 'lucide-react';

export default function AuthModal({ isOpen, onClose, onAuthSuccess }) {
  const [isLogin, setIsLogin] = useState(true);
  const [formData, setFormData] = useState({
    nombre: '',
    email: '',
    password: '',
    zona_santa_cruz: 'Norte Integrado',
    cultivo_principal: 'Soya'
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const endpoint = isLogin ? '/api/auth/login' : '/api/auth/register';
      
      // Enviar solicitud de autenticación
      const response = await axios.post(endpoint, {
        nombre: formData.nombre,
        email: formData.email,
        password: formData.password,
        zona_santa_cruz: formData.zona_santa_cruz,
        cultivo_principal: formData.cultivo_principal
      });

      if (response.data.token) {
        localStorage.setItem('cropdoctor_token', response.data.token);
        localStorage.setItem('cropdoctor_user', JSON.stringify(response.data.usuario));
        onAuthSuccess(response.data.usuario, response.data.token);
        onClose();
      }
    } catch (err) {
      console.error(err);
      setError(err.response?.data?.error || 'Ocurrió un error en la autenticación. Intenta nuevamente.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-40 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl w-full max-w-md shadow-2xl overflow-hidden border border-gray-100 relative animate-in fade-in zoom-in-95 duration-200">
        
        {/* Close Button */}
        <button 
          onClick={onClose}
          className="absolute top-4 right-4 p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-50 rounded-full transition-all duration-300"
          aria-label="Cerrar modal"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="p-8">
          <div className="text-center mb-8">
            <h3 className="text-2xl font-extrabold text-primary-dark">
              {isLogin ? 'Iniciar Sesión' : 'Registrarse'}
            </h3>
            <p className="text-sm text-gray-500 mt-2">
              {isLogin 
                ? 'Ingresa a tu historial de parcelas y créditos pre-aprobados' 
                : 'Únete a la red digital de agricultores en Santa Cruz'}
            </p>
          </div>

          {error && (
            <div className="bg-red-50 text-red-600 border border-red-100 rounded-lg p-3 text-sm mb-6 font-medium text-center">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            
            {/* Campo Nombre (solo registro) */}
            {!isLogin && (
              <div className="space-y-1">
                <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Nombre Completo</label>
                <div className="relative">
                  <User className="w-5 h-5 text-gray-400 absolute left-3 top-3.5" />
                  <input
                    type="text"
                    name="nombre"
                    value={formData.nombre}
                    onChange={handleChange}
                    placeholder="Ej. Juan Mamani"
                    className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl outline-none focus:border-primary focus:bg-white focus:ring-4 focus:ring-green-50 transition-all duration-200"
                    required={!isLogin}
                  />
                </div>
              </div>
            )}

            {/* Campo Correo Electrónico */}
            <div className="space-y-1">
              <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Correo Electrónico</label>
              <div className="relative">
                <Phone className="w-5 h-5 text-gray-400 absolute left-3 top-3.5" />
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  placeholder="Ej. juan.mamani@agro.bo"
                  className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl outline-none focus:border-primary focus:bg-white focus:ring-4 focus:ring-green-50 transition-all duration-200"
                  required
                />
              </div>
            </div>

            {/* Campo Contraseña */}
            <div className="space-y-1">
              <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Contraseña</label>
              <div className="relative">
                <Lock className="w-5 h-5 text-gray-400 absolute left-3 top-3.5" />
                <input
                  type="password"
                  name="password"
                  value={formData.password}
                  onChange={handleChange}
                  placeholder="••••••••"
                  className="w-full pl-10 pr-4 py-3 bg-gray-50 border border-gray-200 rounded-xl outline-none focus:border-primary focus:bg-white focus:ring-4 focus:ring-green-50 transition-all duration-200"
                  required
                />
              </div>
            </div>

            {/* Campos adicionales (solo registro) */}
            {!isLogin && (
              <div className="grid grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Región</label>
                  <div className="relative">
                    <MapPin className="w-4 h-4 text-gray-400 absolute left-3 top-3.5" />
                    <select
                      name="zona_santa_cruz"
                      value={formData.zona_santa_cruz}
                      onChange={handleChange}
                      className="w-full pl-8 pr-2 py-3 bg-gray-50 border border-gray-200 rounded-xl outline-none text-sm focus:border-primary focus:bg-white transition-all"
                    >
                      <option value="Norte Integrado">Norte Integrado</option>
                      <option value="Este">Zona Este</option>
                      <option value="Sur">Zona Sur</option>
                      <option value="Valles">Valles Cruceños</option>
                      <option value="Chiquitanía">Chiquitanía</option>
                    </select>
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Cultivo</label>
                  <div className="relative">
                    <Sprout className="w-4 h-4 text-gray-400 absolute left-3 top-3.5" />
                    <select
                      name="cultivo_principal"
                      value={formData.cultivo_principal}
                      onChange={handleChange}
                      className="w-full pl-8 pr-2 py-3 bg-gray-50 border border-gray-200 rounded-xl outline-none text-sm focus:border-primary focus:bg-white transition-all"
                    >
                      <option value="Soya">Soya</option>
                      <option value="Maíz">Maíz</option>
                      <option value="Tomate">Tomate</option>
                      <option value="Caña de azúcar">Caña</option>
                      <option value="Girasol">Girasol</option>
                    </select>
                  </div>
                </div>
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-3.5 rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 flex items-center justify-center gap-2 mt-6"
            >
              {loading ? (
                <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
              ) : (
                isLogin ? 'Ingresar a SembrIA' : 'Completar Registro'
              )}
            </button>
          </form>

          {/* Toggle Login/Register */}
          <div className="mt-8 text-center text-sm text-gray-500">
            {isLogin ? (
              <span>¿No tienes una cuenta aún?{' '}
                <button 
                  onClick={() => setIsLogin(false)} 
                  className="text-primary hover:text-primary-dark font-semibold outline-none hover:underline"
                >
                  Registrate aquí
                </button>
              </span>
            ) : (
              <span>¿Ya tienes una cuenta?{' '}
                <button 
                  onClick={() => setIsLogin(true)} 
                  className="text-primary hover:text-primary-dark font-semibold outline-none hover:underline"
                >
                  Inicia sesión aquí
                </button>
              </span>
            )}
          </div>

        </div>
      </div>
    </div>
  );
}
