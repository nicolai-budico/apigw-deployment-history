import json


def lambda_handler(event: dict, _):
    return {
        'statusCode': 200,
        'body': json.dumps('v2'),
    }
