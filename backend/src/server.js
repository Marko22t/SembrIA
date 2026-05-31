import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import './config/env.js';

// Importar Controladores
import { register, login } from './controllers/authController.js';
import {
  diagnoseText,
  diagnoseImage,
  getHistory,
  saveDiagnosticoRecord
} from './controllers/diagnoseController.js';
import { chatMessage } from './controllers/chatController.js';
import { getProducts, getProductById, addProduct, createOrder, getOrdersByUser } from './controllers/marketplaceController.js';
import { getSantaCruzWeather } from './controllers/weatherController.js';
import {
  getPublicaciones,
  crearPublicacion,
  incrementarVista,
  marcarVendido,
  getMisVentas
} from './controllers/p2pController.js';
import {
  getSubscriptionStatus,
  getStatus,
  upgradeSubscription,
  changePlan
} from './controllers/subscriptionController.js';
import { getMapaDiagnosticos } from './controllers/mapController.js';
import { getDashboardStats } from './controllers/dashboardController.js';
import { checkPlanLimit } from './middlewares/checkPlanLimit.js';

// Importar Middlewares de Seguridad
import { protect } from './middlewares/authMiddleware.js';

const app = express();
const PORT = process.env.PORT || 5000;

// MIDDLEWARES GENERALES
app.use(helmet());
app.use(cors({
  origin: '*', // Permitir peticiones desde cualquier origen para pruebas de la hackathon
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json({ limit: '10mb' })); // Aumentar límite para soportar subidas de fotos en base64
app.use(morgan('dev'));

// Requests largos (diagnóstico por imagen + Claude Vision)
app.use((req, res, next) => {
  res.setTimeout(120000);
  next();
});

// --- RUTAS DE LA API CROPDOCTOR ---

// 1. Autenticación (Paso 2)
app.post('/api/auth/register', register);
app.post('/api/auth/login', login);

// 2. Diagnóstico por IA - Claude API (Paso 3)
app.post('/api/diagnose/text', checkPlanLimit, diagnoseText);
app.post('/api/diagnose/image', checkPlanLimit, diagnoseImage);
app.get('/api/diagnose/history/:userId', protect, getHistory);
app.post('/api/diagnose/record', protect, saveDiagnosticoRecord);
app.get('/api/dashboard/stats', protect, getDashboardStats);
app.post('/api/chat', chatMessage);

// 2b. Suscripciones
app.get('/api/subscription/status', protect, getStatus);
app.post('/api/subscription/change', protect, changePlan);
app.post('/api/subscription/upgrade', protect, upgradeSubscription);

// 2c. Mapa de plagas
app.get('/api/map/diagnosticos', getMapaDiagnosticos);

// 3. Marketplace de Agroinsumos (Paso 4)
app.get('/api/products', getProducts);
app.get('/api/products/:id', getProductById);
app.post('/api/products', protect, addProduct); // Solo vendedores autenticados
app.post('/api/orders', protect, createOrder);  // Registrar compra con microcrédito
app.get('/api/orders/user/:userId', protect, getOrdersByUser); // Historial de compras

// 4. Clima y Asesoría Fitosanitaria de Santa Cruz (Paso 5)
app.get('/api/weather/santa-cruz', getSantaCruzWeather);

// 5. Marketplace P2P entre agricultores
app.get('/api/p2p', getPublicaciones);
app.post('/api/p2p', protect, crearPublicacion);
app.put('/api/p2p/:id/vista', incrementarVista);
app.delete('/api/p2p/:id', protect, marcarVendido);
app.get('/api/p2p/mis-ventas', protect, getMisVentas);

// Ruta de Check de Salud básica
app.get('/', (req, res) => {
  res.status(200).json({
    name: 'SembrIA API',
    version: '1.0.0',
    status: 'Servidor Express Activo 🌿',
    location: 'Santa Cruz, Bolivia'
  });
});

// Manejo de errores globales
app.use((err, req, res, next) => {
  console.error('Error no controlado en la aplicación:', err);
  res.status(500).json({ error: 'Ocurrió un error inesperado en el servidor.' });
});

// INICIAR SERVIDOR
app.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(` 🌿 SERVIDOR CROPDOCTOR AGRO INICIADO EN PUERTO: ${PORT}`);
  console.log(` 🚀 Entorno: ${process.env.NODE_ENV || 'development'}`);
  console.log(` 📍 Región Foco: Santa Cruz de la Sierra, Bolivia`);
  console.log(`=======================================================`);
});
