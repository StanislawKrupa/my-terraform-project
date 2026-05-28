import os
import boto3
import json

ssm = boto3.client('ssm')

def lambda_handler(event, context):
    # Pobieranie nazwy parametru z ze zmiennych środowiskowych wstrzykniętych przez TF
    secret_name = os.environ.get('DB_SECRET_NAME')
    
    # Pobranie sekretu z AWS SSM Parameter Store
    response = ssm.get_parameter(Name=secret_name, WithDecryption=True)
    db_password = response['Parameter']['Value']
    
    # Logika biznesowa (uproszczona)
    print(move_orders_to_db_using_password(db_password))
    
    return {
        'statusCode': 200,
        'body': json.dumps('Order ingested successfully!')
    }

def move_orders_to_db_using_password(password):
    return "Połączono z bazą danych przy użyciu bezpiecznego hasła."