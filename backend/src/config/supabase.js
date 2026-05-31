import { createClient } from '@supabase/supabase-js';
import '../config/env.js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

const isConfigured =
  supabaseUrl &&
  supabaseAnonKey &&
  !supabaseUrl.includes('tu-proyecto') &&
  !supabaseAnonKey.startsWith('tu-anon-key');

if (!isConfigured) {
  console.warn(
    '⚠️ Supabase no configurado. Auth, marketplace e historial requieren .env con credenciales reales.'
  );
}

// Cliente dummy evita crash al arrancar sin .env; las queries fallarán hasta configurar Supabase
export const supabase = createClient(
  supabaseUrl || 'https://placeholder.supabase.co',
  supabaseAnonKey || 'placeholder-anon-key'
);

export const supabaseReady = isConfigured;
