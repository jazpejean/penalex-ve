#!/bin/bash
# Esto guarda TODA la conversación con el asistente en un archivo con fecha

LOGFILE="chat_log_$(date +%Y%m%d_%H%M%S).txt"

echo "===== INICIO DE SESIÓN =====" > "$LOGFILE"
echo "Fecha: $(date)" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Aquí ejecutas el agente y rediriges todo a stdout y al log
node agente.js 2>&1 | tee -a "$LOGFILE"

echo "" >> "$LOGFILE"
echo "===== FIN DE SESIÓN =====" >> "$LOGFILE"
echo "📁 Log guardado en: $LOGFILE"
