import boto3
from datetime import datetime

ec2 = boto3.client('ec2')

print("\n" + "="*60)
print(f"REPORTE DE RECURSOS AWS - {datetime.now().strftime('%Y-%m-%d %H:%M')}")
print("="*60)

response = ec2.describe_instances()
total = 0

for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        total += 1
        print(f"\n🖥️  {instance['InstanceId']}")
        print(f"   Estado: {instance['State']['Name']}")
        print(f"   Tipo: {instance['InstanceType']}")

print(f"\n📊 TOTAL INSTANCIAS: {total}")
print("="*60 + "\n")
