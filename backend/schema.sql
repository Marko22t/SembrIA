-- Esquema de tablas para Supabase (PostgreSQL)
-- Ejecutar en SQL Editor de Supabase antes de seed.sql
-- Hackathon Build With AI 2026 · CropDoctor Agro

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    zona_santa_cruz VARCHAR(100) NOT NULL,
    cultivo_principal VARCHAR(100) NOT NULL,
    plan VARCHAR(20) DEFAULT 'gratis',
    diagnosticos_hoy INTEGER DEFAULT 0,
    fecha_reset_contador DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS diagnosticos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    imagen_url TEXT,
    descripcion_texto TEXT,
    resultado_json JSONB NOT NULL,
    cultivo VARCHAR(100) NOT NULL,
    zona VARCHAR(100) NOT NULL,
    lat NUMERIC(9, 6),
    lon NUMERIC(9, 6),
    conversation JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS productos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    precio_bob NUMERIC(10, 2) NOT NULL,
    categoria VARCHAR(50) NOT NULL,
    imagen_url TEXT,
    vendedor VARCHAR(150) NOT NULL,
    stock INTEGER DEFAULT 0,
    zona_disponible VARCHAR(150) DEFAULT 'Santa Cruz - General',
    usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    producto_id BIGINT REFERENCES productos(id) ON DELETE CASCADE,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    estado VARCHAR(50) DEFAULT 'Pendiente',
    vendedor_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Marketplace P2P entre agricultores
CREATE TABLE IF NOT EXISTS publicaciones_p2p (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    precio_bob NUMERIC(10, 2),
    es_gratis BOOLEAN DEFAULT false,
    categoria VARCHAR(80) NOT NULL,
    zona_santa_cruz VARCHAR(100) NOT NULL,
    imagen_url TEXT,
    whatsapp_numero VARCHAR(20) NOT NULL,
    estado VARCHAR(30) DEFAULT 'Activo',
    vistas INTEGER DEFAULT 0,
    fecha_venta TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_p2p_categoria ON publicaciones_p2p(categoria);
CREATE INDEX IF NOT EXISTS idx_p2p_zona ON publicaciones_p2p(zona_santa_cruz);
CREATE INDEX IF NOT EXISTS idx_p2p_estado ON publicaciones_p2p(estado);

-- Storage: crear bucket público "diagnosticos" en Supabase Dashboard > Storage
