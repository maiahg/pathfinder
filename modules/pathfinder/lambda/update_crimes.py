from commons import constants as c
from services import crime_service
import logging
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    '''
    Lambda function to periodically update crime data in the database.
    '''
    try:
        # fetch latest crimes from source
        crimes = crime_service.get_crimes_from_source(c.CRIME_DATA_SOURCE)
        if not crimes:
            logger.warning("No crimes found from the data source")
            return {"statusCode": 200, "body": json.dumps("No crimes found from the data source")}

        # update/add/delete crimes in the database
        new_counts = crime_service.bucket_by_geohash(crimes, c.GEOHASH_PRECISION)

        existing_items = crime_service.get_all_crime()
        existing_counts = {item['geohash']: int(item['count']) for item in existing_items}

        to_update_or_add = {}
        for gh, count in new_counts.items():
            if gh not in existing_counts or existing_counts[gh] != count:
                to_update_or_add[gh] = count
        
        to_delete = [gh for gh in existing_counts.keys() if gh not in new_counts]

        crime_service.batch_update_crime(to_update_or_add, to_delete)

        return {
            "statusCode": 200,
            "body": json.dumps(
                f"Updated {len(to_update_or_add)} geohashes, deleted {len(to_delete)} geohashes"
            )
        }

    except Exception as e:
        logger.error("Error updating crimes in the database", exc_info=True)
        return {"statusCode": 500, "body": json.dumps(f"Error updating crimes: {e}")}
