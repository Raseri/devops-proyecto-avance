import boto3

ec2 = boto3.client('ec2')
response = ec2.describe_instances()

print("\n" + "="*50)
print("INSTANCIAS EC2 EN ESTA CUENTA")
print("="*50)

instancias = 0
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        instancias += 1
        nombre = "Sin nombre"
        for tag in instance.get('Tags', []):
            if tag['Key'] == 'Name':
                nombre = tag['Value']
        
        print(f"\n📌 {nombre}")
        print(f"   ID: {instance['InstanceId']}")
        print(f"   Estado: {instance['State']['Name']}")

if instancias == 0:
    print("\n⚠️ No hay instancias EC2 activas\n")
else:
    print(f"\n📊 TOTAL: {instancias}\n")
