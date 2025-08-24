from botocore.exceptions import ClientError
from commons import dynamodb_helper as dbh, constants as c
import logging
import numpy as np
import geohash
from collections import defaultdict
from decimal import Decimal
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def get_all_crimes():
    try:
        crime_table = dbh.get_ytd_crime_data_table()
        response = crime_table.scan()
        return response['Items']
    except ClientError as e:
        logger.error("Error getting all crime data", exc_info=True)
        raise e

def get_crime(geohash):
    try:
        crime_table = dbh.get_ytd_crime_data_table()
        response = crime_table.get_item(Key={'geohash': geohash})
        return response['Item']
    except ClientError as e:
        logger.error(f"Error getting crime data for geohash: {geohash}", exc_info=True)
        raise e


def batch_add_crimes(crimes):
    try:
        crime_table = dbh.get_ytd_crime_data_table()
        with crime_table.batch_writer() as batch:
            for gh, count in crimes.items():
                batch.put_item(Item={'geohash': gh, 'count': Decimal(count)})
    except ClientError as e:
        logger.error("Error adding crime data", exc_info=True)
        raise e

def batch_update_crimes(to_update_and_add, to_delete):
    try:
        crime_table = dbh.get_ytd_crime_data_table()
        with crime_table.batch_writer() as batch:
            for gh in to_delete:
                batch.delete_item(Key={'geohash': gh})
            for gh, count in to_update_and_add.items():
                batch.put_item(Item={'geohash': gh, 'count': Decimal(count)})

    except ClientError as e:
        logger.error("Error batch updating crime data", exc_info=True)
        raise e

def delete_all_crimes():
    try:
        crime_table = dbh.get_ytd_crime_data_table()
        response = crime_table.scan()
        with crime_table.batch_writer() as batch:
            for item in response['Items']:
                batch.delete_item(Key={'geohash': item['geohash']})
    except ClientError as e:
        logger.error("Error deleting all crime data", exc_info=True)
        raise e

def get_crimes_from_source(source):
    try:
        resp = requests.get(source)
        resp.raise_for_status()
        data = resp.json()
        crimes = data.get("features", [])
        return crimes
    except ClientError as e:
        logger.error("Error getting crimes from source", exc_info=True)
        raise e

def bucket_by_geohash(data, precision):
    counts = {}
    for crime in data:
        attr = crime.get("attributes", {})

        lon, lat = attr.get("LONG_WGS84"), attr.get("LAT_WGS84")
        if lon is None or lat is None or lon == 0 or lat == 0:
            continue

        gh = geohash.encode(lat, lon, precision=precision)
        counts[gh] = counts.get(gh, 0) + 1

    return counts

def get_threshold(percentile):
    crimes = get_all_crimes()
    crime_counts = [float(crime['count']) for crime in crimes]
    return np.percentile(crime_counts, percentile)  

def get_excluded_polygons(targeted_gh):
    crimes = get_all_crimes()
    threshold = get_threshold(c.PERCENTILE)
    
    polygons = []
    for crime in crimes:
        count = float(crime['count'])
        crime_geohash = crime['geohash']
        
        if count < threshold or crime_geohash[:c.GEOHASH_LIMIT] not in targeted_gh:
            continue
        
        polygon = geohash_to_polygon(crime_geohash)
        polygons.append(polygon)
    
    return polygons

def decode_polyline6(polyline):
    index, lat, lon, coordinates = 0, 0, 0, []
    changes = {'lat': 0, 'lon': 0}

    while index < len(polyline):
        for unit in ['lat', 'lon']:
            shift, result = 0, 0
            while True:
                b = ord(polyline[index]) - 63
                index += 1
                result |= (b & 0x1f) << shift
                shift += 5
                if b < 0x20:
                    break
            if result & 1:
                changes[unit] = ~(result >> 1)
            else:
                changes[unit] = (result >> 1)

        lat += changes['lat']
        lon += changes['lon']
        coordinates.append([lon / 1e6, lat / 1e6])

    return coordinates

def map_valhalla_to_directions_response(data):
    trip = data["trip"]

    details = []
    street_distances = defaultdict(float)

    for leg in trip["legs"]:
        for step in leg["maneuvers"]:
            street_name = step.get("street_names", [""])[0] if step.get("street_names") else ""
            
            details.append({
                "instruction": step["instruction"],
                "duration": step.get("time", 0),
                "distance": step.get("length", 0),
                "street": street_name
            })

            if street_name:
                street_distances[street_name] += step.get("length", 0)

    # decode the full route shape
    coordinates = []
    for leg in trip["legs"]:
        coordinates.extend(decode_polyline6(leg["shape"]))

    # find top 2 streets by total length
    top_streets = sorted(street_distances.items(), key=lambda x: x[1], reverse=True)[:2]
    top_street_names = [street for street, _ in top_streets]

    # build GeoJSON response
    response = {
        "type": "Feature",
        "properties": {},
        "geometry": {
            "type": "LineString",
            "coordinates": coordinates
        },
        "details": details,
        "summary": {
            "path_summary": ", ".join(top_street_names) if top_street_names else "No street info",
            "duration": trip["summary"]["time"],
            "distance": trip["summary"]["length"]
        }
    }

    return response

def geohash_to_polygon(gh):
    box = geohash.bbox(gh)    
    return [[box['e'], box['n']], [box['w'], box['n']], [box['w'], box['s']], [box['e'], box['s']]]