import fs from 'fs-extra';
import path from 'path';
import { exec } from 'child_process';
import chalk from 'chalk';
import readline from 'readline';
import { puterClient } from './modules/config.js';

const PROJECT_DIR = process.cwd();
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
const pregunta = (q) => new Promise(res => rl.question(q, res));

async function main() {
  console.clear();
  console.log(chalk.cyan.bold('\n🤖 AGENTE REAL DE PENALEX VE'));
  console.log(chalk.gray(`📂 Proyecto: ${PROJECT_DIR}\n`));

  let historial = '';
  try {
    historial = await fs.readFile('HISTORIAL.md', 'utf-8');
    console.log(chalk.green(`✅ Historial cargado: ${historial.split('\n').length} líneas`));
  } catch (e) {
    console.log(chalk.yellow('⚠️ No se encontró HISTORIAL.md.'));
  }

  let contexto = '';
  try {
    contexto = await fs.readFile('CONTEXTO.md', 'utf-8');
    console.log(chalk.green(`✅ Contexto cargado: ${contexto.split('\n').length} líneas`));
  } catch (e) {
    console.log(chalk.yellow('⚠️ No se encontró CONTEXTO.md.'));
  }

  console.log('');

  while (true) {
    const instruccion = await pregunta(chalk.blue('\n💬 ¿Qué necesitas? (o "salir"): '));
    if (instruccion.toLowerCase() === 'salir') break;

    console.log(chalk.yellow('\n⏳ Pensando...'));

    try {
      const prompt = `
## CONTEXTO DEL PROYECTO
${contexto || 'No hay contexto.'}

## HISTORIAL COMPLETO (últimas 5000 palabras)
${historial ? historial.slice(-5000) : 'No hay historial previo.'}

## NUEVA INSTRUCCIÓN
${instruccion}

## REGLAS
1. Si necesitas leer/modificar archivos, genera un script en JavaScript dentro de un bloque \`\`\`javascript ... \`\`\`.
2. Si no necesitas un script, responde en texto normal.
3. Siempre da respuestas concretas y accionables.
`;

      const respuesta = await puterClient.ai.chat(prompt, { model: 'claude-opus-5' });
      const texto = respuesta.message.content[0].text;

      console.log(chalk.cyan('\n📋 RESPUESTA:\n'));
      console.log(texto);

      // Buscar bloque de código JavaScript
      const match = texto.match(/```javascript\n([\s\S]*?)\n```/);
      if (match) {
        const codigo = match[1];
        console.log(chalk.yellow('\n📄 Script detectado. ¿Ejecutarlo? (s/n): '));
        const confirmar = await pregunta('> ');
        if (confirmar.toLowerCase() === 's') {
          const scriptPath = path.join(PROJECT_DIR, 'accion.js');
          await fs.writeFile(scriptPath, codigo, 'utf-8');
          console.log(chalk.green('✅ accion.js guardado. Ejecutando...'));
          try {
            const { stdout, stderr } = await new Promise((resolve, reject) => {
              exec(`node ${scriptPath}`, { cwd: PROJECT_DIR }, (error, stdout, stderr) => {
                if (error) reject(stderr || error.message);
                else resolve({ stdout, stderr });
              });
            });
            if (stdout) console.log(chalk.green('\n📤 SALIDA:\n'), stdout);
            if (stderr) console.log(chalk.yellow('\n⚠️ ERRORES:\n'), stderr);
          } catch (error) {
            console.error(chalk.red('❌ Error al ejecutar:'), error);
          }
        } else {
          console.log(chalk.gray('⏹️ Script guardado como accion.js. Ejecuta "node accion.js" cuando quieras.'));
        }
      } else {
        console.log(chalk.gray('ℹ️ No se generó script. Solo respuesta en texto.'));
      }

      // Guardar en historial
      await fs.appendFile('HISTORIAL.md', `\n\n[${new Date().toISOString()}] USUARIO: ${instruccion}\n[${new Date().toISOString()}] ASISTENTE: ${texto.slice(0, 500)}...\n`, 'utf-8').catch(() => {});

    } catch (error) {
      console.error(chalk.red('❌ Error:'), error.message);
    }
  }

  rl.close();
  console.log(chalk.green('\n👋 ¡Hasta luego!'));
}

main();
