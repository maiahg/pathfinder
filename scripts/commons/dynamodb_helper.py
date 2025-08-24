import boto3

db_resource = boto3.resource('dynamodb')
db_client = boto3.client('dynamodb')

def get_ytd_crime_data_table():
    return db_resource.Table('ytd_crime_data')