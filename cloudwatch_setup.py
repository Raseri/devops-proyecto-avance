import boto3
import json

cloudwatch = boto3.client('cloudwatch')

print("\n" + "="*50)
print("CONFIGURANDO CLOUDWATCH")
print("="*50)

# Crear alarma
try:
    cloudwatch.put_metric_alarm(
        AlarmName='CPU-Alta',
        ComparisonOperator='GreaterThanThreshold',
        EvaluationPeriods=2,
        MetricName='CPUUtilization',
        Namespace='AWS/EC2',
        Period=300,
        Statistic='Average',
        Threshold=80.0,
        ActionsEnabled=False
    )
    print("\n🚨 Alarma creada: CPU-Alta")
except Exception as e:
    print(f"   Error alarma: {e}")

# Crear dashboard
dashboard = {
    "widgets": [{
        "type": "metric",
        "properties": {
            "metrics": [["AWS/EC2", "CPUUtilization"]],
            "title": "CPU de EC2"
        }
    }]
}

try:
    cloudwatch.put_dashboard(
        DashboardName='MiDashboard',
        DashboardBody=json.dumps(dashboard)
    )
    print("📈 Dashboard creado: MiDashboard")
except Exception as e:
    print(f"   Error dashboard: {e}")

print("\n✅ Configuracion completada\n")
