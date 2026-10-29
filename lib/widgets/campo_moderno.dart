import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_colors.dart';
import '../config/app_theme.dart';

/// Campo de formulario moderno de Penalex (icono dorado a12, fondo
/// superficie, bordes redondeados 12). Usado por los formularios de la
/// agenda (audiencia, día sin despacho) y cualquier otro formulario.
class CampoModerno extends StatelessWidget {
  const CampoModerno(
    this.controller,
    this.label,
    this.icon, {
    super.key,
    this.numeric = false,
    this.isDate = false,
    this.isTime = false,
    this.maxLines = 1,
    this.hint,
    this.onTap,
    this.esObligatorio = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool numeric;
  final bool isDate;
  final bool isTime;
  final int maxLines;
  final String? hint;
  final VoidCallback? onTap;
  final bool esObligatorio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        readOnly: onTap != null,
        onTap: onTap,
        keyboardType: (numeric || isDate || isTime)
            ? TextInputType.number
            : TextInputType.text,
        inputFormatters: <TextInputFormatter>[
          if (isDate) DateMaskFormatter(),
          if (isTime) TimeMaskFormatter(),
          if (numeric && !isDate && !isTime)
            FilteringTextInputFormatter.digitsOnly,
        ],
        style: TextStyle(fontSize: 15, color: TemaGlobal.texto),
        decoration: InputDecoration(
          labelText: esObligatorio ? '$label *' : label,
          hintText: hint,
          hintStyle: TextStyle(color: TemaGlobal.textoTenue, fontSize: 13),
          labelStyle: TextStyle(
              color: TemaGlobal.textoSecundario, fontSize: 13.5),
          prefixIcon: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: TemaGlobal.dorado.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.acento, size: 20),
          ),
          filled: true,
          fillColor: TemaGlobal.superficie,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: TemaGlobal.textoTenue.withValues(alpha: 0.25)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.acento, width: 1.4),
          ),
        ),
      ),
    );
  }
}

/// Máscara de fecha DD/MM/AAAA (solo dígitos + barras automáticas).
class DateMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write('/');
    }
    return TextEditingValue(
        text: buffer.toString(),
        selection:
            TextSelection.collapsed(offset: buffer.toString().length));
  }
}

/// Máscara de hora HH:MM con periodo AM/PM inferido (igual que la agenda).
class TimeMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    String digits = newValue.text.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > 4) digits = digits.substring(0, 4);
    if (digits.isEmpty) return TextEditingValue.empty;
    String formatted = '';
    if (digits.isNotEmpty) formatted += digits[0];
    if (digits.length >= 2) formatted += digits[1];
    String period = '';
    if (digits.length >= 2) {
      final int hour = int.tryParse(digits.substring(0, 2)) ?? 0;
      if (hour >= 7 && hour <= 11) {
        period = ' AM';
      } else if (hour == 12 || (hour >= 1 && hour <= 6)) {
        period = ' PM';
      } else {
        period = ' AM';
      }
    }
    if (digits.length >= 3) formatted += ':${digits[2]}';
    if (digits.length >= 4) formatted += digits[3];
    return TextEditingValue(
        text: formatted + period,
        selection: TextSelection.collapsed(offset: formatted.length));
  }
}