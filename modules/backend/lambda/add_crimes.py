from commons import constants as c
from services import crime_service
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    '''
    Lambda function to fetch crimes from the source and add them to the database.
    '''
    try:
        # fetch crimes from the source
        crimes = crime_service.get_crimes_from_source(c.CRIME_DATA_SOURCE)
        
        if not crimes:
            logger.warning("No crimes found from the data source")
            return {"statusCode": 200, "body": json.dumps("No crimes found from the data source")}
        
        # bucket crimes by geohash
        crimes_by_geohash = crime_service.bucket_by_geohash(crimes, c.GEOHASH_PRECISION)
        
        # add crimes to the database
        crime_service.batch_add_crimes(crimes_by_geohash)
        
        return {"statusCode": 200, "body": json.dumps(f"Added {len(crimes_by_geohash)} crimes to the database")}
    except Exception as e:
        logger.error("Error adding crimes to the database", exc_info=True)
        return {"statusCode": 500, "body": json.dumps(f"Error adding crimes to the database: {e}")}