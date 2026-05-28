def handler(event, context):
    """Lambda handler for order processing."""
    return {
        "statusCode": 200,
        "body": "Order processed"
    }
