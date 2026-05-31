import { createClient } from '@supabase/supabase-js';
import '../config/env.js';

const BUCKET = process.env.SUPABASE_STORAGE_BUCKET || 'diagnosticos';

/**
 * Sube una imagen en base64 al bucket de Supabase Storage.
 * @param {string} subfolder - Carpeta dentro del bucket (ej. diagnosticos, p2p)
 */
export async function uploadImageToStorage(
  base64Data,
  mediaType = 'image/jpeg',
  subfolder = 'diagnosticos'
) {
  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (
    !supabaseUrl ||
    !serviceKey ||
    serviceKey.startsWith('tu-service-role-key')
  ) {
    return null;
  }

  const supabaseAdmin = createClient(supabaseUrl, serviceKey);
  const ext = mediaType.includes('png') ? 'png' : mediaType.includes('webp') ? 'webp' : 'jpg';
  const fileName = `${subfolder}/img_${Date.now()}.${ext}`;
  const buffer = Buffer.from(base64Data, 'base64');

  const { data, error } = await supabaseAdmin.storage
    .from(BUCKET)
    .upload(fileName, buffer, {
      contentType: mediaType,
      upsert: false
    });

  if (error) {
    console.error('Error al subir imagen a Supabase Storage:', error.message);
    return null;
  }

  const { data: publicUrl } = supabaseAdmin.storage
    .from(BUCKET)
    .getPublicUrl(data.path);

  return publicUrl?.publicUrl || null;
}

export async function uploadDiagnosisImage(base64Data, mediaType = 'image/jpeg') {
  return uploadImageToStorage(base64Data, mediaType, 'diagnosticos');
}

export async function uploadP2pImage(base64Data, mediaType = 'image/jpeg') {
  return uploadImageToStorage(base64Data, mediaType, 'p2p');
}
