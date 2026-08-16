# 📥 INSTRUCCIONES PARA DESCARGAR LAS 17 LEYES

## ✅ Leyes Seleccionadas

Has seleccionado estas **17 leyes** para PENALEX:

### 🔴 Core (4)
1. **CRBV** - Constitución de Venezuela
2. **CP** - Código Penal
3. **COPP** - Código Orgánico Procesal Penal  
4. **LOA** - Ley de Amparo

### 🟡 Penales Especiales (6)
5. **LOSDMVLV** - Ley Violencia de Género
6. **LOD** - Ley de Drogas
7. **LCDOFT** - Ley contra Delincuencia Organizada
8. **LCSE** - Ley contra Secuestro y Extorsión
9. **LHRVA** - Ley Hurto/Robo Vehículos
10. **LDCAM** - Ley Desarme y Armas

### 🟢 Complementarias (7)
12. **LPVT** - Ley Protección de Víctimas
22. **LECDI** - Ley Delitos Informáticos
23. **LCTPTIM** - Ley Trata de Personas
20. **LORPA** - Ley Responsabilidad Penal Adolescente
15. **LOPNNA** - Ley Protección Niños, Niñas y Adolescentes
17. **LOCC** - Ley contra la Corrupción
-- **MUCC** - Manual Único Cadena de Custodia

---

## 🚀 OPCIÓN 1: Ejecutar Script Automático

### Paso 1: Instalar dependencias
```bash
pip3 install PyPDF2 requests python-dotenv
```

### Paso 2: Ejecutar script
```bash
cd /home/jeanjazpe/Desktop/Penalex_VE
python3 tools/scripts/descargar_leyes_seleccionadas.py
```

El script:
- ✅ Descarga los 17 PDFs desde IAJuriss.com
- ✅ Extrae el texto de cada PDF
- ✅ Guarda metadata en JSON
- ✅ Muestra resumen al final

---

## 🔧 OPCIÓN 2: Descarga Manual (si el script falla)

Si alguna ley no se descarga automáticamente, aquí están las URLs directas:

### Core
```
https://iajuriss.com/docs/leyes/constitucion_venezuela.pdf
https://iajuriss.com/docs/leyes/codigo_penal.pdf
https://iajuriss.com/docs/leyes/copp_2012.pdf
https://iajuriss.com/docs/leyes/ley-organica-de-amparo-sobre-derechos-y-garantias-constitucionales.pdf
```

### Penales Especiales
```
https://iajuriss.com/docs/leyes/ley-mujer.pdf
https://iajuriss.com/docs/leyes/lod_2010.pdf
https://iajuriss.com/docs/leyes/ley-contra-delincuencia-organizada.pdf
https://iajuriss.com/docs/leyes/ley-contra-secuestro-extorsion.pdf
https://iajuriss.com/docs/leyes/ley-hurto-robo-vehiculos.pdf
https://iajuriss.com/docs/leyes/ley-desarme-armas.pdf
```

### Complementarias
```
https://iajuriss.com/docs/leyes/ley-proteccion-victimas.pdf
https://iajuriss.com/docs/leyes/ley-delitos-informaticos.pdf
https://iajuriss.com/docs/leyes/ley-trata-personas.pdf
https://iajuriss.com/docs/leyes/ley-responsabilidad-penal-adolescente.pdf
https://iajuriss.com/docs/leyes/lopnna.pdf
https://iajuriss.com/docs/leyes/ley-contra-corrupcion.pdf
https://iajuriss.com/docs/leyes/manual-cadena-custodia.pdf
```

**Guardar en:** `tools/data/leyes/pdfs/`

---

## 📁 Estructura de Archivos

Después de la descarga tendrás:

```
tools/data/leyes/
├── pdfs/
│   ├── CRBV.pdf
│   ├── CP.pdf
│   ├── COPP.pdf
│   └── ... (17 PDFs total)
└── textos/
    ├── CRBV.txt
    ├── CRBV.json
    ├── CP.txt
    ├── CP.json
    └── ... (17 TXT + 17 JSON)
```

---

## 🎯 Próximos Pasos

Una vez descargadas las leyes:

1. **Parser de Artículos** - Extraer estructura (Títulos, Capítulos, Artículos)
2. **Schema Supabase** - Tablas `leyes` y `articulos`  
3. **Embeddings** - Vectorizar texto para búsqueda semántica
4. **Migración** - Actualizar `leyes_service.dart` a Supabase
5. **Integración AI** - Conectar con chat/dosimetría

---

## ⚠️ Notas Importantes

- **IAJuriss.com** tiene 643 leyes, pero solo descargamos las 17 seleccionadas
- Algunos PDFs pueden estar escaneados (imágenes) y no extraerán texto limpio
- Si una URL da 404, buscar nombre alternativo en https://iajuriss.com/leyes
- El Manual de Cadena de Custodia puede no estar como ley, sino como documento oficial

---

## 🆘 Problemas Comunes

### Error 404 en descarga
- Verificar nombre exacto en IAJuriss.com
- Algunos nombres tienen guiones, otros no
- Ejemplo: `ley-contra-corrupcion.pdf` vs `ley_contra_corrupcion.pdf`

### Sin texto extraído
- PDF es imagen escaneada (no tiene texto seleccionable)
- Solución: Usar OCR (pytesseract) o buscar versión con texto

### Dependencias faltantes
```bash
pip3 install --user PyPDF2 requests python-dotenv
```

---

¿Necesitas ayuda ejecutando el script? Avísame y ajusto la estrategia. 🚀
