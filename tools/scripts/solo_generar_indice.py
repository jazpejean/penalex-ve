#!/usr/bin/env python3
"""Solo genera índices, NO procesa archivos"""
import os
import sys
from dotenv import load_dotenv
import boto3
from botocore.config import Config

load_dotenv()

R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID') or os.environ.get('CLOUDFLARE_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')
R2_BUCKET = os.environ.get('R2_BUCKET_NAME', 'penalex-ve')
R2_PUBLIC_URL = os.environ.get('R2_PUBLIC_URL', 'https://pub-a6e0bfa2e9174e91b031ae28c0667009.r2.dev')

s3 = boto3.client(
    's3',
    endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
    aws_access_key_id=R2_ACCESS_KEY,
    aws_secret_access_key=R2_SECRET_KEY,
    region_name='auto',
    config=Config(signature_version='s3v4')
)

print("📋 Generando índice de HTML...")
html_dict = {}
token = None
while True:
    kwargs = {'Bucket': R2_BUCKET, 'Prefix': 'html/'}
    if token: kwargs['ContinuationToken'] = token
    resp = s3.list_objects_v2(**kwargs)
    if 'Contents' in resp:
        for obj in resp['Contents']:
            k = obj['Key']
            if k.lower().endswith('.html'):
                doc_id = k.replace('html/', '').replace('.html', '').replace('.HTML', '')
                html_dict[doc_id] = f"{R2_PUBLIC_URL}/{k}"
    print(f"   {len(html_dict):,} archivos", end='\r')
    if not resp.get('IsTruncated'): break
    token = resp.get('NextContinuationToken')

print(f"\n✅ HTML: {len(html_dict):,}")

print("📋 Generando índice de TXT...")
txt_dict = {}
token = None
while True:
    kwargs = {'Bucket': R2_BUCKET, 'Prefix': 'txt/'}
    if token: kwargs['ContinuationToken'] = token
    resp = s3.list_objects_v2(**kwargs)
    if 'Contents' in resp:
        for obj in resp['Contents']:
            k = obj['Key']
            if k.lower().endswith('.txt'):
                doc_id = k.replace('txt/', '').replace('.txt', '').replace('.TXT', '')
                txt_dict[doc_id] = f"{R2_PUBLIC_URL}/{k}"
    print(f"   {len(txt_dict):,} archivos", end='\r')
    if not resp.get('IsTruncated'): break
    token = resp.get('NextContinuationToken')

print(f"\n✅ TXT: {len(txt_dict):,}")

all_ids = sorted(set(html_dict.keys()) | set(txt_dict.keys()))

with open('indice_completo.csv', 'w') as f:
    f.write("id,url_html,url_txt\n")
    for doc_id in all_ids:
        f.write(f"{doc_id},{html_dict.get(doc_id,'')},{txt_dict.get(doc_id,'')}\n")

print(f"💾 indice_completo.csv: {len(all_ids):,} documentos")
