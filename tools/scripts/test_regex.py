#!/usr/bin/env python3
"""
Test del regex para verificar que capture las URLs correctamente
Y que elimine el código VML de Microsoft Office
"""

import re

# La URL del logo correcto
LOGO_CORRECTO = 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/assets/logo.jpg'

# Patrones actualizados (orden importa)
PATRONES_ROTOS = [
    # URLs absolutas con dominio R2 (primero para evitar reemplazos parciales)
    r'https://pub-a6e0bfa2e9174e91b031ae28c0667009\.r2\.dev/html/[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    # Logo viejo del TSJ (URLs completas primero)
    r'https://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    r'http://historico\.tsj\.gob\.ve/graficos/encabezadotsj\.jpg',
    # Rutas relativas con punto (./)
    r'\./[^"\'<>\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    # Rutas relativas sin punto
    r'(?<![:/])[^/"\s]+_archivos/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
    # Rutas absolutas relativas al dominio
    r'/graficos/encabezadotsj\.jpg',
    r'/imagenes/[^"\'<>\s]+\.(jpg|png|gif|jpeg)',
]

# HTML de prueba real (con código VML y texto de sala)
html_con_vml = '''<h1><!--[if gte vml 1]><o:wrapblock><v:shapetype id="_x0000_t75" coordsize="21600,21600"
  o:spt="75" o:preferrelative="t" path="m@4@5l@4@11@9@11@9@5xe" filled="f"
  stroked="f">
  <v:stroke joinstyle="miter"/>
  <v:formulas>
   <v:f eqn="if lineDrawn pixelLineWidth 0"/>
  </v:formulas>
  <v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect"/>
  <o:lock v:ext="edit" aspectratio="t"/>
 </v:shapetype><v:shape id="_x0000_s1026" type="#_x0000_t75" style='position:absolute;
  left:0;text-align:left;margin-left:0;margin-top:-155.95pt;width:176pt;
  height:2in;z-index:1;mso-position-horizontal:center;
  mso-position-horizontal-relative:text;mso-position-vertical-relative:text'>
  <v:imagedata src="./01-200100-00-002_archivos/image001.jpg" o:title="encabezadotsj"/>
  <w:wrap type="topAndBottom" anchorx="page"/>
 </v:shape><![endif]--><!--[if !vml]--><img width="235" height="192" src="./01-200100-00-002_archivos/image001.jpg" v:shapes="_x0000_s1026"><!--[endif]--><!--[if gte vml 1]></o:wrapblock><![endif]--><br style="mso-ignore:vglayout" clear="ALL">
<span style="font-size:12.0pt;mso-bidi-font-size:10.0pt;font-family:&quot;Times New Roman&quot;;
text-transform:uppercase">sala constitucional<o:p></o:p></span></h1>
'''

print("="*80)
print("🧪 TEST DE LIMPIEZA VML + REGEX")
print("="*80)

print(f"\n✅ Logo correcto: {LOGO_CORRECTO}\n")

print("📋 PASO 1: Reemplazar imágenes en código VML (v:imagedata)")
print("-" * 80)

# Reemplazar imágenes en v:imagedata (dentro del VML)
html_paso1 = re.sub(
    r'(<v:imagedata\s+src=")[^"]+_archivos/[^"]+\.(jpg|png|gif|jpeg)(")',
    r'\1' + LOGO_CORRECTO + r'\3',
    html_con_vml,
    flags=re.IGNORECASE
)

print("✅ Imágenes en v:imagedata reemplazadas")
print()

# Verificar que el texto se preservó
if "sala constitucional" in html_paso1:
    print("✅ TEXTO PRESERVADO en paso 1\n")
else:
    print("❌ ERROR: texto perdido en paso 1\n")

print("📋 PASO 2: Reemplazar rutas de imágenes rotas")
print("-" * 80)

# URLs de prueba (las que mencionaste + rutas relativas)
urls_test = [
    'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev/html/jurisprudencias/constitucional/01-200100-00-002_archivos/image001.jpg',
    '/graficos/encabezadotsj.jpg',
    'https://historico.tsj.gob.ve/graficos/encabezadotsj.jpg',
    './01-200100-00-002_archivos/image001.jpg',  # RUTA RELATIVA CON ./
    '01-200100-00-002_archivos/image001.jpg',    # RUTA RELATIVA SIN ./
]

for url in urls_test:
    print(f"URL original: {url}")
    
    encontrado = False
    for patron in PATRONES_ROTOS:
        if re.search(patron, url):
            print(f"  ✅ Capturado por: {patron[:50]}...")
            encontrado = True
            break
    
    if not encontrado:
        print(f"  ❌ NO capturado por ningún patrón")
    
    # Simular reemplazo
    html_test = f'<img src="{url}">'
    html_corregido = html_test
    for patron in PATRONES_ROTOS:
        html_corregido = re.sub(patron, LOGO_CORRECTO, html_corregido, flags=re.IGNORECASE)
    
    if html_test != html_corregido:
        print(f"  ✅ REEMPLAZADO: {html_corregido}")
    else:
        print(f"  ❌ NO REEMPLAZADO")
    
    print()

print("📋 PASO 3: Reemplazar otras imágenes rotas (<img> tags)")
print("-" * 80)
html_final = html_paso1
for patron in PATRONES_ROTOS:
    html_final = re.sub(patron, LOGO_CORRECTO, html_final, flags=re.IGNORECASE)

print("HTML FINAL:")
print(html_final)
print()

# Verificar resultado final
if "sala constitucional" in html_final and html_final.count(LOGO_CORRECTO) >= 2:
    print("✅ RESULTADO CORRECTO:")
    print(f"   - Logo correcto presente en v:imagedata y <img>")
    print("   - Texto 'sala constitucional' preservado")
    print(f"   - Total de logos: {html_final.count(LOGO_CORRECTO)}")
else:
    print("\n❌ ERROR en resultado final")

print("\n" + "="*80)
print("✅ TEST COMPLETADO")
print("="*80)

