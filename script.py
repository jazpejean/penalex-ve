name: Procesar y Publicar Sentencias TSJ

on:
  workflow_dispatch:
    inputs:
      limite:
        description: 'Número de archivos a procesar (0 = todos)'
        required: false
        default: '0'
      lote:
        description: 'Publicar cada N archivos (ej: 1, 5, 10)'
        required: false
        default: '10'

jobs:
  procesar:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout código
        uses: actions/checkout@v4

      - name: Configurar Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Instalar dependencias
        run: |
          pip install -r requirements.txt
          npm install -g firebase-tools

      - name: Configurar credenciales de Google
        env:
          CREDS_JSON: ${{ secrets.GOOGLE_APPLICATION_CREDENTIALS_JSON }}
        run: |
          # Validar que el JSON sea válido
          echo "${CREDS_JSON}" > /tmp/creds.json
          python -c "import json; json.load(open('/tmp/creds.json')); print('✅ JSON válido')"
          echo "GOOGLE_APPLICATION_CREDENTIALS_JSON=${CREDS_JSON}" >> $GITHUB_ENV

      - name: Cache progreso
        uses: actions/cache@v3
        with:
          path: /content/progreso.json
          key: progreso-${{ github.run_id }}
          restore-keys: |
            progreso-

      - name: Ejecutar script
        env:
          FIREBASE_TOKEN: ${{ secrets.FIREBASE_TOKEN }}
          LIMITE: ${{ github.event.inputs.limite || '0' }}
          LOTE: ${{ github.event.inputs.lote || '10' }}
        run: python script.py
