#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Procesador de PDFs de Jurisprudencia TSJ Venezuela
Extrae texto, metadata y estructura sentencias en JSON para Firestore
"""

import os
import json
import re
from datetime import datetime
from pathlib import Path
import PyPDF2
import pdfplumber
from tqdm import tqdm

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

INPUT_DIR = "pdfs_jurisprudencia"  # Carpeta con PDFs
OUTPUT_DIR = "sentencias_procesadas"  # Salida JSON
LOG_FILE = "procesamiento.log"

# Salas del TSJ
SALAS = {
    'penal': 'Sala Penal',
    'constitucional': 'Sala Constitucional',
    'politicoadministrativa': 'Sala Político-Administrativa',
    'electoral': 'Sala Electoral',
    'social': 'Sala Social',
    'civil': 'Sala Civil',
    'plena': 'Sala Plena'
}

# Delitos venezolanos comunes
DELITOS_VENEZOLANOS = [
    'homicidio', 'homicidio calificado', 'homicidio intencional', 'homicidio culposo',
    'robo', 'robo agravado', 'robo en grado de frustración',
    'hurto', 'hurto calificado', 'hurto agravado',
    'lesiones', 'lesiones graves', 'lesiones leves', 'lesiones personales',
    'violación', 'abuso sexual', 'acto carnal',
    'secuestro', 'secuestro express', 'privación de libertad',
    'extorsión',
    'estafa', 'estafa agravada',
    'narcotráfico', 'tráfico de drogas', 'tráfico de estupefacientes',
    'porte ilícito de arma', 'porte ilícito', 'porte de arma de fuego',
    'legitimación de capitales', 'lavado de dinero',
    'corrupción', 'peculado', 'concusión',
    'trata de personas', 'trata de blancas',
    'violencia de género', 'violencia contra la mujer',
    'resistencia a la autoridad',
    'asociación para delinquir', 'agavillamiento',
    'apropiación indebida',
    'falsificación de documento',
    'prevaricación'
]


class JurisprudenciaPDFProcessor:
    """Procesador de PDFs de sentencias TSJ"""
    
    def __init__(self, input_dir, output_dir):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        self.stats = {
            'total_pdfs': 0,
            'procesados_ok': 0,
            'errores': 0,
            'sin_metadata': 0
        }
        
        self.log_entries = []
    
    def log(self, mensaje, tipo='INFO'):
        """Registra mensaje en log"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        entry = f"[{timestamp}] [{tipo}] {mensaje}"
        self.log_entries.append(entry)
        print(entry)
    
    def extraer_texto_pdf(self, pdf_path):
        """Extrae texto de PDF usando pdfplumber (mejor que PyPDF2)"""
        try:
            texto_completo = []
            
            with pdfplumber.open(pdf_path) as pdf:
                for page in pdf.pages:
                    texto = page.extract_text()
                    if texto:
                        texto_completo.append(texto)
            
            return '\n'.join(texto_completo)
        
        except Exception as e:
            self.log(f"Error con pdfplumber en {pdf_path.name}: {e}", 'WARNING')
            
            # Fallback a PyPDF2
            try:
                texto_completo = []
                with open(pdf_path, 'rb') as file:
                    pdf_reader = PyPDF2.PdfReader(file)
                    for page in pdf_reader.pages:
                        texto = page.extract_text()
                        if texto:
                            texto_completo.append(texto)
                
                return '\n'.join(texto_completo)
            
            except Exception as e2:
                self.log(f"Error con PyPDF2 en {pdf_path.name}: {e2}", 'ERROR')
                return None
    
    def extraer_numero_sentencia(self, texto):
        """Extrae número de sentencia"""
        patterns = [
            r'Sentencia\s+N[°º\.]\s*(\d+)',
            r'Decisión\s+N[°º\.]\s*(\d+)',
            r'Nro\.\s*(\d+)',
            r'N[°º]\s*(\d+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE)
            if match:
                return match.group(1)
        
        return None
    
    def extraer_fecha(self, texto):
        """Extrae fecha de sentencia"""
        patterns = [
            r'(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})',
            r'(\d{1,2})/(\d{1,2})/(\d{4})',
            r'(\d{4})-(\d{1,2})-(\d{1,2})',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE)
            if match:
                return match.group(0)
        
        return None
    
    def extraer_expediente(self, texto):
        """Extrae número de expediente"""
        patterns = [
            r'Expediente\s+N[°º\.]\s*([A-Z0-9\-\.]+)',
            r'Exp\.\s*N[°º\.]\s*([A-Z0-9\-\.]+)',
            r'Exp\.\s*([A-Z0-9\-\.]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE)
            if match:
                return match.group(1).strip()
        
        return None
    
    def extraer_ponente(self, texto):
        """Extrae magistrado ponente"""
        patterns = [
            r'Ponente:\s*(?:Magistrad[oa]\s+)?([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){1,4})',
            r'Magistrad[oa]\s+Ponente:\s*([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){1,4})',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, texto, re.IGNORECASE | re.MULTILINE)
            if match:
                return match.group(1).strip()
        
        return None
    
    def identificar_sala(self, texto, nombre_archivo):
        """Identifica sala del TSJ"""
        texto_lower = texto.lower()
        nombre_lower = nombre_archivo.lower()
        
        # Buscar en nombre de archivo primero
        for codigo, nombre in SALAS.items():
            if codigo in nombre_lower:
                return nombre
        
        # Buscar en contenido
        for codigo, nombre in SALAS.items():
            if nombre.lower() in texto_lower[:500]:  # Primeros 500 chars
                return nombre
        
        return "No especificada"
    
    def extraer_delitos(self, texto):
        """Extrae delitos mencionados"""
        texto_lower = texto.lower()
        delitos_encontrados = []
        
        for delito in DELITOS_VENEZOLANOS:
            if delito in texto_lower:
                if delito not in delitos_encontrados:
                    delitos_encontrados.append(delito.title())
        
        return delitos_encontrados
    
    def extraer_tipo_decision(self, texto):
        """Extrae tipo de decisión"""
        tipos = {
            'Casación': ['casación', 'casa', 'anula', 'anulación'],
            'Amparo': ['amparo', 'tutela'],
            'Apelación': ['apelación', 'apela', 'revoca', 'revocatoria'],
            'Revisión': ['revisión'],
            'Nulidad': ['nulidad', 'declara nulo'],
            'Inadmisible': ['inadmisible', 'inadmisibilidad'],
            'Desistimiento': ['desiste', 'desistimiento'],
        }
        
        texto_lower = texto.lower()
        
        for tipo, palabras in tipos.items():
            if any(palabra in texto_lower for palabra in palabras):
                return tipo
        
        return "No especificado"
    
    def extraer_articulos_citados(self, texto):
        """Extrae artículos legales citados"""
        articulos = set()
        
        patterns = [
            r'art[íi]culo\s+(\d+)[°º\.]?\s+(?:del\s+)?([A-Z][a-záéíóúñ\s]{0,30})',
            r'art\.\s+(\d+)[°º\.]?\s+(?:del\s+)?([A-Z][a-záéíóúñ\s]{0,30})',
        ]
        
        for pattern in patterns:
            matches = re.finditer(pattern, texto, re.IGNORECASE)
            for match in matches:
                articulo = match.group(0).strip()
                if len(articulo) < 100:  # Evitar matches muy largos
                    articulos.add(articulo)
        
        return list(articulos)[:15]  # Limitar a 15 más relevantes
    
    def extraer_partes(self, texto):
        """Extrae partes del proceso"""
        partes = {}
        
        # Acusado/Imputado
        pattern_acusado = r'(?:acusad[oa]|imputad[oa])[:\s]+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){0,3})'
        match = re.search(pattern_acusado, texto, re.IGNORECASE)
        if match:
            partes['acusado'] = match.group(1).strip()
        
        # Víctima
        pattern_victima = r'v[íi]ctima[:\s]+([A-ZÁÉÍÓÚÑ][a-záéíóúñ]+(?:\s+[A-ZÁÉÍÓÚÑ][a-záéíóúñ]+){0,3})'
        match = re.search(pattern_victima, texto, re.IGNORECASE)
        if match:
            partes['victima'] = match.group(1).strip()
        
        return partes
    
    def extraer_extracto(self, texto):
        """Extrae extracto relevante"""
        # Buscar inicio del fallo
        inicio_markers = ['SENTENCIA', 'DECISIÓN', 'FALLO', 'SE ORDENA', 'RESUELVE']
        inicio_pos = -1
        
        texto_upper = texto.upper()
        for marker in inicio_markers:
            pos = texto_upper.find(marker)
            if pos > -1 and (inicio_pos == -1 or pos < inicio_pos):
                inicio_pos = pos
        
        if inicio_pos > -1:
            extracto = texto[inicio_pos:inicio_pos + 1000]
        else:
            # Tomar desde el principio
            extracto = texto[:1000]
        
        return extracto.strip()
    
    def procesar_pdf(self, pdf_path):
        """Procesa un PDF individual y retorna dict con datos estructurados"""
        try:
            self.log(f"Procesando: {pdf_path.name}")
            
            # Extraer texto
            texto = self.extraer_texto_pdf(pdf_path)
            
            if not texto or len(texto) < 100:
                self.log(f"Texto insuficiente en {pdf_path.name}", 'WARNING')
                self.stats['errores'] += 1
                return None
            
            # Extraer metadata
            sentencia = {
                'archivo_original': pdf_path.name,
                'numero': self.extraer_numero_sentencia(texto),
                'fecha': self.extraer_fecha(texto),
                'expediente': self.extraer_expediente(texto),
                'sala': self.identificar_sala(texto, pdf_path.name),
                'ponente': self.extraer_ponente(texto),
                'delitos': self.extraer_delitos(texto),
                'tipo_decision': self.extraer_tipo_decision(texto),
                'partes': self.extraer_partes(texto),
                'articulos_citados': self.extraer_articulos_citados(texto),
                'extracto': self.extraer_extracto(texto),
                'texto_completo': texto,
                'longitud_texto': len(texto),
                'procesado_en': datetime.now().isoformat(),
            }
            
            # Validar datos mínimos
            if not sentencia['numero']:
                self.log(f"No se pudo extraer número de sentencia: {pdf_path.name}", 'WARNING')
                self.stats['sin_metadata'] += 1
            
            self.stats['procesados_ok'] += 1
            return sentencia
        
        except Exception as e:
            self.log(f"Error procesando {pdf_path.name}: {e}", 'ERROR')
            self.stats['errores'] += 1
            return None
    
    def procesar_todos(self):
        """Procesa todos los PDFs en el directorio"""
        self.log(f"Iniciando procesamiento de PDFs en: {self.input_dir}")
        
        # Buscar todos los PDFs
        pdf_files = list(self.input_dir.glob('**/*.pdf'))
        self.stats['total_pdfs'] = len(pdf_files)
        
        if not pdf_files:
            self.log("No se encontraron PDFs", 'ERROR')
            return
        
        self.log(f"Encontrados {len(pdf_files)} archivos PDF")
        
        sentencias_procesadas = []
        
        # Procesar con barra de progreso
        for pdf_path in tqdm(pdf_files, desc="Procesando PDFs"):
            sentencia = self.procesar_pdf(pdf_path)
            if sentencia:
                sentencias_procesadas.append(sentencia)
                
                # Guardar individual
                output_file = self.output_dir / f"{pdf_path.stem}.json"
                with open(output_file, 'w', encoding='utf-8') as f:
                    json.dump(sentencia, f, ensure_ascii=False, indent=2)
        
        # Guardar consolidado
        consolidado_file = self.output_dir / "sentencias_todas.json"
        with open(consolidado_file, 'w', encoding='utf-8') as f:
            json.dump(sentencias_procesadas, f, ensure_ascii=False, indent=2)
        
        self.log(f"Archivo consolidado guardado: {consolidado_file}")
        
        # Guardar log
        with open(LOG_FILE, 'w', encoding='utf-8') as f:
            f.write('\n'.join(self.log_entries))
        
        # Estadísticas finales
        self.imprimir_estadisticas()
    
    def imprimir_estadisticas(self):
        """Imprime estadísticas finales"""
        print("\n" + "="*60)
        print("📊 ESTADÍSTICAS DE PROCESAMIENTO")
        print("="*60)
        print(f"Total PDFs: {self.stats['total_pdfs']}")
        print(f"✅ Procesados correctamente: {self.stats['procesados_ok']}")
        print(f"⚠️  Sin metadata completa: {self.stats['sin_metadata']}")
        print(f"❌ Errores: {self.stats['errores']}")
        
        tasa_exito = (self.stats['procesados_ok'] / self.stats['total_pdfs'] * 100) if self.stats['total_pdfs'] > 0 else 0
        print(f"📈 Tasa de éxito: {tasa_exito:.1f}%")
        print("="*60)


def main():
    """Función principal"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Procesador de PDFs de Jurisprudencia TSJ')
    parser.add_argument('--input', default='pdfs_jurisprudencia', help='Carpeta con PDFs')
    parser.add_argument('--output', default='sentencias_procesadas', help='Carpeta de salida')
    
    args = parser.parse_args()
    
    print("🚀 PROCESADOR DE JURISPRUDENCIA TSJ VENEZUELA")
    print("="*60)
    
    # Verificar que exista carpeta de input
    input_path = Path(args.input)
    if not input_path.exists():
        print(f"❌ ERROR: No existe la carpeta '{args.input}'")
        print(f"📁 Crea la carpeta y coloca los PDFs ahí")
        return
    
    # Procesar
    processor = JurisprudenciaPDFProcessor(args.input, args.output)
    processor.procesar_todos()
    
    print(f"\n✅ Proceso completado")
    print(f"📂 Resultados en: {args.output}/")
    print(f"📄 Log en: {LOG_FILE}")


if __name__ == "__main__":
    main()
