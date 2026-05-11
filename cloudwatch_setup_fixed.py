import boto3
import json

cloudwatch = boto3.client('cloudwatch')

# Dashboard con formato correcto
dashboard_body = {
    "widgets": [
        {
            "type": "metric",
            "properties": {
                "metrics": [
                    [ "AWS/EC2", "CPUUtilization" ]
                ],
                "period": 300,
                "stat": "Average",
                "region": "us-east-1",
                "title": "CPU Utilization - EC2",
                "view": "timeSeries"
            }
        },
        {
            "type": "text",
            "properties": {
                "markdown": "# Soluciones Tecnológicas del Futuro\n## Dashboard de Monitoreo DevOps\n\n### Métricas configuradas:\n- CPU de instancias EC2\n- Alarmas activas"
            }
        }
    ]
}

try:
    cloudwatch.put_dashboard(
        DashboardName='Soluciones-Dashboard-V2',
        DashboardBody=json.dumps(dashboard_body)
    )
    print("✅ Dashboard creado correctamente: Soluciones-Dashboard-V2")
except Exception as e:
    print(f"Error: {e}")

# Verificar que la alarma existe
alarms = cloudwatch.describe_alarms(AlarmNames=['CPU-Alta'])
if alarms['MetricAlarms']:
    print(f"✅ Alarma 'CPU-Alta' está activa")
    print(f"   Estado: {alarms['MetricAlarms'][0]['StateValue']}")
