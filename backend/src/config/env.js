import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Cargar .env desde la raíz del monorepo (Hackaton/.env)
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

export const CLAUDE_MODEL =
  process.env.CLAUDE_MODEL || 'claude-sonnet-4-20250514';
