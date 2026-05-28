import os
import boto3
from moto import mock_ssm
from order_ingest.handler import lambda_handler

@mock_ssm
def test_lambda_handler_with_mocked_ssm():
    # 1. Przygotowanie mockowanego środowiska SSM
    param_name = "/myapp/db_password"
    os.environ['DB_SECRET_NAME'] = param_name
    
    client = boto3.client('ssm', region_name='us-east-1')
    client.put_parameter(
        Name=param_name,
        Value="super_secret_password_123",
        Type="SecureString"
    )

    # 2. Wywołanie funkcji
    event = {}
    context = None
    response = lambda_handler(event, context)

    # 3. Asercja
    assert response['statusCode'] == 200