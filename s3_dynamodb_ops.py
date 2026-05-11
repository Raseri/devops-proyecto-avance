import boto3
import uuid

s3 = boto3.client('s3')

print("\n" + "="*50)
print("OPERACIONES CON S3")
print("="*50)

bucket = f"mi-bucket-{uuid.uuid4().hex[:8]}"
print(f"\n📦 Creando bucket: {bucket}")

try:
    s3.create_bucket(Bucket=bucket)
    print(f"   ✅ Bucket creado")
    
    s3.put_object(Bucket=bucket, Key="test.txt", Body=b"Hola DevOps!")
    print(f"   ✅ Archivo test.txt subido")
    
    print(f"\n✅ Operaciones S3 completadas")
except Exception as e:
    print(f"   ⚠️ Error: {e}")
