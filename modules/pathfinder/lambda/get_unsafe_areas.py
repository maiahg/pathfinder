from commons import constants as c
from services import crime_service
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    '''
    Lambda function to get unsafe areas from the database.
    '''
    try:
        # preflight response for CORS
        if event.get("httpMethod") == "OPTIONS":
            # Preflight response
            return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin": "*",
                    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                    "Access-Control-Allow-Methods": "GET,OPTIONS"
                },
                "body": ""
        }
        # fetch crimes from the database
        crimes = crime_service.get_all_crimes()
        
        threshold = crime_service.get_threshold(c.PERCENTILE)
        
        areas = []
        for crime in crimes:
            count = float(crime['count'])
            
            if count < threshold:
                continue
            
            polygon = crime_service.geohash_to_polygon(crime['geohash'])
            if polygon[0] != polygon[-1]:
                polygon.append(polygon[0])
                
            areas.append({
                "type": "Feature",
                "geometry": {
                    "type": "Polygon",
                    "coordinates": [polygon]
                }
            })
        
        response_body = {
            "type": "FeatureCollection",
            "features": areas
        }
        
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                "Access-Control-Allow-Methods": "GET,OPTIONS"
            },
            "body": json.dumps(response_body)
        }
    except Exception as e:
        logger.error("Error getting unsafe areas", exc_info=True)
        return {"statusCode": 500, "body": json.dumps(f"Error getting unsafe areas: {e}")}