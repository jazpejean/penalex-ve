#!/usr/bin/env python3
import sys
print("Python OK")
print(f"Version: {sys.version}")

try:
    import requests
    print("requests: OK")
except:
    print("requests: FALTA")

try:
    import PyPDF2
    print("PyPDF2: OK")
except:
    print("PyPDF2: FALTA")
