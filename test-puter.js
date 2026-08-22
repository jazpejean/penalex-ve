import dotenv from 'dotenv';
import { init } from '@heyputer/puter.js/src/init.cjs';

dotenv.config();

const token = process.env.PUTER_API_KEY || process.env.PUTER_AUTH_TOKEN;
console.log('Token (primeros 20 caracteres):', token?.slice(0, 20) + '...');

if (!token) {
  console.error('❌ No se encontró token en .env');
  process.exit(1);
}

const client = init(token);

try {
  const response = await client.ai.chat('Responde "OK" si me escuchas', {
    model: 'claude-sonnet-4-6'
  });
  console.log('✅ Puter:', response.message.content[0].text);
} catch (err) {
  console.error('❌ Puter error:', err.message);
}
