import json
import random
import datetime

def lambda_handler(event, context):
    mensajes = [
        "✅ Despliegue exitoso",
        "📊 Monitoreo activo",
        "🔒 Seguridad OK"
    ]
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'mensaje': random.choice(mensajes),
            'timestamp': str(datetime.datetime.now())
        })
    }
