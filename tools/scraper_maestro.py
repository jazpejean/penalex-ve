#!/usr/bin/env python3
"""
🕷️ SCRAPER MAESTRO - Leyes Venezolanas de ley.com.ve
Extrae TODAS las leyes disponibles en una sola ejecución
Autor: PENALEX VE
Fecha: 2026-08-14
"""

import sys
import os

# Agregar el path actual para importar el scraper
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from scraper_ley_secuencial import LeySecuencialScraper
import time

class ScrapterMaestro:
    """Scraper maestro para todas las leyes venezolanas"""
    
    # Configuración completa de TODAS las leyes disponibles
    LEYES_COMPLETAS = {
        # ===== CÓDIGOS FUNDAMENTALES =====
        'crbv': {
            'nombre': 'Constitución de la República Bolivariana de Venezuela',
            'sigla': 'CRBV',
            'categoria': 'constitucion',
            'slug': 'constitucion-de-la-republica-bolivariana-de-venezuela',
            'rango': (1, 350),
            'buscar_variantes': False,
            'prioridad': 1  # Alta prioridad
        },
        'cp': {
            'nombre': 'Código Penal',
            'sigla': 'CP',
            'categoria': 'codigo-penal',
            'slug': 'codigo-penal',
            'rango': (1, 500),
            'buscar_variantes': True,  # Tiene 191-A, 406-A, etc.
            'prioridad': 1
        },
        'copp': {
            'nombre': 'Código Orgánico Procesal Penal',
            'sigla': 'COPP',
            'categoria': 'codigo-organico-procesal-penal',
            'slug': 'codigo-organico-procesal-penal',
            'rango': (1, 650),
            'buscar_variantes': False,
            'prioridad': 1
        },
        
        # ===== LEYES CRÍTICAS (PENALES) =====
        'lcdoft': {
            'nombre': 'Ley Contra la Delincuencia Organizada y Financiamiento al Terrorismo',
            'sigla': 'LCDOFT',
            'categoria': 'ley-organica-contra-delincuencia-organizada',
            'slug': 'ley-organica-contra-delincuencia-organizada-financiamiento-terrorismo',
            'rango': (1, 100),
            'buscar_variantes': False,
            'prioridad': 2
        },
        'lcse': {
            'nombre': 'Ley Contra el Secuestro y la Extorsión',
            'sigla': 'LCSE',
            'categoria': 'ley-contra-secuestro-extorsion',
            'slug': 'ley-contra-secuestro-extorsion',
            'rango': (1, 50),
            'buscar_variantes': False,
            'prioridad': 2
        },
        'lod': {
            'nombre': 'Ley Orgánica de Drogas',
            'sigla': 'LOD',
            'categoria': 'ley-organica-drogas',
            'slug': 'ley-organica-drogas',
            'rango': (1, 200),
            'buscar_variantes': False,
            'prioridad': 2
        },
        'lecdi': {
            'nombre': 'Ley Especial Contra los Delitos Informáticos',
            'sigla': 'LECDI',
            'categoria': 'ley-delitos-informaticos',
            'slug': 'ley-especial-contra-delitos-informaticos',
            'rango': (1, 50),
            'buscar_variantes': False,
            'prioridad': 2
        },
        'locc': {
            'nombre': 'Ley Orgánica Contra la Corrupción',
            'sigla': 'LOCC',
            'categoria': 'ley-organica-contra-corrupcion',
            'slug': 'ley-organica-contra-corrupcion',
            'rango': (1, 100),
            'buscar_variantes': False,
            'prioridad': 2
        },
        
        # ===== LEYES DE PROTECCIÓN =====
        'lopnna': {
            'nombre': 'Ley Orgánica para la Protección de Niños, Niñas y Adolescentes',
            'sigla': 'LOPNNA',
            'categoria': 'lopnna',
            'slug': 'ley-organica-proteccion-ninos-ninas-adolescentes',
            'rango': (1, 700),
            'buscar_variantes': False,
            'prioridad': 2
        },
        'losdmvlv': {
            'nombre': 'Ley Orgánica sobre el Derecho de las Mujeres a una Vida Libre de Violencia',
            'sigla': 'LOSDMVLV',
            'categoria': 'ley-mujeres-vida-libre-violencia',
            'slug': 'ley-organica-derecho-mujeres-vida-libre-violencia',
            'rango': (1, 100),
            'buscar_variantes': False,
            'prioridad': 2
        },
        'lpvt': {
            'nombre': 'Ley de Protección de Víctimas, Testigos y demás Sujetos Procesales',
            'sigla': 'LPVT',
            'categoria': 'ley-proteccion-victimas-testigos',
            'slug': 'ley-proteccion-victimas-testigos-sujetos-procesales',
            'rango': (1, 80),
            'buscar_variantes': False,
            'prioridad': 3
        },
        
        # ===== LEYES COMPLEMENTARIAS =====
        'ldcam': {
            'nombre': 'Ley de Drogas, Control de Armas y Municiones',
            'sigla': 'LDCAM',
            'categoria': 'ley-drogas-armas-municiones',
            'slug': 'ley-drogas-control-armas-municiones',
            'rango': (1, 150),
            'buscar_variantes': False,
            'prioridad': 3
        },
        'lhrva': {
            'nombre': 'Ley de Hábeas Corpus y Amparo',
            'sigla': 'LHRVA',
            'categoria': 'ley-habeas-corpus-amparo',
            'slug': 'ley-habeas-corpus-amparo',
            'rango': (1, 50),
            'buscar_variantes': False,
            'prioridad': 3
        },
        'loa': {
            'nombre': 'Ley Orgánica de Aduanas',
            'sigla': 'LOA',
            'categoria': 'ley-organica-aduanas',
            'slug': 'ley-organica-aduanas',
            'rango': (1, 200),
            'buscar_variantes': False,
            'prioridad': 4
        },
        'cea': {
            'nombre': 'Código de Ética del Abogado',
            'sigla': 'CEA',
            'categoria': 'codigo-etica-abogado',
            'slug': 'codigo-etica-abogado-venezolano',
            'rango': (1, 100),
            'buscar_variantes': False,
            'prioridad': 4
        },
        'cop': {
            'nombre': 'Código de Procedimiento Civil',
            'sigla': 'COP',
            'categoria': 'codigo-procedimiento-civil',
            'slug': 'codigo-procedimiento-civil',
            'rango': (1, 900),
            'buscar_variantes': False,
            'prioridad': 4
        },
    }
    
    def __init__(self):
        self.scraper = LeySecuencialScraper()
        # Actualizar configuración del scraper con la completa
        self.scraper.LEYES_CONFIG = self.LEYES_COMPLETAS
        
        self.resultados = {
            'exitosas': [],
            'fallidas': [],
            'parciales': []
        }
    
    def scrappear_todas(self, solo_prioritarias=False, prioridad_max=4):
        """
        Scrappea todas las leyes configuradas
        
        Args:
            solo_prioritarias: Si True, solo scrappea prioridad 1-2
            prioridad_max: Scrappea hasta esta prioridad (1-4)
        """
        # Filtrar por prioridad
        leyes_a_scrappear = {}
        for clave, config in self.LEYES_COMPLETAS.items():
            if config['prioridad'] <= prioridad_max:
                leyes_a_scrappear[clave] = config
        
        # Ordenar por prioridad
        leyes_ordenadas = sorted(
            leyes_a_scrappear.items(),
            key=lambda x: x[1]['prioridad']
        )
        
        total = len(leyes_ordenadas)
        
        print("\n" + "="*80)
        print(f"🚀 SCRAPER MAESTRO - INICIANDO")
        print(f"   Total de leyes a scrappear: {total}")
        print(f"   Prioridad máxima: {prioridad_max}")
        print("="*80 + "\n")
        
        for i, (clave, config) in enumerate(leyes_ordenadas, 1):
            print(f"\n{'='*80}")
            print(f"📖 LEY {i}/{total} - Prioridad {config['prioridad']}")
            print(f"   {config['sigla']}: {config['nombre']}")
            print(f"{'='*80}")
            
            tiempo_inicio = time.time()
            
            try:
                exito = self.scraper.scrappear_ley(clave)
                tiempo_total = time.time() - tiempo_inicio
                
                if exito:
                    self.resultados['exitosas'].append({
                        'clave': clave,
                        'sigla': config['sigla'],
                        'tiempo': tiempo_total
                    })
                    print(f"\n✅ {config['sigla']} completado en {tiempo_total:.1f}s")
                else:
                    self.resultados['fallidas'].append({
                        'clave': clave,
                        'sigla': config['sigla'],
                        'razon': 'No se extrajo ningún artículo'
                    })
                    print(f"\n❌ {config['sigla']} FALLÓ")
                
            except KeyboardInterrupt:
                print(f"\n\n⚠️ INTERRUMPIDO por usuario")
                print(f"   Leyes completadas: {len(self.resultados['exitosas'])}/{i}")
                self._mostrar_resumen()
                return
                
            except Exception as e:
                self.resultados['fallidas'].append({
                    'clave': clave,
                    'sigla': config['sigla'],
                    'razon': str(e)
                })
                print(f"\n❌ ERROR en {config['sigla']}: {e}")
            
            # Pausa entre leyes para no saturar el servidor
            if i < total:
                print(f"\n⏸️ Pausa de 5 segundos antes de siguiente ley...")
                time.sleep(5)
        
        self._mostrar_resumen()
    
    def _mostrar_resumen(self):
        """Muestra resumen final"""
        print("\n" + "="*80)
        print("📊 RESUMEN FINAL DEL SCRAPING")
        print("="*80)
        
        exitosas = len(self.resultados['exitosas'])
        fallidas = len(self.resultados['fallidas'])
        total = exitosas + fallidas
        
        print(f"\n✅ EXITOSAS: {exitosas}/{total}")
        for ley in self.resultados['exitosas']:
            print(f"   - {ley['sigla']:10} ({ley['tiempo']:.1f}s)")
        
        if self.resultados['fallidas']:
            print(f"\n❌ FALLIDAS: {fallidas}/{total}")
            for ley in self.resultados['fallidas']:
                print(f"   - {ley['sigla']:10} - {ley['razon']}")
        
        tiempo_total = sum(l['tiempo'] for l in self.resultados['exitosas'])
        
        print(f"\n⏱️ TIEMPO TOTAL: {tiempo_total/60:.1f} minutos")
        print(f"📁 Archivos guardados en: ../leyes_json/")
        print("="*80 + "\n")
        
        # Guardar reporte
        self._guardar_reporte()
    
    def _guardar_reporte(self):
        """Guarda reporte en archivo"""
        import json
        from datetime import datetime
        
        reporte = {
            'fecha': datetime.now().isoformat(),
            'exitosas': len(self.resultados['exitosas']),
            'fallidas': len(self.resultados['fallidas']),
            'leyes': self.resultados
        }
        
        with open('../leyes_json/reporte_scraping.json', 'w', encoding='utf-8') as f:
            json.dump(reporte, f, ensure_ascii=False, indent=2)
        
        print("📄 Reporte guardado en: ../leyes_json/reporte_scraping.json")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='🕷️ Scraper Maestro - Todas las leyes venezolanas',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos:
  # Scrappear TODAS las leyes (15 leyes, ~2-3 horas)
  python scraper_maestro.py --todas

  # Solo leyes prioritarias (prioridad 1-2, ~1 hora)
  python scraper_maestro.py --prioritarias

  # Hasta prioridad 3 (incluye complementarias)
  python scraper_maestro.py --prioridad 3

  # Ver leyes disponibles
  python scraper_maestro.py --listar
        """
    )
    
    parser.add_argument(
        '--todas',
        action='store_true',
        help='Scrappear TODAS las leyes (prioridad 1-4)'
    )
    parser.add_argument(
        '--prioritarias',
        action='store_true',
        help='Solo leyes prioritarias (prioridad 1-2)'
    )
    parser.add_argument(
        '--prioridad',
        type=int,
        choices=[1, 2, 3, 4],
        help='Scrappear hasta esta prioridad'
    )
    parser.add_argument(
        '--listar',
        action='store_true',
        help='Listar todas las leyes disponibles'
    )
    
    args = parser.parse_args()
    
    maestro = ScrapterMaestro()
    
    if args.listar:
        print("\n" + "="*80)
        print("📚 LEYES DISPONIBLES PARA SCRAPING")
        print("="*80 + "\n")
        
        por_prioridad = {}
        for clave, config in maestro.LEYES_COMPLETAS.items():
            prio = config['prioridad']
            if prio not in por_prioridad:
                por_prioridad[prio] = []
            por_prioridad[prio].append((clave, config))
        
        nombres_prioridad = {
            1: "CÓDIGOS FUNDAMENTALES",
            2: "LEYES CRÍTICAS (Penales)",
            3: "LEYES COMPLEMENTARIAS",
            4: "LEYES SECUNDARIAS"
        }
        
        total = 0
        for prio in sorted(por_prioridad.keys()):
            print(f"\n🔹 PRIORIDAD {prio}: {nombres_prioridad[prio]}")
            print("-" * 80)
            for clave, config in por_prioridad[prio]:
                inicio, fin = config['rango']
                variantes = " (con variantes -A, -B)" if config['buscar_variantes'] else ""
                print(f"  {total+1:2}. {config['sigla']:10} - {config['nombre']}")
                print(f"      Clave: {clave} | Rango: Arts. {inicio}-{fin}{variantes}")
                total += 1
        
        print(f"\n{'='*80}")
        print(f"TOTAL: {total} leyes disponibles")
        print("="*80 + "\n")
        
        print("💡 Tiempo estimado por prioridad:")
        print("   Prioridad 1 (3 leyes): ~45-60 min")
        print("   Prioridad 1-2 (8 leyes): ~90-120 min")
        print("   Prioridad 1-3 (11 leyes): ~120-150 min")
        print("   Todas (15 leyes): ~150-180 min")
        print()
        
    elif args.todas:
        maestro.scrappear_todas(prioridad_max=4)
    elif args.prioritarias:
        maestro.scrappear_todas(prioridad_max=2)
    elif args.prioridad:
        maestro.scrappear_todas(prioridad_max=args.prioridad)
    else:
        print("❌ Debes especificar una opción")
        print("\nEjemplos:")
        print("  python scraper_maestro.py --listar")
        print("  python scraper_maestro.py --prioritarias")
        print("  python scraper_maestro.py --todas")
        print("\nUsa --help para ver todas las opciones")


if __name__ == '__main__':
    main()
