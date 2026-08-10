import { initializeApp } from "https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js";
import { getFirestore, collection, getDocs }
  from "https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore.js";

// ⚠️ REEMPLAZA con tu config real (Firebase Console > ⚙️ > General > Tus apps > App web)
// La apiKey de Firebase NO es secreta: puede ir en código público sin riesgo.
const firebaseConfig = {
  apiKey: "REEMPLAZA_API_KEY",
  authDomain: "penalex-ve.firebaseapp.com",
  projectId: "penalex-ve",
  storageBucket: "penalex-ve.appspot.com",
  messagingSenderId: "REEMPLAZA",
  appId: "REEMPLAZA"
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

let allDocs = [];

document.getElementById('btn-load').addEventListener('click', async () => {
  const status = document.getElementById('status');
  status.textContent = 'Cargando...';
  try {
    const snap = await getDocs(collection(db, 'documentos'));
    allDocs = snap.docs.map(d => ({ id: d.id, ...d.data() }));
    status.textContent = allDocs.length + ' documentos cargados';
    updateStats();
    render();
  } catch (e) {
    status.textContent = '';
    document.getElementById('results').innerHTML =
      '<div class="error">❌ Error al leer Firestore: ' + e.message +
      '<br>Revisa las reglas de Firestore (lectura pública de /documentos).</div>';
  }
});

function updateStats() {
  document.getElementById('stat-total').textContent = allDocs.length;
  document.getElementById('stat-sent').textContent = allDocs.filter(d => d.tipo === 'sentencia').length;
  document.getElementById('stat-juris').textContent = allDocs.filter(d => d.tipo === 'jurisprudencia').length;
  document.getElementById('stat-res').textContent = allDocs.filter(d => d.tipo === 'resolucion').length;
}

function render() {
  const q = document.getElementById('search').value.toLowerCase();
  const tipo = document.getElementById('filter-tipo').value;
  const sala = document.getElementById('filter-sala').value;

  let filtered = allDocs.filter(d => {
    if (tipo && d.tipo !== tipo) return false;
    if (sala && d.sala !== sala) return false;
    if (q) {
      const hay = [d.id, d.partes, d.ponente, d.expediente, d.procedimiento, d.decision, d.extracto, d.texto_busqueda]
        .filter(Boolean).join(' ').toLowerCase();
      if (!hay.includes(q)) return false;
    }
    return true;
  });

  filtered.sort((a, b) => (b.fecha || '').localeCompare(a.fecha || ''));

  const container = document.getElementById('results');
  if (filtered.length === 0) {
    container.innerHTML = '<div class="loading">No se encontraron documentos.</div>';
    return;
  }

  const mostrar = filtered.slice(0, 100);
  let html = '<div style="color:#93a3b8;margin-bottom:10px;">Mostrando ' + mostrar.length +
             ' de ' + filtered.length + ' resultados</div>';

  for (const d of mostrar) {
    const sub = d.tipo === 'resolucion' ? 'resoluciones' : d.tipo + 's';
    const htmlUrl = '/html/' + sub + '/' + d.sala + '/' + d.id + '.html';
    const pdfUrl = '/pdf/' + sub + '/' + d.sala + '/' + d.id + '.pdf';

    html += '<div class="doc">';
    html += '<div class="doc-title">' + (d.tipo || '').toUpperCase() + ' ' + (d.num_sentencia || '') +
            ' - Exp. ' + (d.expediente || 's/n') + '</div>';
    html += '<div class="doc-meta">📅 ' + (d.fecha || 's/f') + ' · 🏛️ ' + (d.sala || '') +
            ' · 👤 ' + (d.ponente || 's/p') +
            (d.procedimiento ? ' · ⚖️ ' + d.procedimiento : '') +
            (d.decision ? ' · 📋 ' + d.decision : '') + '</div>';
    if (d.partes) html += '<div class="doc-meta"><strong>Partes:</strong> ' + d.partes + '</div>';
    if (d.extracto) {
      const ex = String(d.extracto);
      html += '<div class="doc-extracto">' + ex.substring(0, 400) + (ex.length > 400 ? '...' : '') + '</div>';
    }
    html += '<div class="doc-links">';
    html += '<a href="' + htmlUrl + '" target="_blank">Ver HTML</a>';
    html += '<a href="' + pdfUrl + '" target="_blank" class="pdf">Descargar PDF</a>';
    if (d.url_tsj) html += '<a href="' + d.url_tsj + '" target="_blank" class="pdf">Fuente TSJ</a>';
    html += '</div></div>';
  }

  container.innerHTML = html;
}

document.getElementById('search').addEventListener('input', render);
document.getElementById('filter-tipo').addEventListener('change', render);
document.getElementById('filter-sala').addEventListener('change', render);
