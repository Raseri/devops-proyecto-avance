import json
import random
import datetime

def lambda_handler(event, context):
    messages = [
        "✅ Despliegue exitoso",
        "📊 Monitoreo activo", 
        "🔒 Seguridad OK"
    ]
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'mensaje': random.choice(messages),
            'timestamp': str(datetime.datetime.now())
        })
    }
