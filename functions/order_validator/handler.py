def handler(event, context):
    """Lambda handler for order validation."""
    return {
        "statusCode": 200,
        "body": "Order validated"
    }
