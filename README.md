# 🌿 SembrIA Agro — Hackathon Build With AI 2026

[![React](https://img.shields.io/badge/React-18-61DAFB?style=flat-square&logo=react)](https://react.dev/)
[![Node](https://img.shields.io/badge/Node.js-Express-339933?style=flat-square&logo=node.js)](https://nodejs.org/)
[![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3FCF8E?style=flat-square&logo=supabase)](https://supabase.com/)
[![Claude](https://img.shields.io/badge/Claude-Anthropic-D97757?style=flat-square)](https://www.anthropic.com/)
[![Santa Cruz](https://img.shields.io/badge/Enfoque-Santa%20Cruz%2C%20Bolivia-14532d?style=flat-square)](#)

> **Mención AGRO** · Diagnóstico fitosanitario con IA + marketplace de agroinsumos para agricultores de **Santa Cruz de la Sierra**.

---

## 📺 Video de Presentación

Puedes ver el video de presentación del proyecto haciendo clic en el siguiente enlace:
👉 [Ver video de presentación en YouTube](https://youtu.be/0KsaTHf7_Hw)

## El problema en Santa Cruz

Santa Cruz concentra ~**70%** de la producción agrícola nacional. Pequeños y medianos productores del Norte Integrado, Sur y Este pierden **20–40%** de cosechas por plagas detectadas tarde (roya asiática en soya, cogollero en maíz, trips, mosca blanca). No hay agrónomos suficientes en campo; cuando llegan, el daño ya está hecho.

**CropDoctor** convierte el celular en primera línea de diagnóstico: foto o texto → IA especializada en cultivos cruceños → productos en BOB en el marketplace → alertas climáticas locales.

---

## Estructura del monorepo

```
Hackaton/
├── backend/           # API Express (puerto 5000)
│   ├── schema.sql     # Tablas Supabase
│   ├── seed.sql       # 20 productos, 5 usuarios, 8 diagnósticos demo
│   └── src/
├── frontend/          # React + Vite + Tailwind (puerto 3000)
├── .env.example
├── DOCUMENTO_TECNICO.md
└── README.md
```

---

## Instalación en 5 pasos

### 1. Clonar e instalar dependencias

```bash
git clone https://github.com/TU-USUARIO/cropdoctor-agro.git
cd cropdoctor-agro
npm run install:all
```

### 2. Variables de entorno

```bash
cp .env.example .env
```

Edita `.env` en la **raíz** con tus credenciales de [Supabase](https://supabase.com) y [Anthropic](https://console.anthropic.com).

### 3. Base de datos Supabase

1. Crea un proyecto en Supabase.
2. En **SQL Editor**, ejecuta `backend/schema.sql`, luego `backend/seed.sql` y `backend/p2p-seed.sql` (marketplace entre agricultores).
3. En **Storage**, crea un bucket público llamado `diagnosticos` (las fotos P2P se guardan en la carpeta `p2p/` dentro del mismo bucket).
4. Copia URL, anon key y service role key al `.env`.

### 4. Iniciar backend

```bash
npm run dev:backend
```

Verifica: http://localhost:5000 → JSON de estado.

### 5. Iniciar frontend

```bash
npm run dev:frontend
```

Abre: http://localhost:3000 (el proxy de Vite redirige `/api` al backend).

**Usuarios de prueba (contraseña `123456`):**

| Email | Zona |
|-------|------|
| juan.mamani@agro.bo | Norte Integrado |
| severina.choque@agro.bo | Valles |

---

## Variables de entorno

| Variable | Descripción |
|----------|-------------|
| `PORT` | Puerto del API (default 5000) |
| `SUPABASE_URL` | URL del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Clave pública anon |
| `SUPABASE_SERVICE_ROLE_KEY` | Subida de fotos a Storage |
| `SUPABASE_STORAGE_BUCKET` | Nombre del bucket (default `diagnosticos`) |
| `ANTHROPIC_API_KEY` | Claude API (texto + visión) |
| `CLAUDE_MODEL` | Modelo (default `claude-sonnet-4-20250514`) |
| `JWT_SECRET` | Firma de tokens de sesión |

Sin `ANTHROPIC_API_KEY`, el backend usa un **motor agronómico de respaldo** con casos reales de Santa Cruz (útil para demo offline).

---

## API — Endpoints principales

### Autenticación

```http
POST /api/auth/register
POST /api/auth/login
```

### Diagnóstico IA

```http
POST /api/diagnose/text
Content-Type: application/json

{
  "descripcion": "Hojas de soya con manchas amarillas y pústulas en el envés",
  "cultivo": "Soya",
  "zona_santa_cruz": "Norte Integrado",
  "usuario_id": "uuid-opcional"
}
```

```http
POST /api/diagnose/image
{
  "imagen_base64": "data:image/jpeg;base64,...",
  "cultivo": "Soya",
  "zona_santa_cruz": "Este",
  "descripcion_opcional": "Desde hace 3 días"
}
```

```http
GET /api/diagnose/history/:userId
Authorization: Bearer <token>
```

### Marketplace P2P (entre agricultores + WhatsApp)

```http
GET /api/p2p?categoria=Cosecha&q=soya
POST /api/p2p              # JWT — publicar producto
PUT /api/p2p/:id/vista       # contador de vistas
DELETE /api/p2p/:id          # JWT — marcar vendido
```

### Marketplace oficial (B2C)

```http
GET /api/products?categoria=Fungicidas&zona=Norte Integrado&precio_max=300
GET /api/products/:id
POST /api/orders          # JWT requerido
```

### Clima Santa Cruz

```http
GET /api/weather/santa-cruz
```

Respuesta incluye temperatura, humedad, precipitación, viento y `recomendacion_agronomica`.

---

## Arquitectura (ASCII)

```
[Agricultor móvil]
       │
       ▼
[React + Vite :3000] ──proxy──► [Express API :5000]
       │                              │
       │                    ┌─────────┼─────────┐
       │                    ▼         ▼         ▼
       │              [Supabase]  [Claude API] [Open-Meteo]
       │              PostgreSQL  texto/visión  clima SC
       │              + Storage
       └──────────────────────────────────────────────
```

---

## Lean Canvas (resumen)

| Bloque | Contenido |
|--------|-----------|
| Problema | Pérdidas 20–40% por plagas tardías en Santa Cruz |
| Solución | Diagnóstico IA + marketplace + clima local |
| Segmento | PyMEs agrícolas Norte/Sur/Este cruceño |
| Propuesta única | Contexto Santa Cruz + compra directa en BOB |
| Canales | PWA móvil, cooperativas, agroveterinarias |
| Ingresos | Freemium $5/mes, comisión 8% marketplace, SaaS B2B $100/mes |
| Costos | API Claude, hosting Vercel/Railway, Supabase free tier |

---

## Integrantes

_Agrega aquí los nombres de los 3 integrantes del equipo._

---

## Roadmap post-hackathon

1. **Fase 1:** Validación con 50 productores en Norte Integrado + alianza con 2 agroveterinarias.
2. **Fase 2:** App nativa offline-first + integración pagos (QR Bolivia).
3. **Fase 3:** Panel B2B para ANAPO / El Tejar + modelo predictivo de plagas por zona.

---

## Documentación adicional

- `DOCUMENTO_TECNICO.md` — FODA, PESTEL, financiero, impacto (entregable jueces).
- Pitch: ver sección Paso 10 del prompt maestro del proyecto.

**Hackathon Build With AI 2026 · GDG & WTM Santa Cruz · UCB**
