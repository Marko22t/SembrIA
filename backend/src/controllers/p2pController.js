import { supabase } from '../config/supabase.js';
import { uploadP2pImage } from '../utils/storage.js';
import { obtenerVentasDelVendedor } from '../services/ventasService.js';

/** Extrae base64 puro y media type de data URL o cadena cruda */
function parseBase64Image(imagen_base64) {
  if (!imagen_base64) return null;
  if (imagen_base64.includes(';base64,')) {
    const parts = imagen_base64.split(';base64,');
    return {
      data: parts[1],
      mediaType: parts[0].replace('data:', '') || 'image/jpeg'
    };
  }
  return { data: imagen_base64, mediaType: 'image/jpeg' };
}

/** Normaliza número WhatsApp a formato internacional (Bolivia 591) */
export function limpiarNumeroWhatsApp(numero) {
  if (!numero) return '';
  let n = numero.replace(/[\s\-().+]/g, '');
  if (n.startsWith('0')) n = '591' + n.slice(1);
  if (!n.startsWith('591') && n.length <= 8) n = '591' + n;
  return n;
}

// GET /api/p2p — Listar publicaciones activas
export const getPublicaciones = async (req, res) => {
  try {
    const { categoria, zona, precio_max, q, limit } = req.query;
    const maxItems = Math.min(parseInt(limit, 10) || 50, 100);

    let query = supabase
      .from('publicaciones_p2p')
      .select('*, usuarios(nombre, zona_santa_cruz)')
      .eq('estado', 'Activo')
      .order('created_at', { ascending: false })
      .limit(maxItems);

    if (categoria && categoria !== 'Todos') query = query.eq('categoria', categoria);
    if (zona) query = query.eq('zona_santa_cruz', zona);
    if (precio_max) query = query.lte('precio_bob', parseFloat(precio_max));
    if (q) query = query.ilike('titulo', `%${q}%`);

    const { data, error } = await query;
    if (error) throw error;
    return res.status(200).json(data || []);
  } catch (err) {
    console.error('Error getPublicaciones:', err.message);
    return res.status(200).json([]);
  }
};

// POST /api/p2p — Crear publicación (JWT)
export const crearPublicacion = async (req, res) => {
  try {
    const {
      titulo,
      descripcion,
      precio_bob,
      es_gratis,
      categoria,
      zona_santa_cruz,
      imagen_url,
      imagen_base64,
      whatsapp_numero
    } = req.body;
    const usuario_id = req.user.id;

    if (!titulo || !descripcion || !categoria || !zona_santa_cruz || !whatsapp_numero) {
      return res.status(400).json({ error: 'Faltan campos obligatorios.' });
    }

    const whatsappLimpio = limpiarNumeroWhatsApp(whatsapp_numero);

    let imagenFinal = imagen_url || null;
    if (imagen_base64) {
      const parsed = parseBase64Image(imagen_base64);
      if (parsed) {
        const urlSubida = await uploadP2pImage(parsed.data, parsed.mediaType);
        if (urlSubida) {
          imagenFinal = urlSubida;
        } else if (!imagen_url) {
          console.warn(
            '⚠️ No se pudo subir la foto P2P (revisa SUPABASE_SERVICE_ROLE_KEY y bucket público).'
          );
        }
      }
    }

    const { data, error } = await supabase
      .from('publicaciones_p2p')
      .insert([
        {
          titulo,
          descripcion,
          precio_bob: es_gratis ? null : parseFloat(precio_bob) || 0,
          es_gratis: Boolean(es_gratis),
          categoria,
          zona_santa_cruz,
          imagen_url: imagenFinal,
          whatsapp_numero: whatsappLimpio,
          usuario_id
        }
      ])
      .select('*, usuarios(nombre, zona_santa_cruz)')
      .single();

    if (error) throw error;

    const respuesta = { ...data };
    if (imagen_base64 && !imagenFinal) {
      respuesta.aviso_imagen =
        'Publicación guardada, pero la foto no se subió. Verifica SUPABASE_SERVICE_ROLE_KEY y que el bucket sea público.';
    }

    return res.status(201).json(respuesta);
  } catch (err) {
    console.error('Error crearPublicacion:', err);
    return res.status(500).json({ error: 'Error al crear la publicación.' });
  }
};

// PUT /api/p2p/:id/vista — Incrementar vistas
export const incrementarVista = async (req, res) => {
  try {
    const { id } = req.params;
    const { data } = await supabase
      .from('publicaciones_p2p')
      .select('vistas')
      .eq('id', id)
      .maybeSingle();

    if (data) {
      await supabase
        .from('publicaciones_p2p')
        .update({ vistas: (data.vistas || 0) + 1 })
        .eq('id', id);
    }
    return res.status(200).json({ ok: true });
  } catch {
    return res.status(200).json({ ok: true });
  }
};

// GET /api/p2p/mis-ventas — Pedidos de productos del vendedor (marketplace B2C)
export const getMisVentas = async (req, res) => {
  try {
    const { ventas } = await obtenerVentasDelVendedor(req.user.id);
    return res.status(200).json(ventas);
  } catch (err) {
    console.error('Error getMisVentas:', err.message);
    return res.status(200).json([]);
  }
};

// DELETE /api/p2p/:id — Marcar como vendido
export const marcarVendido = async (req, res) => {
  try {
    const { id } = req.params;
    const usuario_id = req.user.id;

    const { error } = await supabase
      .from('publicaciones_p2p')
      .update({ estado: 'Vendido' })
      .eq('id', id)
      .eq('usuario_id', usuario_id);

    if (error) throw error;
    return res.status(200).json({ message: 'Publicación marcada como vendida.' });
  } catch (err) {
    console.error('Error marcarVendido:', err);
    return res.status(500).json({ error: 'Error al actualizar.' });
  }
};
