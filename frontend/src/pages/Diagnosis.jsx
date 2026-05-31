import React, { useState, useRef } from 'react';
import axios from 'axios';
import { Upload, FileText, Camera, AlertTriangle, CheckCircle, ArrowRight, Trash2, HelpCircle } from 'lucide-react';
import {
  guardarDiagnosticoEnSupabase,
  buildTextoUsuario,
  buildRespuestaDesdeResultado
} from '../utils/diagnosticoStorage.js';
import UsageBar from '../components/UsageBar.jsx';
import { isFreePlan } from '../utils/planUtils.js';

const DEMO_RESULT = {
  problema: 'Roya Asiática de la Soya',
  causa:
    'Hongo Phakopsora pachyrhizi favorecido por humedad alta y temperaturas entre 15-28°C en el Norte integrado de Santa Cruz',
  severidad: 4,
  urgencia: 'ALTA',
  nivel_urgencia: 'ALTA',
  tratamiento: [
    'Aplicar fungicida triazol+estrobilurina (Opera o Priori Xtra) inmediatamente',
    'Usar dosis de 0.5L por hectárea con mochila o fumigadora',
    'Repetir aplicación a los 14 días si persisten los síntomas',
    'No aplicar con viento fuerte para evitar deriva'
  ],
  productos_recomendados: [
    { nombre: 'Opera (BASF)', dosis: '0.5L/ha', precio_estimado_bob: 280 },
    { nombre: 'Priori Xtra (Syngenta)', dosis: '0.3L/ha', precio_estimado_bob: 320 }
  ],
  prevencion:
    'Monitorear semanalmente desde floración. En Santa Cruz la roya es más agresiva entre enero y abril.',
  confianza: 'ALTA',
  certeza: 'ALTA',
  zona_riesgo: 'Norte integrado y Sur integrado',
  cuando_actuar: 'En las próximas 24-48 horas',
  _demo: true
};

const DEMO_IMAGE =
  'https://images.unsplash.com/photo-1625246333195-78d9c38ad449?w=800&q=80';

const DIAGNOSE_AXIOS_TIMEOUT_MS = 120000;

function isDemoMode(usuario) {
  if (typeof window !== 'undefined') {
    const params = new URLSearchParams(window.location.search);
    if (params.get('demo') === 'true') return true;
  }
  return usuario?.email === 'demo@cropdoctor.bo';
}

export default function Diagnosis({
  usuario,
  onRecommendRedirect,
  token,
  onLimitReached,
  onDiagnosisDone,
  subStatus,
  onUpgrade
}) {
  const [cultivo, setCultivo] = useState('Soya');
  const [zona, setZona] = useState('Norte Integrado');
  const [activeTab, setActiveTab] = useState('text'); // 'text' | 'image'
  const [descripcion, setDescripcion] = useState('');
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState('');
  const [loading, setLoading] = useState(false);
  const [statusText, setStatusText] = useState('');
  const [resultado, setResultado] = useState(null);
  const [diagnosticoMeta, setDiagnosticoMeta] = useState(null);
  const [conversacion, setConversacion] = useState([]);
  const [error, setError] = useState('');
  const [saveError, setSaveError] = useState(false);

  const fileInputRef = useRef(null);

  // Drag and Drop State
  const [dragActive, setDragActive] = useState(false);

  const handleDrag = (e) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") {
      setDragActive(true);
    } else if (e.type === "dragleave") {
      setDragActive(false);
    }
  };

  const handleDrop = (e) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (e.dataTransfer.files && e.dataTransfer.files[0]) {
      const file = e.dataTransfer.files[0];
      handleFile(file);
    }
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      handleFile(e.target.files[0]);
    }
  };

  const handleFile = (file) => {
    if (!file.type.startsWith('image/')) {
      setError('Por favor selecciona un archivo de imagen válido (JPG, PNG).');
      return;
    }
    setImageFile(file);
    setError('');

    const reader = new FileReader();
    reader.onload = (e) => {
      setImagePreview(e.target.result);
    };
    reader.readAsDataURL(file);
  };

  const removeImage = () => {
    setImageFile(null);
    setImagePreview('');
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const handleTriggerFile = () => {
    fileInputRef.current.click();
  };

  // Ejecutar el diagnóstico fitopatológico
  const handleAnalyze = async () => {
    setLoading(true);
    setError('');
    setResultado(null);
    setDiagnosticoMeta(null);
    setConversacion([]);
    setSaveError(false);

    const logs = [
      "Analizando tu cultivo...",
      "Consultando base de datos de plagas cruceñas...",
      "Generando recomendaciones para Santa Cruz...",
      "Preparando receta de tratamiento en BOB..."
    ];

    let logIndex = 0;
    setStatusText(logs[0]);

    const logInterval = setInterval(() => {
      logIndex++;
      if (logIndex < logs.length) {
        setStatusText(logs[logIndex]);
      } else {
        clearInterval(logInterval);
      }
    }, 600);

    try {
      let response;
      const headers = token ? { Authorization: `Bearer ${token}` } : {};
      const axiosConfig = { headers, timeout: DIAGNOSE_AXIOS_TIMEOUT_MS };
      const esImagen = activeTab === 'image';
      const persistirCliente = Boolean(usuario?.id);

      if (activeTab === 'text') {
        if (!descripcion.trim()) {
          setError('Por favor describe los síntomas del cultivo.');
          setLoading(false);
          clearInterval(logInterval);
          return;
        }

        response = await axios.post(
          '/api/diagnose/text',
          {
            descripcion,
            cultivo,
            zona_santa_cruz: zona,
            usuario_id: usuario?.id || null,
            skip_persist: persistirCliente
          },
          axiosConfig
        );
      } else {
        if (!imagePreview) {
          setError('Por favor selecciona o arrastra una imagen de tu cultivo.');
          setLoading(false);
          clearInterval(logInterval);
          return;
        }

        response = await axios.post(
          '/api/diagnose/image',
          {
            imagen_base64: imagePreview,
            descripcion_opcional: descripcion,
            cultivo,
            zona_santa_cruz: zona,
            usuario_id: usuario?.id || null,
            skip_persist: persistirCliente
          },
          axiosConfig
        );
      }

      const {
        diagnostico_id: _idPrevio,
        numero_diagnostico: _numPrevio,
        diagnosticos_mes: _mesPrevio,
        diagnosticos_hoy: _hoyPrevio,
        respuesta_ia,
        imagen_url,
        ...rest
      } = response.data;

      const textoUsuario = buildTextoUsuario({
        cultivo,
        zona,
        descripcion,
        esImagen
      });
      const ultimaRespuestaIA = respuesta_ia || buildRespuestaDesdeResultado(rest);
      const primerMensajeDelUsuario = esImagen
        ? descripcion.trim() || 'Análisis de imagen del cultivo'
        : descripcion.trim();

      const conversacionCompleta = [
        { role: 'user', content: textoUsuario, hasImage: esImagen },
        { role: 'assistant', content: ultimaRespuestaIA }
      ];
      setConversacion(conversacionCompleta);
      setResultado(rest);

      if (usuario?.id) {
        try {
          const meta = await guardarDiagnosticoEnSupabase({
            usuarioId: usuario.id,
            imagenUrl: imagen_url || (esImagen ? imagePreview : null),
            descripcionTexto: primerMensajeDelUsuario,
            conversacion: conversacionCompleta,
            respuestaIa: ultimaRespuestaIA,
            tieneImagen: esImagen,
            resultadoJson: rest,
            cultivo,
            zona,
            token
          });
          setDiagnosticoMeta({
            diagnostico_id: meta.diagnostico_id,
            numero_diagnostico: meta.numero_diagnostico,
            diagnosticos_mes: meta.diagnosticos_mes ?? meta.diagnosticos_hoy
          });
          window.dispatchEvent(new CustomEvent('stats-actualizar'));
        } catch (saveErr) {
          console.error('Error guardando diagnóstico:', saveErr);
          setSaveError(true);
        }
      }

      onDiagnosisDone?.();
    } catch (err) {
      console.error(err);
      const limitError =
        err.response?.status === 403 ||
        err.response?.data?.error === 'Límite del plan gratuito alcanzado' ||
        err.response?.data?.error === 'límite_diario';

      if (limitError) {
        onLimitReached?.();
        setError(err.response.data.mensaje);
      } else {
        setError(
          err.response?.data?.mensaje ||
          err.response?.data?.error ||
          'No se pudo realizar el diagnóstico. Intenta nuevamente.'
        );
      }
    } finally {
      clearInterval(logInterval);
      setLoading(false);
    }
  };

  const runDemoFlow = async () => {
    setLoading(true);
    setError('');
    setResultado(null);
    setCultivo('Soya');
    setZona('Norte Integrado');
    setActiveTab('image');
    setImagePreview(DEMO_IMAGE);
    setDescripcion('Manchas marrones en hojas de soya — demo Demo Day');

    const logs = [
      'Analizando tu cultivo...',
      'Consultando plagas cruceñas...',
      'Generando recomendaciones...'
    ];
    for (let i = 0; i < logs.length; i++) {
      setStatusText(logs[i]);
      await new Promise((r) => setTimeout(r, 700));
    }

    const demoUser = buildTextoUsuario({
      cultivo: 'Soya',
      zona: 'Norte Integrado',
      descripcion: 'Manchas marrones en hojas de soya — demo Demo Day',
      esImagen: true
    });
    const demoResp = buildRespuestaDesdeResultado(DEMO_RESULT);
    setConversacion([
      { role: 'user', content: demoUser, hasImage: true },
      { role: 'assistant', content: demoResp }
    ]);
    setResultado({ ...DEMO_RESULT });
    setDiagnosticoMeta({ numero_diagnostico: 'demo', diagnostico_id: 'demo' });
    setLoading(false);
  };

  const showDemo = isDemoMode(usuario);

  return (
    <div className="max-w-4xl mx-auto px-4 py-12 pb-24">

      {subStatus && isFreePlan(subStatus.plan) && !subStatus?.ilimitado && (
        <UsageBar
          usados={subStatus.diagnosticos_mes ?? subStatus.diagnosticos_hoy}
          limite={subStatus.limite_gratis || 10}
          onUpgrade={onUpgrade}
        />
      )}

      {showDemo && (
        <button
          type="button"
          onClick={runDemoFlow}
          disabled={loading}
          className="fixed bottom-24 right-6 z-50 bg-red-600 hover:bg-red-700 text-white font-bold px-4 py-3 rounded-full shadow-xl text-sm"
        >
          ▶ Ver Demo
        </button>
      )}

      <div className="text-center max-w-2xl mx-auto mb-12">
        <h2 className="text-3xl font-extrabold text-primary-dark tracking-tight">
          Diagnostica tu cultivo
        </h2>
        <p className="text-gray-500 mt-2">
          Sube una foto o describe los síntomas foliares. Nuestra Inteligencia Artificial procesará la información al instante.
        </p>
      </div>

      <div className="bg-white border border-gray-100 rounded-3xl p-6 sm:p-10 shadow-md">

        {/* Selector de Cultivo y Zona */}
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-6 mb-8">
          <div className="space-y-1.5">
            <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Cultivo Principal</label>
            <select
              value={cultivo}
              onChange={(e) => setCultivo(e.target.value)}
              className="w-full bg-gray-50 border border-gray-200 text-gray-800 rounded-xl px-4 py-3 outline-none text-sm focus:border-primary focus:bg-white focus:ring-4 focus:ring-green-50 transition-all font-semibold"
            >
              <option value="Soya">Soya</option>
              <option value="Caña de azúcar">Caña de azúcar</option>
              <option value="Maíz">Maíz</option>
              <option value="Arroz">Arroz</option>
              <option value="Girasol">Girasol</option>
              <option value="Sorgo">Sorgo</option>
              <option value="Otro">Otro</option>
            </select>
          </div>

          <div className="space-y-1.5">
            <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Zona de Santa Cruz</label>
            <select
              value={zona}
              onChange={(e) => setZona(e.target.value)}
              className="w-full bg-gray-50 border border-gray-200 text-gray-800 rounded-xl px-4 py-3 outline-none text-sm focus:border-primary focus:bg-white focus:ring-4 focus:ring-green-50 transition-all font-semibold"
            >
              <option value="Norte Integrado">Norte integrado</option>
              <option value="Sur">Sur integrado</option>
              <option value="Este">Este</option>
              <option value="Chiquitanía">Chiquitanía</option>
              <option value="Valles">Valles</option>
              <option value="Ciudad">Ciudad (área periurbana)</option>
            </select>
          </div>
        </div>

        {/* Tab triggers */}
        <div className="flex border-b border-gray-100 mb-8">
          <button
            onClick={() => { setActiveTab('text'); setError(''); }}
            className={`flex items-center gap-2.5 pb-4 px-6 font-bold text-sm outline-none border-b-2 transition-all ${activeTab === 'text'
              ? 'border-primary text-primary'
              : 'border-transparent text-gray-400 hover:text-gray-600'
              }`}
          >
            <FileText className="w-4 h-4" /> Describir síntomas
          </button>
          <button
            onClick={() => { setActiveTab('image'); setError(''); }}
            className={`flex items-center gap-2.5 pb-4 px-6 font-bold text-sm outline-none border-b-2 transition-all ${activeTab === 'image'
              ? 'border-primary text-primary'
              : 'border-transparent text-gray-400 hover:text-gray-600'
              }`}
          >
            <Camera className="w-4 h-4" /> Subir foto de muestra
          </button>
        </div>

        {/* Form Inputs according to Active Tab */}
        <div className="space-y-6">
          {error && (
            <div className="bg-red-50 text-red-600 border border-red-100 rounded-xl p-3 text-sm font-semibold text-center">
              {error}
            </div>
          )}

          {activeTab === 'text' ? (
            <div className="space-y-2">
              <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Detalles físicos</label>
              <textarea
                value={descripcion}
                onChange={(e) => setDescripcion(e.target.value)}
                placeholder="Ej. Las hojas de mi cultivo de soya en Okinawa muestran pequeños puntos amarillentos en el envés. El problema avanza de abajo hacia arriba y las hojas del tercio inferior están comenzando a caerse..."
                rows={5}
                className="w-full bg-gray-50 border border-gray-200 rounded-2xl p-4 outline-none text-sm focus:bg-white focus:border-primary focus:ring-4 focus:ring-green-50 transition-all leading-relaxed"
              />
            </div>
          ) : (
            <div className="space-y-4">
              <input
                type="file"
                ref={fileInputRef}
                onChange={handleFileChange}
                accept="image/*"
                id="hiddenFileInput"
              />

              {/* Drag and drop zone */}
              {!imagePreview ? (
                <div
                  onDragEnter={handleDrag}
                  onDragOver={handleDrag}
                  onDragLeave={handleDrag}
                  onDrop={handleDrop}
                  onClick={handleTriggerFile}
                  className={`border-2 border-dashed rounded-2xl py-12 px-6 text-center cursor-pointer transition-all duration-300 flex flex-col items-center justify-center gap-4 ${dragActive
                    ? 'border-primary bg-green-50'
                    : 'border-gray-200 hover:border-primary hover:bg-green-50 bg-gray-50 bg-opacity-50'
                    }`}
                >
                  <div className="w-16 h-16 bg-white shadow-sm rounded-full flex items-center justify-center text-primary">
                    <Upload className="w-6 h-6" />
                  </div>
                  <div>
                    <h4 className="font-bold text-gray-900">Arrastra la foto aquí</h4>
                    <p className="text-xs text-gray-500 mt-1">Foto clara del envés y haz de la hoja, con buena luz</p>
                  </div>
                  <button className="bg-primary hover:bg-primary-dark text-white font-bold px-5 py-2.5 rounded-xl text-xs shadow hover:shadow-md transition-all">
                    Seleccionar Foto
                  </button>
                </div>
              ) : (
                <div className="flex flex-col items-center justify-center p-4 border border-gray-100 rounded-2xl bg-gray-50">
                  <div className="relative rounded-xl overflow-hidden border border-white shadow-md max-w-sm w-full">
                    <img
                      src={imagePreview}
                      alt="Previsualización del cultivo"
                      className="w-full h-56 object-cover block"
                    />
                    <button
                      onClick={removeImage}
                      className="absolute top-3 right-3 bg-black bg-opacity-65 text-white hover:bg-accent-red p-2 rounded-full transition-all"
                      title="Eliminar imagen"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  <p className="text-xs text-gray-500 font-semibold mt-3">Imagen seleccionada para análisis de visión</p>
                </div>
              )}

              {/* Optional description during Vision analysis */}
              <div className="space-y-1.5 pt-2">
                <label className="text-xs font-bold text-gray-700 uppercase tracking-wider block">Comentario Adicional (Opcional)</label>
                <input
                  type="text"
                  value={descripcion}
                  onChange={(e) => setDescripcion(e.target.value)}
                  placeholder="Ej. ¿Es roya o otra mancha? Hojas con puntos marrones en el envés desde hace 3 días."
                  className="w-full bg-gray-50 border border-gray-200 rounded-xl px-4 py-3 outline-none text-sm focus:bg-white focus:border-primary transition-all"
                />
              </div>
            </div>
          )}

          {/* Action button */}
          {!loading && (
            <button
              onClick={handleAnalyze}
              className="w-full bg-primary hover:bg-primary-dark text-white font-bold py-4 rounded-2xl shadow-lg hover:shadow-xl transition-all duration-300 flex items-center justify-center gap-2.5 text-base"
            >
              <Camera className="w-5 h-5" /> Analizar con IA
            </button>
          )}

          {/* Loading pipeline animation */}
          {loading && (
            <div className="border border-green-100 rounded-2xl p-6 bg-green-50 bg-opacity-30 flex flex-col items-center justify-center gap-4 text-center animate-pulse">
              <div className="w-10 h-10 border-4 border-green-200 border-t-primary rounded-full animate-spin"></div>
              <div>
                <h5 className="font-bold text-primary-dark text-sm">Consultando al Servidor de Diagnóstico</h5>
                <p className="text-xs text-gray-500 mt-1 font-semibold">{statusText}</p>
              </div>
            </div>
          )}
        </div>

        {/* --- 4. RESULT SHEET DIALOG --- */}
        {resultado && (() => {
          const urgencia = resultado.urgencia || resultado.nivel_urgencia || 'MEDIA';
          const causaTexto = resultado.causa || resultado.descripcion_visual || '';
          const tratamientos = resultado.tratamiento || [];
          return (
            <div className="mt-12 border border-green-200 rounded-3xl bg-green-50 bg-opacity-20 p-6 sm:p-8 animate-in slide-in-from-bottom-8 duration-500 relative">
              {resultado._demo && (
                <span className="absolute top-4 right-4 bg-red-600 text-white text-[10px] font-black px-2 py-1 rounded uppercase tracking-wider">
                  Demo
                </span>
              )}

              <div className="flex flex-col sm:flex-row justify-between items-start gap-4 border-b border-green-100 pb-6 mb-6">
                <div>
                  {diagnosticoMeta?.numero_diagnostico && (
                    <p className="text-xs font-bold text-primary uppercase tracking-wider mb-1">
                      Diagnóstico #{diagnosticoMeta.numero_diagnostico}
                      {diagnosticoMeta.diagnosticos_mes != null &&
                        ` · ${diagnosticoMeta.diagnosticos_mes} este mes`}
                    </p>
                  )}
                  <h3 className="text-2xl font-black text-primary-dark">{resultado.problema}</h3>
                  {causaTexto && <p className="text-sm text-gray-500 font-medium italic mt-1">{causaTexto}</p>}
                  {resultado.certeza && (
                    <p className="text-xs text-gray-400 mt-2 font-semibold">Certeza del diagnóstico: {resultado.certeza || resultado.confianza}</p>
                  )}
                  {saveError && (
                    <p className="text-xs text-orange-500 mt-2">
                      ⚠️ No se pudo guardar en historial, pero aquí está tu diagnóstico.
                    </p>
                  )}
                </div>
                <span className={`badge border font-black text-xs px-3.5 py-1.5 rounded-full ${urgencia === 'BAJA'
                  ? 'bg-green-100 text-green-700 border-green-200'
                  : urgencia === 'MEDIA'
                    ? 'bg-amber-100 text-amber-700 border-amber-200'
                    : 'bg-red-100 text-accent-red border-red-200'
                  }`}>
                  Severidad {resultado.severidad || '?'}/5 • Urgencia {urgencia}
                </span>
              </div>

              {/* Signos y diagnóstico diferencial */}
              <div className="space-y-6">
                {resultado.signos_observados?.length > 0 && (
                  <div className="bg-white border border-gray-100 rounded-xl p-4 space-y-2">
                    <h4 className="font-bold text-gray-900 text-sm">Signos observados en la muestra</h4>
                    <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                      {resultado.signos_observados.map((s, i) => (
                        <li key={i}>{s}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {resultado.diagnostico_diferencial?.length > 0 && (
                  <div className="bg-blue-50 border border-blue-100 rounded-xl p-4 space-y-3">
                    <h4 className="font-bold text-blue-900 text-sm">Otras posibilidades (diagnóstico diferencial)</h4>
                    {resultado.diagnostico_diferencial.map((d, i) => (
                      <div key={i} className="text-sm border-b border-blue-100 last:border-0 pb-2 last:pb-0">
                        <span className="font-bold text-blue-800">{d.enfermedad}</span>
                        <span className="text-xs uppercase font-black text-blue-600 ml-2">
                          {d.probabilidad}
                        </span>
                        <p className="text-gray-600 mt-0.5 text-xs">{d.por_que}</p>
                      </div>
                    ))}
                  </div>
                )}

                {(resultado.advertencia_confirmacion || (resultado.certeza && resultado.certeza !== 'ALTA')) && (
                  <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 text-sm text-amber-900">
                    <strong>Importante:</strong>{' '}
                    {resultado.advertencia_confirmacion ||
                      'Certeza no alta — confirma con un agrónomo antes de comprar tratamientos costosos.'}
                  </div>
                )}

                <div className="space-y-3">
                  <h4 className="font-bold text-gray-900 flex items-center gap-2.5">
                    <CheckCircle className="w-5 h-5 text-primary" /> Receta de Tratamiento Agrónomo
                  </h4>
                  <ol className="space-y-3">
                    {tratamientos.map((step, idx) => (
                      <li key={idx} className="bg-white border border-gray-100 p-4 rounded-xl flex gap-3 text-sm shadow-sm">
                        <span className="w-6 h-6 rounded-full bg-green-50 border border-green-200 text-primary font-extrabold flex items-center justify-center flex-shrink-0 text-xs">
                          {idx + 1}
                        </span>
                        <span className="text-gray-700 leading-relaxed font-medium">{step}</span>
                      </li>
                    ))}
                  </ol>
                </div>

                {(resultado.zona_riesgo || resultado.alerta_climatica) && (
                  <div className="bg-amber-50 border border-amber-200 text-amber-900 rounded-xl p-4 text-sm flex gap-3 font-semibold items-start">
                    <AlertTriangle className="w-5 h-5 text-accent-amber flex-shrink-0 mt-0.5" />
                    <span>
                      {resultado.alerta_climatica ? (
                        <><strong>Alerta climática:</strong> {resultado.alerta_climatica}</>
                      ) : (
                        <><strong>Zona de riesgo:</strong> {resultado.zona_riesgo}. Actuar: {resultado.cuando_actuar || 'lo antes posible'}.</>
                      )}
                    </span>
                  </div>
                )}

                {resultado.medidas_preventivas?.length > 0 && (
                  <div className="space-y-2">
                    <h4 className="font-bold text-gray-900 text-sm">Prevención</h4>
                    <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                      {resultado.medidas_preventivas.map((m, i) => (
                        <li key={i}>{m}</li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* Recommended Products Grid */}
                {resultado.productos_recomendados && resultado.productos_recomendados.length > 0 && (
                  <div className="space-y-4">
                    <h4 className="font-bold text-gray-900 flex items-center gap-2">
                      <HelpCircle className="w-5 h-5 text-primary" /> Agroinsumos Sugeridos para la Compra
                    </h4>
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      {resultado.productos_recomendados.map((prod, idx) => (
                        <div key={idx} className="bg-white border border-gray-100 p-5 rounded-2xl flex flex-col justify-between gap-4 shadow-sm hover:shadow transition-all">
                          <div>
                            <span className="text-[10px] font-bold text-gray-400 uppercase tracking-widest block">Insumo Recomendado</span>
                            <h5 className="font-bold text-gray-900 mt-1">{prod.nombre}</h5>
                            <p className="text-xs text-gray-500 mt-1 font-semibold">Dosis: {prod.dosis}</p>
                          </div>
                          <div className="flex items-center justify-between border-t border-gray-50 pt-3">
                            <span className="text-sm font-black text-primary-dark">{prod.precio_estimado_bob} BOB</span>
                            <button
                              onClick={() => onRecommendRedirect('Fungicidas')}
                              className="text-xs text-primary hover:text-primary-dark font-bold flex items-center gap-1 hover:underline outline-none"
                            >
                              Comprar en Marketplace <ArrowRight className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Save Diagnostics warning */}
                {!usuario && (
                  <div className="text-center bg-gray-50 rounded-xl p-4 border border-gray-100 text-xs text-gray-500 font-semibold">
                    💡 Inicia sesión para guardar este diagnóstico en tu historial y habilitar tu evaluación crediticia.
                  </div>
                )}
              </div>

            </div>
          );
        })()}

      </div>

    </div>
  );
}
