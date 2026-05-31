-- Datos de ejemplo para marketplace P2P (ejecutar después de seed.sql)
-- Requiere usuarios ya insertados en tabla usuarios

INSERT INTO publicaciones_p2p (usuario_id, titulo, descripcion, precio_bob, es_gratis, categoria, zona_santa_cruz, whatsapp_numero, estado, vistas) VALUES
('a3c18b76-4d22-4467-bc5b-ee4f7c17d7b0', 'Soya cosechada 15 qq', 'Soya limpia recién cosechada en Okinawa, humedad 13%. Entrega en parcela.', 2850.00, false, 'Cosecha', 'Norte Integrado', '59171234567', 'Activo', 12),
('d9f41e09-7a55-7790-ef8e-bb7fa04af0e3', 'Semilla maíz NK 900 sobrante', 'Medio saco de semilla híbrida NK 900, buen germinador. Comprada en El Tejar.', 420.00, false, 'Semillas', 'Sur', '59179876543', 'Activo', 8),
('c7e30d98-6f44-6689-de7d-aa6f9e39f9d2', 'Pulverizadora de mochila 20L', 'Pulverizadora usada 1 temporada, sin fugas. Ideal para parcelas medianas.', 350.00, false, 'Herramientas', 'Este', '59176543210', 'Activo', 24),
('b5d29c87-5e33-5578-cd6c-ff5f8d28e8c1', 'Tomate perita Vallegrande', '2 quintales tomate perita fresco, cosecha de ayer. Precio negociable.', 180.00, false, 'Cosecha', 'Valles', '59172345678', 'Activo', 5),
('e1a52f10-8b66-8801-fa9f-cc8fa15bf1f4', 'Rastrojo de caña gratis', 'Rastrojo de caña para ganado o compost. Retiro en parcela Warnes.', NULL, true, 'Otros', 'Norte Integrado', '59173456789', 'Activo', 31),
('a3c18b76-4d22-4467-bc5b-ee4f7c17d7b0', 'Servicio fumigación con dron', 'Fumigación aérea soya y maíz. Zona Norte Integrado y Este.', 45.00, false, 'Servicios', 'Norte Integrado', '59171234567', 'Activo', 18);
