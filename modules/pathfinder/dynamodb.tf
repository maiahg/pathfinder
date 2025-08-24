resource "aws_dynamodb_table" "ytd_crime_data" {
    name           = "ytd_crime_data"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "geohash"

    attribute {
        name = "geohash"
        type = "S"
    }
    
}