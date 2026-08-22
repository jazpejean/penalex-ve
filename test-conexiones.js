import { puterClient, supabase, r2, R2_BUCKET } from './modules/config.js';

async function test() {
  console.log('🔌 Probando conexiones...\n');

  // 1. Puter
  try {
    const testIA = await puterClient.ai.chat('Responde "OK" si me escuchas', { model: 'claude-sonnet-4-6' });
    console.log('✅ Puter:', testIA.message.content[0].text);
  } catch (err) {
    console.error('❌ Puter:', err.message);
  }

  // 2. Supabase
  try {
    const { count, error } = await supabase.from('sentencias').select('*', { count: 'exact', head: true });
    if (error) throw error;
    console.log('✅ Supabase: conectado, ~', count, 'registros en "sentencias"');
  } catch (err) {
    console.warn('⚠️ Supabase:', err.message);
    console.log('   (Si la tabla "sentencias" no existe, ignora esta advertencia)');
  }

  // 3. R2
  try {
    const list = await r2.listObjectsV2({ Bucket: R2_BUCKET, MaxKeys: 1 }).promise();
    console.log('✅ R2: conectado, bucket contiene', list.Contents?.length || 0, 'objetos');
  } catch (err) {
    console.error('❌ R2:', err.message);
  }

  console.log('\n🎉 Prueba completada.');
}
test();
