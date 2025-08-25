import json
import httpx
import logging
from commons import secret_manager_helper as smh

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    '''
    Lambda function to calculate the direction between origin and destinations.
    '''
   
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
         
        # get mapbox access token from secret manager
        secret = smh.get_secret()
        secret_dict = json.loads(secret)
        MAPBOX_ACCESS_TOKEN = secret_dict.get("MAPBOX_ACCESS_TOKEN")
                
        body = json.loads(event.get("body", "{}")) if isinstance(event.get("body"), str) else event.get("body", {})
        origin = body.get("origin")
        destinations = body.get("destinations", [])
        profile = body.get("profile", "driving")
        
        if not origin or not destinations:
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "origin and destinations are required"})
            }

        coordinates = f"{origin[0]},{origin[1]}"
        for dest in destinations:
            coordinates += f";{dest[0]},{dest[1]}"
        
        mapbox_url = (
            f"https://api.mapbox.com/directions/v5/mapbox/{profile}/{coordinates}"
            f"?steps=true&geometries=geojson&access_token={MAPBOX_ACCESS_TOKEN}"
        )

        with httpx.Client() as client:
            resp = client.get(mapbox_url)
            data = resp.json()
        
        route = data["routes"][0]["geometry"]
        steps = data["routes"][0]["legs"][0]["steps"]
        
        details = [
            {
                "instruction": step["maneuver"]["instruction"],
                "duration": step["duration"],
                "distance": step["distance"]
            }
            for step in steps
        ]
        
        response_body = {
            "type": "Feature",
            "properties": {},
            "geometry": route,
            "details": details,
            "summary": {
                "path_summary": data["routes"][0]["legs"][0]["summary"],
                "duration": data["routes"][0]["duration"],
                "distance": data["routes"][0]["distance"]
            }
        }

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
