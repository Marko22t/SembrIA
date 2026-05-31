-- =======================================================
-- ESQUEMA DDL Y DATOS SEMILLA PARA CROPDOCTOR AGRO
-- Hackathon Build With AI 2026 · Santa Cruz, Bolivia
-- =======================================================

-- Habilitar extensión pgcrypto para generación de UUIDs si no está habilitada
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Eliminar tablas existentes para asegurar una reinstalación limpia si fuera necesario
DROP TABLE IF EXISTS pedidos CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS diagnosticos CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;

-- 1. TABLA DE USUARIOS (PRODUCTORES AGRÍCOLAS)
CREATE TABLE usuarios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre VARCHAR(150) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    zona_santa_cruz VARCHAR(100) NOT NULL, -- Norte Integrado, Sur, Este, Chiquitanía, Valles, Ciudad
    cultivo_principal VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. TABLA DE DIAGNÓSTICOS DE CULTIVOS (PROCESADOS POR CLAUDE)
CREATE TABLE diagnosticos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
    imagen_url TEXT,
    descripcion_texto TEXT,
    resultado_json JSONB NOT NULL,
    cultivo VARCHAR(100) NOT NULL,
    zona VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. TABLA DE PRODUCTOS DEL MARKETPLACE (AGROINSUMOS REALES EN BOLIVIA)
CREATE TABLE productos (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT NOT NULL,
    precio_bob NUMERIC(10, 2) NOT NULL,
    categoria VARCHAR(50) NOT NULL, -- Fungicidas, Fertilizantes, Herramientas, Semillas
    imagen_url TEXT,
    vendedor VARCHAR(150) NOT NULL,
    stock INTEGER DEFAULT 0,
    zona_disponible VARCHAR(150) DEFAULT 'Santa Cruz - General'
);

-- 4. TABLA DE PEDIDOS (MICROCRÉDITOS Y COMPRAS)
CREATE TABLE pedidos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
    producto_id BIGINT REFERENCES productos(id) ON DELETE CASCADE,
    cantidad INTEGER NOT NULL CHECK (cantidad > 0),
    estado VARCHAR(50) DEFAULT 'Pendiente', -- Pendiente, Aprobado, Enviado, Completado
    precio_unitario NUMERIC(10, 2),
    nombre_producto VARCHAR(200),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =======================================================
-- DATOS SEMILLA (SEED DATA) ESPECÍFICOS DE SANTA CRUZ
-- =======================================================

-- 5 PRODUCTORES AGRÍCOLAS DE PRUEBA EN DIFERENTES REGIONES
-- Contraseñas encriptadas (password es '123456')
INSERT INTO usuarios (id, nombre, email, password_hash, zona_santa_cruz, cultivo_principal) VALUES
('a3c18b76-4d22-4467-bc5b-ee4f7c17d7b0', 'Juan Mamani', 'juan.mamani@agro.bo', '$2a$10$P46JqlUAAjKclOlmaWzKHuYlbjxjfooL09J7zLOaSR3llda.sr0nK', 'Norte Integrado', 'Soya'),
('b5d29c87-5e33-5578-cd6c-ff5f8d28e8c1', 'Severina Choque', 'severina.choque@agro.bo', '$2a$10$P46JqlUAAjKclOlmaWzKHuYlbjxjfooL09J7zLOaSR3llda.sr0nK', 'Valles', 'Tomate'),
('c7e30d98-6f44-6689-de7d-aa6f9e39f9d2', 'Carlos Justiniano', 'carlos.justiniano@agro.bo', '$2a$10$P46JqlUAAjKclOlmaWzKHuYlbjxjfooL09J7zLOaSR3llda.sr0nK', 'Este', 'Girasol'),
('d9f41e09-7a55-7790-ef8e-bb7fa04af0e3', 'Mateo Pinto', 'mateo.pinto@agro.bo', '$2a$10$P46JqlUAAjKclOlmaWzKHuYlbjxjfooL09J7zLOaSR3llda.sr0nK', 'Chiquitanía', 'Maíz'),
('e1a52f10-8b66-8801-fa9f-cc8fa15bf1f4', 'Rolando Vaca', 'rolando.vaca@agro.bo', '$2a$10$P46JqlUAAjKclOlmaWzKHuYlbjxjfooL09J7zLOaSR3llda.sr0nK', 'Sur', 'Caña de azúcar');

-- 20 PRODUCTOS DE MARCAS LÍDERES DISPONIBLES EN AGROVETERINARIAS CRUCEÑAS
INSERT INTO productos (nombre, descripcion, precio_bob, categoria, imagen_url, vendedor, stock, zona_disponible) VALUES
-- Fungicidas
('Fungicida Priori Xtra (Syngenta) - 1L', 'Fungicida sistémico preventivo y curativo, especial para el control de Roya Asiática en cultivos de Soya.', 280.00, 'Fungicidas', 'priori_xtra.png', 'AgroVeterinaria Montero', 150, 'Norte Integrado'),
('Fungicida Opera (BASF) - 5L', 'Excelente fungicida a base de piraclostrobina y epoxiconazol. Gran persistencia para controlar manchas foliares y roya.', 980.00, 'Fungicidas', 'opera_basf.png', 'Importadora El Tejar', 60, 'Santa Cruz - General'),
('Fungicida Mancozeb WG AgroFit - 1kg', 'Fungicida protector de contacto de amplio espectro, ideal para evitar resistencias en tomate y papa.', 125.00, 'Fungicidas', 'mancozeb.png', 'Distribuidora Oriental', 300, 'Santa Cruz - General'),
('Fungicida Amistar Top (Syngenta) - 1L', 'Fungicida de amplio espectro con acción sistémica y translaminar para control de antracnosis y mildiu.', 340.00, 'Fungicidas', 'amistar_top.png', 'AgroVeterinaria Montero', 80, 'Norte Integrado'),
('Fungicida Ridomil Gold (Syngenta) - 2.5kg', 'Especialista en el control de oomicetos como el Tizón Tardío (Phytophthora infestans) en papa y hortalizas.', 210.00, 'Fungicidas', 'ridomil.png', 'AgroVeterinaria Okinawa', 120, 'Valles'),

-- Fertilizantes
('Fertilizante NPK 15-15-15 (Yara) - 50kg', 'Fertilizante compuesto balanceado con nitrógeno, fósforo y potasio para arranque de campaña agrícola.', 320.00, 'Fertilizantes', 'npk_15.png', 'Yara Bolivia S.A.', 500, 'Santa Cruz - General'),
('Urea Granulada 46% (YPFB) - 50kg', 'Nitrógeno de alta concentración producido localmente en Bolivia para rápido desarrollo foliar y vigor.', 180.00, 'Fertilizantes', 'urea.png', 'YPFB Refinación', 1000, 'Santa Cruz - General'),
('Triple 16 BioSuelo - 50kg', 'Fertilizante mineral óptimo para suelos desgastados en las zonas Este y Norte integrado.', 340.00, 'Fertilizantes', 'triple_16.png', 'Importadora El Tejar', 200, 'Este'),
('Sulfato de Amonio Soluble - 25kg', 'Aporte inmediato de nitrógeno y azufre, ideal para corregir suelos alcalinos en cultivos de oleaginosas.', 150.00, 'Fertilizantes', 'sulfato_amonio.png', 'Distribuidora Oriental', 180, 'Sur'),
('Fosfato Diamónico (DAP) - 50kg', 'Excelente fuente de fósforo y nitrógeno para un fuerte enraizamiento y floración de maíz y girasol.', 380.00, 'Fertilizantes', 'dap.png', 'AgroVeterinaria Montero', 250, 'Norte Integrado'),
('Bioestimulante Radicular AlgaMax - 1L', 'Fórmula biológica a base de algas marinas que estimula el desarrollo del sistema radicular en condiciones de sequía.', 180.00, 'Fertilizantes', 'algamax.png', 'BioAgro Santa Cruz', 90, 'Santa Cruz - General'),

-- Herbicidas / Pesticidas
('Herbicida Roundup ControlMax (Monsanto) - 10kg', 'Glifosato granulado soluble de alta eficiencia para barbecho químico rápido en soya y caña.', 480.00, 'Herramientas', 'roundup.png', 'Importadora El Tejar', 400, 'Santa Cruz - General'),
('Herbicida Gramoxone (Syngenta) - 5L', 'Herbicida desecante de contacto para control post-emergente de malezas de hoja ancha y gramíneas.', 350.00, 'Herramientas', 'gramoxone.png', 'AgroVeterinaria Montero', 150, 'Norte Integrado'),
('Insecticida Lorsban 4E (Dow) - 1L', 'Insecticida organofosforado de amplio espectro, letal contra el gusano cogollero en el maíz.', 140.00, 'Herramientas', 'lorsban.png', 'AgroVeterinaria Okinawa', 100, 'Sur'),
('Insecticida Karate con Tecnología Zeon - 1L', 'Piretroide encapsulado de alta persistencia contra trips, pulgones y orugas cortadoras.', 175.00, 'Herramientas', 'karate.png', 'Distribuidora Oriental', 220, 'Santa Cruz - General'),
('Insecticida Cipermex 25 EC - 1L', 'Cipermetrina pura para control de volteo rápido de plagas masticadoras y picadoras.', 95.00, 'Herramientas', 'cipermex.png', 'BioAgro Santa Cruz', 300, 'Chiquitanía'),

-- Semillas
('Semillas Soya Don Mario DM 6.8i - Bolsa 40kg', 'Semilla de soya certificada de excelente vigor y alto rendimiento, tolerante a sequía.', 290.00, 'Semillas', 'semilla_soya.png', 'ANAPO Semillas', 800, 'Este'),
('Semillas Maíz Híbrido Dekalb DK 79-10 - Bolsa 60k', 'Híbrido de maíz amarillo de alto rendimiento, resistente al cogollero bajo tecnología VT Triple PRO.', 950.00, 'Semillas', 'dekalb_maiz.png', 'Semillería Warnes', 120, 'Norte Integrado'),
('Semillas Girasol Syn 3970 CL - Bolsa 10kg', 'Semilla de girasol híbrida Clearfield de ciclo medio y alta concentración de aceite.', 840.00, 'Semillas', 'girasol_sem.png', 'Semillería Warnes', 90, 'Este'),
('Kit Medidor pH y Humedad Digital 3 en 1', 'Herramienta de campo digital para medir humedad de suelo, pH y luz solar directa en parcelas.', 95.00, 'Herramientas', 'ph_meter.png', 'Distribuidora Oriental', 150, 'Santa Cruz - General');

-- 8 DIAGNÓSTICOS HISTÓRICOS DE EJEMPLO
INSERT INTO diagnosticos (usuario_id, cultivo, zona, imagen_url, descripcion_texto, resultado_json) VALUES
-- 1. Roya en Soya (Norte Integrado)
('a3c18b76-4d22-4467-bc5b-ee4f7c17d7b0', 'Soya', 'Norte Integrado', 'roya_soya.jpg', 'Hojas con puntos marrones y amarillamiento acelerado en el tercio inferior del cultivo de soya.',
'{
  "problema": "Roya Asiática de la Soya (Phakopsora pachyrhizi)",
  "causa": "Hongo altamente destructivo favorecido por periodos de rocío foliar prolongado y temperaturas de 18-26°C comunes en el Norte Integrado.",
  "severidad": 4,
  "urgencia": "ALTA",
  "tratamiento": [
    "Pulverizar inmediatamente con una mezcla de triazoles y estrobirulinas.",
    "Monitorear las parcelas vecinas para verificar focos de infección.",
    "Respetar la pausa ecológica obligatoria de la soya en el departamento."
  ],
  "productos_recomendados": [
    {"nombre": "Fungicida Priori Xtra (Syngenta)", "dosis": "300 ml/ha", "precio_estimado_bob": 280.00},
    {"nombre": "Fungicida Opera (BASF)", "dosis": "500 ml/ha", "precio_estimado_bob": 980.00}
  ],
  "prevencion": "Sembrar en las fechas recomendadas por ANAPO y calibrar la pulverizadora para lograr una buena cobertura en el tercio medio e inferior.",
  "confianza": "ALTA",
  "zona_riesgo": "Región Norte Integrado y Este de Santa Cruz.",
  "cuando_actuar": "Antes de que la severidad supere el 5% de área foliar afectada."
}'),

-- 2. Cogollero en Maíz (Sur)
('e1a52f10-8b66-8801-fa9f-cc8fa15bf1f4', 'Maíz', 'Sur', 'cogollero_maiz.jpg', 'El cogollo de mis plantas de maíz muestra perforaciones y restos de aserrín.',
'{
  "problema": "Gusano Cogollero (Spodoptera frugiperda)",
  "causa": "Larva de polilla que se alimenta del tejido tierno dentro del cogollo, común en campañas secas en el Sur de Santa Cruz.",
  "severidad": 3,
  "urgencia": "MEDIA",
  "tratamiento": [
    "Efectuar aplicaciones focalizadas al cogollo temprano por la mañana o al atardecer.",
    "Implementar trampas de feromonas para captura de adultos nocturnos.",
    "Utilizar insecticidas reguladores de crecimiento (IGRs) si las larvas son pequeñas."
  ],
  "productos_recomendados": [
    {"nombre": "Insecticida Lorsban 4E", "dosis": "800 ml/ha", "precio_estimado_bob": 140.00}
  ],
  "prevencion": "Rotación de cultivos y uso de semillas híbridas con eventos Bt aprobados en Bolivia.",
  "confianza": "ALTA",
  "zona_riesgo": "Municipio de Cabezas y Cordillera.",
  "cuando_actuar": "Al detectar más del 10% de plantas con grado 2 en la escala de Davis."
}'),

-- 3. Trips en Soya (Este)
('c7e30d98-6f44-6689-de7d-aa6f9e39f9d2', 'Soya', 'Este', 'trips_soya.jpg', 'Las hojas de soya en el envés se ven plateadas y algo deformes, hay insectos pequeñitos negros.',
'{
  "problema": "Trips (Frankliniella schultzei)",
  "causa": "Insecto picador-chupador que prospera en climas extremadamente secos y calurosos de la zona Este (Pailón, Tres Cruces).",
  "severidad": 3,
  "urgencia": "MEDIA",
  "tratamiento": [
    "Aplicar insecticida de contacto sistémico con buena presión de agua para penetrar el dosel del cultivo.",
    "Evitar pulverizar al mediodía para prevenir evaporación del producto."
  ],
  "productos_recomendados": [
    {"nombre": "Insecticida Karate con Tecnología Zeon", "dosis": "150 ml/ha", "precio_estimado_bob": 175.00}
  ],
  "prevencion": "Mantener el suelo con cobertura de rastrojo para conservar humedad y retardar la reproducción de trips.",
  "confianza": "ALTA",
  "zona_riesgo": "Región de Pailón y Cuatro Cañadas.",
  "cuando_actuar": "Al observar un promedio de 5 a 10 trips por folíolo."
}'),

-- 4. Mosca Blanca en Tomate (Valles)
('b5d29c87-5e33-5578-cd6c-ff5f8d28e8c1', 'Tomate', 'Valles', 'mosca_blanca.jpg', 'Nubes de mosquitas blancas vuelan al sacudir las plantas de tomate en Samaipata.',
'{
  "problema": "Mosca Blanca (Bemisia tabaci)",
  "causa": "Plaga chupadora que succiona savia y transmite virus en hortalizas. Muy activa en los valles cruceños.",
  "severidad": 4,
  "urgencia": "ALTA",
  "tratamiento": [
    "Instalar trampas cromáticas amarillas con pegamento alrededor de la parcela.",
    "Aplicar insecticidas sistémicos específicos rotando familias químicas para evitar resistencia."
  ],
  "productos_recomendados": [
    {"nombre": "Insecticida Karate con Tecnología Zeon", "dosis": "200 ml/ha", "precio_estimado_bob": 175.00}
  ],
  "prevencion": "Eliminar malezas hospederas alrededor de las parcelas de tomate antes del trasplante.",
  "confianza": "ALTA",
  "zona_riesgo": "Vallegrande, Samaipata y Mairana.",
  "cuando_actuar": "De inmediato al detectar los primeros adultos para evitar la transmisión de geminivirus."
}'),

-- 5. Antracnosis en Soya (Norte Integrado)
('a3c18b76-4d22-4467-bc5b-ee4f7c17d7b0', 'Soya', 'Norte Integrado', NULL, 'Manchas negras en las vainas de la soya, algunas vainas están vacías y marchitas.',
'{
  "problema": "Antracnosis (Colletotrichum dematium)",
  "causa": "Hongo favorecido por altas temperaturas y lluvias frecuentes durante el llenado de grano en el Norte Integrado.",
  "severidad": 4,
  "urgencia": "ALTA",
  "tratamiento": [
    "Aplicar fungicida sistémico de amplio espectro protector.",
    "Cosechar a tiempo para evitar mayor pudrición de vainas si el ataque es avanzado."
  ],
  "productos_recomendados": [
    {"nombre": "Fungicida Amistar Top (Syngenta)", "dosis": "350 ml/ha", "precio_estimado_bob": 340.00}
  ],
  "prevencion": "Utilizar semilla certificada y tratada profesionalmente con fungicidas curasemillas.",
  "confianza": "MEDIA",
  "zona_riesgo": "Warnes, Montero y Mineros.",
  "cuando_actuar": "Inicio de floración y llenado de vainas."
}'),

-- 6. Deficiencia de Nitrógeno en Papa (Valles)
('b5d29c87-5e33-5578-cd6c-ff5f8d28e8c1', 'Papa', 'Valles', NULL, 'Hojas viejas amarillentas de manera uniforme en la parcela de papa.',
'{
  "problema": "Deficiencia de Nitrógeno (Trastorno Nutricional)",
  "causa": "Lavado de nutrientes en suelos inclinados de los valles debido a lluvias recientes.",
  "severidad": 2,
  "urgencia": "BAJA",
  "tratamiento": [
    "Realizar una fertilización foliar correctora o una aplicación directa al suelo en el aporque."
  ],
  "productos_recomendados": [
    {"nombre": "Urea Granulada 46% (YPFB)", "dosis": "100 kg/ha", "precio_estimado_bob": 180.00}
  ],
  "prevencion": "Incorporar materia orgánica al suelo y fraccionar la fertilización nitrogenada en dos etapas.",
  "confianza": "ALTA",
  "zona_riesgo": "Toda la zona productora de papa en los valles.",
  "cuando_actuar": "Dentro de las 2 semanas de notar los síntomas."
}'),

-- 7. Barrenador de la Caña (Norte Integrado)
('e1a52f10-8b66-8801-fa9f-cc8fa15bf1f4', 'Caña de azúcar', 'Norte Integrado', NULL, 'Tallos de caña de azúcar quebrados, con agujeros y galerías internas al cortarlos.',
'{
  "problema": "Barrenador de la Caña (Diatraea saccharalis)",
  "causa": "Larva de polilla que perfora los tallos de la caña, favoreciendo la entrada de hongos como el carbón o la podredumbre roja en Warnes/Montero.",
  "severidad": 3,
  "urgencia": "MEDIA",
  "tratamiento": [
    "Liberar avispas parasitoides (Cotesia flavipes) para control biológico eficiente.",
    "Monitorear las larvas en los entrenudos jóvenes."
  ],
  "productos_recomendados": [
    {"nombre": "Insecticida Karate con Tecnología Zeon", "dosis": "250 ml/ha", "precio_estimado_bob": 175.00}
  ],
  "prevencion": "Utilizar variedades de caña con mayor dureza de corteza y eliminar rastrojos del ciclo anterior.",
  "confianza": "ALTA",
  "zona_riesgo": "Zonas cañeras de Warnes, Montero y Mineros.",
  "cuando_actuar": "Al detectar más del 3% de entrenudos infestados."
}'),

-- 8. Carbón de la Caña (Norte Integrado)
('e1a52f10-8b66-8801-fa9f-cc8fa15bf1f4', 'Caña de azúcar', 'Norte Integrado', NULL, 'Estructuras negras con forma de látigo saliendo del cogollo de la caña de azúcar.',
'{
  "problema": "Carbón de la Caña de Azúcar (Sporisorium scitamineum)",
  "causa": "Enfermedad fúngica sistémica muy perjudicial favorecida por altas temperaturas y humedad en parcelas cañeras de Montero.",
  "severidad": 5,
  "urgencia": "CRÍTICA",
  "tratamiento": [
    "Arrancar y quemar de inmediato las plantas enfermas completas colocándolas en sacos para evitar dispersión de esporas.",
    "Eliminar la cepa completa si el rebrote muestra látigos del carbón."
  ],
  "productos_recomendados": [],
  "prevencion": "Sembrar únicamente yemas sanas provenientes de semilleros certificados y desinfectar el machete de corte.",
  "confianza": "ALTA",
  "zona_riesgo": "Norte Integrado cañero.",
  "cuando_actuar": "De forma INMEDIATA al ver el primer látigo negro."
}');
