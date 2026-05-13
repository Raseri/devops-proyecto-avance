import boto3
from datetime import datetime

# Cliente EC2
ec2 = boto3.client('ec2')

# Obtener información
response = ec2.describe_instances()

# Contadores
total_instances = 0
running = 0
stopped = 0

# Encabezado
print("\n" + "═" * 80)
print("🚀 REPORTE AVANZADO DE INFRAESTRUCTURA AWS")
print(f"📅 Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
print("═" * 80)

# Recorrer instancias
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        
        total_instances += 1
        
        instance_id = instance.get('InstanceId', 'N/A')
        instance_type = instance.get('InstanceType', 'N/A')
        state = instance['State']['Name']
        az = instance['Placement']['AvailabilityZone']
        launch_time = instance['LaunchTime']
        
        public_ip = instance.get('PublicIpAddress', 'Sin IP pública')
        private_ip = instance.get('PrivateIpAddress', 'Sin IP privada')
        
        # Nombre de la instancia
        name = "Sin Nombre"
        if 'Tags' in instance:
            for tag in instance['Tags']:
                if tag['Key'] == 'Name':
                    name = tag['Value']

        # Contadores de estado
        if state == "running":
            running += 1
            status_icon = "🟢"
        elif state == "stopped":
            stopped += 1
            status_icon = "🔴"
        else:
            status_icon = "🟡"

        # Mostrar información
        print("\n" + "─" * 80)
        print(f"🖥️  INSTANCIA: {name}")
        print("─" * 80)
        print(f"🆔 ID                : {instance_id}")
        print(f"{status_icon} Estado           : {state}")
        print(f"⚙️ Tipo              : {instance_type}")
        print(f"🌎 Zona              : {az}")
        print(f"🌐 IP Pública        : {public_ip}")
        print(f"🔒 IP Privada        : {private_ip}")
        print(f"🕒 Lanzamiento       : {launch_time}")

# Resumen final
print("\n" + "═" * 80)
print("📊 RESUMEN GENERAL")
print("═" * 80)
print(f"🖥️  Total Instancias : {total_instances}")
print(f"🟢 En ejecución      : {running}")
print(f"🔴 Detenidas         : {stopped}")
print("═" * 80 + "\n")
