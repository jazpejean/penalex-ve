import 'package:flutter/material.dart';

DateTime? parseFecha(String texto) {
  try {
    final List<String> partes = texto.split('/');
    if (partes.length != 3) return null;
    final int? dia = int.tryParse(partes[0]);
    final int? mes = int.tryParse(partes[1]);
    final int? anio = int.tryParse(partes[2]);
    if (dia == null || mes == null || anio == null) return null;
    return DateTime(anio, mes, dia);
  } on Exception catch (_) {
    return null;
  }
}

TimeOfDay? parseHora(String texto) {
  try {
    final String horaLimpia = texto.replaceAll(' ', '').toLowerCase();
    
    if (horaLimpia.length < 4) return null;
    
    int hora;
    int minuto;
    
    if (horaLimpia.length == 4) {
      hora = int.tryParse(horaLimpia.substring(0, 2)) ?? 0;
      minuto = int.tryParse(horaLimpia.substring(2, 4)) ?? 0;
    } else if (horaLimpia.length == 5) {
      hora = int.tryParse(horaLimpia.substring(0, 1)) ?? 0;
      minuto = int.tryParse(horaLimpia.substring(1, 3)) ?? 0;
    } else {
      return null;
    }
    
    if (hora < 12 && !horaLimpia.contains('am') && !horaLimpia.contains('pm')) {
      hora += 12;
    } else if (horaLimpia.contains('am') && hora == 12) {
      hora = 0;
    } else if (horaLimpia.contains('pm') && hora != 12) {
      hora += 12;
    }
    
    if (hora >= 0 && hora < 24 && minuto >= 0 && minuto < 60) {
      return TimeOfDay(hour: hora, minute: minuto);
    }
    return null;
  } on Exception catch (_) {
    return null;
  }
}