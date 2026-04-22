import 'package:flutter/material.dart';

class PenalexAlert {
  static void show(BuildContext context, {
    required String title, 
    required String message, 
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red.shade900 : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        // CORRECCIÓN: Se usa 'side' dentro de RoundedRectangleBorder para el borde
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFC5A059)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title.toUpperCase(), 
              style: const TextStyle(
                color: Color(0xFFC5A059), 
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 12,
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}