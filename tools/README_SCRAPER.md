# 🕷️ Scraper de Leyes Venezolanas - ley.com.ve

## 📚 ¿Qué hace este script?

Extrae leyes venezolanas desde [ley.com.ve](https://www.ley.com.ve) y las convierte a JSON estructurado con formato jerárquico:

```
Ley
 └── Título
      └── Capítulo
           └── Sección (opcional)
                └── Artículos
```

---

## 🚀 Instalación

### 1. Instalar Python 3.8+
```bash
python3 --version  # Verificar versión
```

### 2. Crear entorno virtual (recomendado)
```bash
cd /home/jeanjazpe/Desktop/Penalex_VE/tools
python3 -m venv venv
source venv/bin/activate  # En Linux/Mac
```

### 3. Instalar dependencias
```bash
pip install -r requirements_scraper.txt
```

---

## 📖 Uso

### Listar leyes disponibles
```bash
python scraper_leyes_ve.py --listar
```

**Salida:**
```
📚 LEYES DISPONIBLES PARA SCRAPPING
═══════════════════════════════════════════════════════════════════

 1. CP         - Código Penal
    Clave: codigo-penal
    URL: https://www.ley.com.ve/codigo-penal

 2. COPP       - Código Orgánico Procesal Penal
    Clave: copp
    URL: https://www.ley.com.ve/codigo-organico-procesal-penal

 3. LCDOFT     - Ley Contra la Delincuencia Organizada...
    Clave: lcdoft
    [...]
```

---

### Scrappear UNA ley específica
```bash
# Ley Contra la Delincuencia Organizada
python scraper_leyes_ve.py --ley lcdoft

# Ley Contra el Secuestro
python scraper_leyes_ve.py --ley lcse

# Ley Orgánica de Drogas
python scraper_leyes_ve.py --ley lod
```

**Salida:**
```
═══════════════════════════════════════════════════════════════════
🔍 Scrappeando: Ley Contra la Delincuencia Organizada (LCDOFT)
═══════════════════════════════════════════════════════════════════
📥 Descargando: https://www.ley.com.ve/...
  📘 TÍTULO I: DISPOSICIONES GENERALES
    📗 CAPÍTULO I: Objeto y Ámbito de Aplicación
        ✓ Artículo 1
        ✓ Artículo 2
    📗 CAPÍTULO II: Definiciones
        ✓ Artículo 3
        [...]

✅ Extraídos 87 artículos
💾 Guardado en: ../leyes_json/lcdoft_scraped.json
```

---

### Scrappear TODAS las leyes críticas
```bash
python scraper_leyes_ve.py --todas
```

**Esto scrappea automáticamente:**
1. LCDOFT - Ley Contra Delincuencia Organizada
2. LCSE - Ley Contra Secuestro y Extorsión
3. LOD - Ley Orgánica de Drogas
4. LOCTP - Ley Contra Trata de Personas
5. LCC - Ley Contra el Contrabando
6. LOPNNA - Ley de Protección de Niños
7. LOSDMVLV - Ley Sobre Violencia contra la Mujer
8. LECDI - Ley Delitos Informáticos
9. CP - Código Penal
10. COPP - Código Orgánico Procesal Penal

**Tiempo estimado:** 5-10 minutos (2-3 segundos por ley + procesamiento)

---

### Especificar directorio de salida
```bash
python scraper_leyes_ve.py --ley lcdoft --output /ruta/personalizada
```

Por defecto guarda en: `../leyes_json/`

---

## 📂 Estructura del JSON Generado

```json
{
  "codigo": "LCDOFT",
  "nombre": "Ley Contra la Delincuencia Organizada y Financiamiento al Terrorismo",
  "fuente": "ley.com.ve",
  "fecha_extraccion": "2026-08-13",
  "estructura": [
    {
      "titulo": "I",
      "nombre": "DISPOSICIONES GENERALES",
      "capitulos": [
        {
          "capitulo": "I",
          "nombre": "Objeto y Ámbito de Aplicación",
          "secciones": [],
          "articulos": [
            {
              "numero": 1,
              "texto": "Esta Ley tiene por objeto prevenir...",
              "texto_completo": "Artículo 1. Esta Ley tiene por objeto..."
            },
            {
              "numero": 2,
              "texto": "Las disposiciones de esta Ley...",
              "texto_completo": "Artículo 2. Las disposiciones..."
            }
          ]
        }
      ]
    }
  ]
}
```

---

## 🔧 Características Avanzadas

### 1. Detección Inteligente de Estructura
El script detecta automáticamente:
- ✅ Títulos (TÍTULO I, II, III...)
- ✅ Capítulos (CAPÍTULO I, II, III...)
- ✅ Secciones (SECCIÓN I, II, III...)
- ✅ Artículos (Artículo 1, 2, 3...)

### 2. Limpieza de Texto
- ✅ Elimina espacios múltiples
- ✅ Normaliza saltos de línea
- ✅ Extrae contenido limpio

### 3. Manejo de Errores
- ✅ Reintenta en caso de fallo de red
- ✅ Continúa con siguiente ley si una falla
- ✅ Reporta errores detallados

### 4. Respeto al Servidor
- ✅ Pausa de 2 segundos entre páginas
- ✅ Pausa de 3 segundos entre leyes
- ✅ User-Agent apropiado

---

## 🎯 Casos de Uso

### Caso 1: Actualizar una ley específica
```bash
# Si LCDOFT fue reformada
python scraper_leyes_ve.py --ley lcdoft

# Revisar el JSON generado
cat ../leyes_json/lcdoft_scraped.json | jq '.estructura[0].capitulos[0].articulos[0]'
```

### Caso 2: Obtener todas las leyes pendientes
```bash
# Scrappear las 10 leyes críticas
python scraper_leyes_ve.py --todas

# Verificar archivos generados
ls -lh ../leyes_json/*_scraped.json
```

### Caso 3: Integrar con PENALEX VE
```bash
# 1. Scrappear ley
python scraper_leyes_ve.py --ley lcdoft

# 2. Renombrar para integración
mv ../leyes_json/lcdoft_scraped.json ../leyes_json/lcdoft.json

# 3. Verificar formato
python -m json.tool ../leyes_json/lcdoft.json > /dev/null && echo "✅ JSON válido"
```

---

## 🐛 Solución de Problemas

### Error: "No module named 'requests'"
```bash
pip install -r requirements_scraper.txt
```

### Error: "No se encontró contenido principal"
La estructura del sitio web cambió. Opciones:
1. Inspeccionar HTML manualmente
2. Ajustar selectores en el código
3. Reportar issue

### Error: "Connection timeout"
```bash
# Reintentar con delay mayor
# Editar scraper_leyes_ve.py línea ~54:
time.sleep(5)  # Cambiar de 2 a 5 segundos
```

### JSON generado está vacío o incompleto
1. Verificar que la URL existe: Abrir en navegador
2. Ver HTML crudo:
```bash
curl "https://www.ley.com.ve/codigo-penal" > test.html
cat test.html  # Revisar estructura
```

---

## 📊 Comparación: PDF vs HTML Scraping

| Aspecto | PDF | HTML Scraping |
|---------|-----|---------------|
| **Velocidad** | Lento (OCR) | Rápido ⚡ |
| **Precisión** | 85-90% | 95-98% ✅ |
| **Estructura** | Difícil | Fácil ✅ |
| **Mantenimiento** | Complejo | Simple ✅ |
| **Dependencias** | PyPDF2, OCR | Requests, BS4 |
| **Costo computacional** | Alto (CPU) | Bajo ✅ |

**Conclusión:** HTML scraping es MUCHO mejor para este caso.

---

## 🔐 Consideraciones Legales

### Términos de Uso
- ✅ ley.com.ve publica contenido público (leyes oficiales)
- ✅ No hay copyright en textos legales venezolanos
- ✅ Uso educativo y profesional permitido
- ⚠️ Usar con moderación (no saturar servidor)

### Validación Legal
- ⚠️ **IMPORTANTE:** Verificar que las leyes extraídas sean versiones OFICIALES
- ⚠️ Contrastar con Gaceta Oficial si hay dudas
- ⚠️ Indicar fuente en la app: "Fuente: ley.com.ve"

---

## 🚀 Próximos Pasos

### 1. Scrappear las 10 leyes críticas
```bash
cd /home/jeanjazpe/Desktop/Penalex_VE/tools
python scraper_leyes_ve.py --todas
```

### 2. Verificar calidad de los JSONs
```bash
cd ../leyes_json
for file in *_scraped.json; do
    echo "Verificando $file..."
    python -m json.tool "$file" > /dev/null && echo "✅ Válido" || echo "❌ Inválido"
done
```

### 3. Integrar en PENALEX VE
```bash
# Renombrar archivos scrapeados
mv lcdoft_scraped.json LCDOFT.json
mv lcse_scraped.json LCSE.json
mv lod_scraped.json LOD.json
# ... etc
```

### 4. Actualizar índice de leyes en la app
Editar: `lib/data/leyes_disponibles.dart`

---

## 📝 Registro de Cambios

### v1.0.0 (2026-08-13)
- ✅ Scraping de 10 leyes críticas
- ✅ Detección automática de estructura jerárquica
- ✅ Limpieza inteligente de texto
- ✅ Exportación a JSON estructurado
- ✅ CLI con múltiples opciones

---

## 💡 Tips y Trucos

### Scrappear en batch de noche
```bash
# Crear script automático
cat > scrappear_noche.sh << 'EOF'
#!/bin/bash
cd /home/jeanjazpe/Desktop/Penalex_VE/tools
source venv/bin/activate
python scraper_leyes_ve.py --todas
date >> scraping.log
EOF

chmod +x scrappear_noche.sh

# Ejecutar con cron a las 2am
crontab -e
# Agregar: 0 2 * * * /ruta/scrappear_noche.sh
```

### Ver progreso en tiempo real
```bash
python scraper_leyes_ve.py --todas | tee scraping_$(date +%Y%m%d).log
```

### Validar todos los JSONs
```bash
for json in ../leyes_json/*_scraped.json; do
    articulos=$(jq '[.estructura[].capitulos[].articulos[]] | length' "$json")
    echo "$(basename $json): $articulos artículos"
done
```

---

## 🤝 Contribuir

Si encuentras errores o mejoras:
1. Editar `scraper_leyes_ve.py`
2. Probar con una ley
3. Documentar cambios
4. Compartir con el equipo

---

## 📧 Soporte

**Problemas comunes:** Ver sección "Solución de Problemas"  
**Preguntas técnicas:** Documentación del código (docstrings)  
**Actualizaciones del sitio:** Revisar HTML actual y ajustar selectores

---

**Autor:** PENALEX VE Team  
**Fecha:** 13 de agosto de 2026  
**Versión:** 1.0.0  
**Licencia:** Uso interno PENALEX VE
