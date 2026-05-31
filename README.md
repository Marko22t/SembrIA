# 🌱 SembrIA — Diagnóstico Agrícola con IA para Bolivia

> Plataforma de inteligencia artificial para agricultores del departamento de Santa Cruz, Bolivia. Diagnostica enfermedades de cultivos por texto o foto, conecta a productores en un marketplace P2P y muestra alertas fitosanitarias en tiempo real.

---

## ✨ Funcionalidades principales

- **Diagnóstico por IA** — Describe los síntomas de tu cultivo o sube una foto y recibe un diagnóstico detallado con nivel de urgencia, tratamiento y productos recomendados (con precios en Bolivianos).
- **Diagnóstico por imagen (Claude Vision)** — Análisis visual de hojas, tallos y frutos con identificación de signos visibles y diagnóstico diferencial.
- **Mapa de plagas** — Visualización geográfica de diagnósticos anónimos en todo Santa Cruz para detectar focos de infección.
- **Marketplace de agroinsumos** — Catálogo de productos con filtros por categoría, zona y precio.
- **Marketplace P2P** — Agricultores compran y venden productos entre sí con integración directa a WhatsApp.
- **Clima en tiempo real** — Widget meteorológico de Santa Cruz de la Sierra.
- **Historial de diagnósticos** — Registro completo de consultas previas por usuario.
- **Planes gratuito / Pro / Empresa** — Sistema de suscripciones con límite de 10 diagnósticos/mes en el plan gratuito.
- **Motor de respaldo offline** — Si la API de Claude no está disponible, un motor agronómico local responde con diagnósticos de alta fidelidad para soya, maíz y tomate.

---

## 🛠 Stack tecnológico

| Capa | Tecnología |
|---|---|
| Frontend | React 18 + Vite + Tailwind CSS + Framer Motion |
| Backend | Node.js + Express |
| Base de datos | Supabase (PostgreSQL) |
| IA | Anthropic Claude API (claude-3 — texto y visión) |
| Mapa | Leaflet.js |
| Autenticación | JWT + bcryptjs |
| Storage | Supabase Storage (imágenes de diagnósticos) |

---

## 📁 Estructura del proyecto

```
SembrIA/
├── frontend/
│   ├── src/
│   │   ├── components/       # ChatBot, AuthModal, WeatherWidget, PaymentModal…
│   │   ├── pages/            # Home, Diagnosis, History, Marketplace, PlagueMap, Plans
│   │   ├── utils/            # whatsapp.js, planUtils.js, diagnosticoStorage.js
│   │   └── lib/              # supabase.js (cliente)
│   └── package.json
├── backend/
│   ├── src/
│   │   ├── controllers/      # auth, diagnose, chat, marketplace, p2p, map, dashboard…
│   │   ├── middlewares/      # authMiddleware.js, checkPlanLimit.js
│   │   ├── services/         # planService.js, ventasService.js
│   │   └── server.js
│   ├── migrations/           # Scripts SQL de migración
│   └── package.json
└── README.md
```

---

## 🚀 Instalación y uso local

### Requisitos previos
- Node.js 18+
- Cuenta en [Supabase](https://supabase.com)
- API Key de [Anthropic](https://console.anthropic.com)

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/SembrIA.git
cd SembrIA
```

### 2. Configurar el backend

```bash
cd backend
npm install
```

Crea un archivo `.env` en la carpeta `backend/` con las siguientes variables:

```env
PORT=5000
NODE_ENV=development

# Anthropic
ANTHROPIC_API_KEY=sk-ant-...

# Supabase
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJ...
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# JWT
JWT_SECRET=tu_secreto_seguro
```

Inicializa la base de datos ejecutando los scripts en orden:

```bash
# En el SQL Editor de Supabase
# 1. schema.sql
# 2. migrations/001_subscriptions_and_map.sql
# 3. migrations/002_conversation_and_sales.sql
# 4. ... (el resto en orden numérico)
```

Inicia el servidor:

```bash
npm run dev        # desarrollo (con hot reload)
npm start          # producción
```

### 3. Configurar el frontend

```bash
cd ../frontend
npm install
```

Crea un archivo `.env` en la carpeta `frontend/`:

```env
VITE_SUPABASE_URL=https://xxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_API_URL=http://localhost:5000
```

Inicia el servidor de desarrollo:

```bash
npm run dev
```

Abre [http://localhost:5173](http://localhost:5173) en tu navegador.

---

## 🌿 Variables de entorno — referencia completa

| Variable | Dónde | Descripción |
|---|---|---|
| `ANTHROPIC_API_KEY` | backend | Clave de la API de Claude |
| `SUPABASE_URL` | backend y frontend | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | backend y frontend | Clave pública de Supabase |
| `SUPABASE_SERVICE_ROLE_KEY` | backend | Clave de servicio (solo backend) |
| `JWT_SECRET` | backend | Secreto para firmar tokens |
| `PORT` | backend | Puerto del servidor (default: 5000) |
| `VITE_API_URL` | frontend | URL base del backend |

---

## 🔌 Endpoints principales de la API

```
POST   /api/auth/register              Registro de usuario
POST   /api/auth/login                 Login

POST   /api/diagnose/text              Diagnóstico por síntomas (texto)
POST   /api/diagnose/image             Diagnóstico por foto (base64)
GET    /api/diagnose/history/:userId   Historial del usuario

GET    /api/map/diagnosticos           Puntos del mapa de plagas
GET    /api/weather/santa-cruz         Clima actual

GET    /api/products                   Catálogo de agroinsumos
POST   /api/orders                     Crear pedido

GET    /api/p2p                        Publicaciones P2P activas
POST   /api/p2p                        Crear publicación

GET    /api/subscription/status        Estado del plan del usuario
POST   /api/subscription/change        Cambiar de plan
```

---

## 📋 Planes de suscripción

| Plan | Diagnósticos/mes | Historial | Precio |
|---|---|---|---|
| Gratuito | 10 | Últimos 10 | Gratis |
| Pro | Ilimitados | Completo | — |
| Empresa | Ilimitados | Completo + dashboard | — |

---

## 🤝 Contribuir

1. Haz un fork del repositorio
2. Crea una rama: `git checkout -b feature/mi-mejora`
3. Haz commit de tus cambios: `git commit -m "feat: descripción"`
4. Push a la rama: `git push origin feature/mi-mejora`
5. Abre un Pull Request

---

## 📄 Licencia

MIT © CropDoctor Team — Hackathon Build With AI 2025, Bolivia
