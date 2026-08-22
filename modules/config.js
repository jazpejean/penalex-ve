import dotenv from 'dotenv';
import { createClient } from '@supabase/supabase-js';
import AWS from 'aws-sdk';
import { init } from '@heyputer/puter.js/src/init.cjs';
import ws from 'ws';

dotenv.config();

// ---- Puter: inicialización correcta ----
const puterToken = process.env.PUTER_API_KEY || process.env.PUTER_AUTH_TOKEN;
if (!puterToken) {
  console.error('❌ No se encontró PUTER_API_KEY en .env');
  process.exit(1);
}
export const puterClient = init(puterToken);  // <--- Usamos init()

// ---- Supabase con WebSocket ----
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  realtime: { transport: ws }
});

// ---- Cloudflare R2 ----
const r2Config = {
  endpoint: `https://${process.env.R2_ACCOUNT_ID}.r2.cloudflarestorage.com`,
  accessKeyId: process.env.R2_ACCESS_KEY_ID,
  secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  region: 'auto',
  s3ForcePathStyle: true,
  signatureVersion: 'v4'
};
export const r2 = new AWS.S3(r2Config);
export const R2_BUCKET = process.env.R2_BUCKET_NAME;
export const PROJECT_DIR = process.cwd();
