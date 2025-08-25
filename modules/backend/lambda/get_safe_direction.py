import logging
import json
import geohash
import httpx
from commons import constants as c
from services import crime_service
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    '''
    Lambda function to get the safe direction between origin and destinations.
    '''
    VALHALLA_ENDPOINT = os.getenv("VALHALLA_ENDPOINT")
    try:
        # preflight response for CORS
        if event.get("httpMethod") == "OPTIONS":
                return {
                    "statusCode": 200,
                    "headers": {
                        "Access-Control-Allow-Origin": "*",
                        "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                        "Access-Control-Allow-Methods": "POST,OPTIONS"
                    },
                    "body": ""
        }
                
        body = json.loads(event.get("body", "{}")) if isinstance(event.get("body"), str) else event.get("body", {})
        origin = body.get("origin")
        destinations = body.get("destinations", [])
        profile = body.get("profile", "driving")
        
        if not origin or not destinations:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "origin and destinations are required"})
            }
        
        geohashes = []
        geohashes.append(geohash.encode(origin[1], origin[0], c.GEOHASH_LIMIT))
        for destination in destinations:
            geohashes.append(geohash.encode(destination[1], destination[0], c.GEOHASH_LIMIT))
        
        excluded_polygons = crime_service.get_excluded_polygons(geohashes)
        
        if excluded_polygons is None:
            excluded_polygons = []
        
        if profile == "driving":
            costing = "auto"
        elif profile == "walking":
            costing = "pedestrian"
        elif profile == "cycling":
            costing = "bicycle"
        else:
            raise ValueError(f"Invalid profile: {profile}")
        
        
        request_body = {
            "locations": [{"lat": origin[1], "lon": origin[0]}] + [
                {"lat": d[1], "lon": d[0]} for d in destinations
            ],
            "costing": costing,
            "exclude_polygons": excluded_polygons,
            "units": "kilometers"
        }
        
        with httpx.Client() as client:
            resp = client.post(VALHALLA_ENDPOINT, json=request_body)
            data = resp.json()

        response_body = crime_service.map_valhalla_to_directions_response(data)

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
                "Access-Control-Allow-Methods": "POST,OPTIONS"
            },
            "body": json.dumps(response_body)
        }
    except Exception as e:
        logger.error("Error getting direction", exc_info=True)
        return {"statusCode": 500, "body": json.dumps(f"Error getting getting direction: {e}")}