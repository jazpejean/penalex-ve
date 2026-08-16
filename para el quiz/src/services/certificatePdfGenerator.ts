import jsPDF from 'jspdf';
import { CertificateData, UserProfile } from '../types';
import { getRankByLevel } from '../data/judicialRanks';

/**
 * Generates an official printable and downloadable Venezuelan Judicial Certificate in PDF format
 */
export function generateCertificatePdf(profile: UserProfile, level: number): CertificateData {
  const rank = getRankByLevel(level);
  const now = new Date();
  const dateFormatted = now.toLocaleDateString('es-VE', {
    day: '2-digit',
    month: 'long',
    year: 'numeric'
  });

  const verificationHash = 'VE-TSJ-' + Math.random().toString(36).substring(2, 8).toUpperCase() + '-' + level;
  const certificateId = 'cert_' + level + '_' + Date.now();

  // Create A4 Landscape PDF (297 x 210 mm)
  const doc = new jsPDF({
    orientation: 'landscape',
    unit: 'mm',
    format: 'a4'
  });

  const width = 297;
  const height = 210;

  // Background: Warm rich parchment
  doc.setFillColor(252, 249, 239);
  doc.rect(0, 0, width, height, 'F');

  // Outer Gold Decorative Border
  doc.setDrawColor(180, 83, 9); // Amber 700
  doc.setLineWidth(3);
  doc.rect(8, 8, width - 16, height - 16);

  // Inner Thin Gold Filigree
  doc.setDrawColor(217, 119, 6); // Amber 600
  doc.setLineWidth(0.8);
  doc.rect(12, 12, width - 24, height - 24);

  // Deep Navy Inner Accent Line
  doc.setDrawColor(15, 23, 42); // Slate 900
  doc.setLineWidth(0.4);
  doc.rect(14, 14, width - 28, height - 28);

  // Header Title
  doc.setFont('times', 'bold');
  doc.setFontSize(11);
  doc.setTextColor(71, 85, 105);
  doc.text('REPÚBLICA BOLIVARIANA DE VENEZUELA', width / 2, 25, { align: 'center' });
  doc.text('PODER JUDICIAL • CIRCUITO JUDICIAL PENAL', width / 2, 30, { align: 'center' });
  doc.text('TRIBUNAL SUPREMO DE JUSTICIA - SALA DE CASACIÓN PENAL', width / 2, 35, { align: 'center' });

  // Seal / Gold Emblem Divider
  doc.setDrawColor(180, 83, 9);
  doc.setLineWidth(1);
  doc.line(width / 2 - 60, 39, width / 2 + 60, 39);

  // Diploma Header
  doc.setFont('times', 'bold');
  doc.setFontSize(26);
  doc.setTextColor(180, 83, 9); // Gold/Amber
  doc.text('CERTIFICADO DE MÉRITO JUDICIAL', width / 2, 54, { align: 'center' });

  doc.setFont('times', 'italic');
  doc.setFontSize(13);
  doc.setTextColor(100, 116, 139);
  doc.text('Se confiere la presente Acreditación de Excelencia y Aptitud Jurídica a:', width / 2, 66, { align: 'center' });

  // Recipient Name
  doc.setFont('times', 'bold');
  doc.setFontSize(28);
  doc.setTextColor(15, 23, 42);
  doc.text(profile.nombre.toUpperCase(), width / 2, 82, { align: 'center' });

  // Underline for name
  doc.setDrawColor(217, 119, 6);
  doc.setLineWidth(0.8);
  const nameWidth = doc.getTextWidth(profile.nombre.toUpperCase());
  doc.line(width / 2 - (nameWidth / 2 + 10), 86, width / 2 + (nameWidth / 2 + 10), 86);

  // Text Body
  doc.setFont('times', 'normal');
  doc.setFontSize(13);
  doc.setTextColor(51, 65, 85);
  const bodyText = `Por haber superado exitosamente el Nivel ${level} de jurisprudencia penal, demostrando riguroso dominio dogmático del Código Penal Venezolano, del Código Orgánico Procesal Penal y precedentes de la Sala de Casación Penal, otorgándosele el rango de honor:`;
  
  const splitText = doc.splitTextToSize(bodyText, 210);
  doc.text(splitText, width / 2, 100, { align: 'center' });

  // Rank Title Box
  doc.setFillColor(254, 243, 199); // Amber 100
  doc.setDrawColor(180, 83, 9);
  doc.setLineWidth(1.2);
  doc.roundedRect(width / 2 - 80, 120, 160, 20, 3, 3, 'FD');

  doc.setFont('times', 'bold');
  doc.setFontSize(18);
  doc.setTextColor(146, 64, 14); // Amber 900
  doc.text(`« ${rank.title.toUpperCase()} »`, width / 2, 133, { align: 'center' });

  // Signatures Section
  const sigY = 168;

  // Left Signature: Magistrado Presidente
  doc.setDrawColor(71, 85, 105);
  doc.setLineWidth(0.5);
  doc.line(45, sigY, 115, sigY);
  doc.setFont('times', 'bold');
  doc.setFontSize(10);
  doc.setTextColor(30, 41, 59);
  doc.text('Dr. Magistrado Presidente', 80, sigY + 5, { align: 'center' });
  doc.setFont('times', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(100, 116, 139);
  doc.text('Sala de Casación Penal del TSJ', 80, sigY + 9, { align: 'center' });

  // Center Seal Text
  doc.setFont('times', 'bold');
  doc.setFontSize(11);
  doc.setTextColor(180, 83, 9);
  doc.text('★ SELLO JUDICIAL ★', width / 2, sigY - 5, { align: 'center' });
  doc.setFontSize(8);
  doc.setTextColor(100, 116, 139);
  doc.text(`Emitido en Caracas, Venezuela`, width / 2, sigY + 2, { align: 'center' });
  doc.text(dateFormatted, width / 2, sigY + 7, { align: 'center' });

  // Right Signature: Secretario de Sala
  doc.setDrawColor(71, 85, 105);
  doc.setLineWidth(0.5);
  doc.line(width - 115, sigY, width - 45, sigY);
  doc.setFont('times', 'bold');
  doc.setFontSize(10);
  doc.setTextColor(30, 41, 59);
  doc.text('Abg. Secretario de Sala', width - 80, sigY + 5, { align: 'center' });
  doc.setFont('times', 'normal');
  doc.setFontSize(9);
  doc.setTextColor(100, 116, 139);
  doc.text('Circuito Judicial Penal', width - 80, sigY + 9, { align: 'center' });

  // Footer Verification Bar
  doc.setFont('courier', 'bold');
  doc.setFontSize(8);
  doc.setTextColor(100, 116, 139);
  doc.text(`CÓDIGO DE VERIFICACIÓN: ${verificationHash}  •  XP ACUMULADA: ${profile.puntos_totales} PTS  •  SISTEMA SUPABASE CLOUD IURISPENAL`, width / 2, height - 12, { align: 'center' });

  // Save / Download PDF
  const filename = `Certificado_Judicial_Nivel_${level}_${profile.nombre.replace(/\s+/g, '_')}.pdf`;
  doc.save(filename);

  return {
    id: certificateId,
    user_id: profile.id,
    nombre: profile.nombre,
    nivel: level,
    rango: rank.title,
    fecha: dateFormatted,
    codigo_verificacion: verificationHash,
    pdf_url: filename
  };
}
