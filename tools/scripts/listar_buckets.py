#!/usr/bin/env python3
"""Ver qué buckets tienes en R2"""
import os
from dotenv import load_dotenv
import boto3
from botocore.config import Config

load_dotenv()

R2_ACCOUNT_ID = os.environ.get('R2_ACCOUNT_ID')
R2_ACCESS_KEY = os.environ.get('R2_ACCESS_KEY_ID')
R2_SECRET_KEY = os.environ.get('R2_SECRET_ACCESS_KEY')

s3 = boto3.client(
    's3',
    endpoint_url=f'https://{R2_ACCOUNT_ID}.r2.cloudflarestorage.com',
    aws_access_key_id=R2_ACCESS_KEY,
    aws_secret_access_key=R2_SECRET_KEY,
    region_name='auto',
    config=Config(signature_version='s3v4')
)

print("📦 Tus buckets de R2:")
response = s3.list_buckets()
for bucket in response['Buckets']:
    print(f"   - {bucket['Name']}")
