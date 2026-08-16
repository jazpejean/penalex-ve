# ⚠️ FALTA INSTALAR python3-venv

Tu sistema necesita `python3-venv` para crear entornos virtuales.

## 🔧 SOLUCIÓN:

```bash
sudo apt install python3.12-venv
```

Después ejecuta:

```bash
cd ~/Desktop/Penalex_VE
python3 -m venv venv
source venv/bin/activate
pip install supabase boto3 python-dotenv
python auditoria_completa_local.py
```

---

## 🚀 ALTERNATIVA RÁPIDA (Sin instalar nada en tu sistema)

**USA GOOGLE COLAB** - No necesitas instalar nada localmente:

1. Ve a: https://colab.research.google.com/
2. Click **"File" → "Upload notebook"**
3. Sube: `auditoria_completa_colab.ipynb`
4. Click en 🔑 (Secrets, panel izquierdo)
5. Agrega estos secretos:

```
SUPABASE_URL
https://efxzcglhyosrxtafirhs.supabase.co

SUPABASE_ANON_KEY
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmeHpjZ2xoeW9zcnh0YWZpcmhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODY0MDMxODgsImV4cCI6MjEwMTk3OTE4OH0.LYkvBjiO1l11hnRZsYIuFf2ZaQ3ShP9sU43HYB5l4_0

R2_ACCOUNT_ID
9245781c2bca24b4c7e868111ef122f7

R2_ACCESS_KEY_ID
fd9654d548ad8692fd6fb1b68425a6a0

R2_SECRET_ACCESS_KEY
a525df5776ee9433c96f73c73a238826ceeafd1681ef4433849fe1d846e518b32
```

6. **Runtime → Run all**

**¡Listo en 5 minutos!** 🎉

---

## ¿Qué Prefieres?

**Opción A:** Instalar python3-venv (requiere sudo)
**Opción B:** Usar Google Colab (más rápido, sin instalar nada)

Te recomiendo **Opción B (Colab)** para ver resultados inmediatamente.
