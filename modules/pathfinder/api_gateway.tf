########################################################################################
# Define the API Gateway to call the pathfinder endpoints
########################################################################################

resource "aws_api_gateway_rest_api" "rest_api" {
  name        = "pathfinder-api"
  description = "REST API to call the pathfinder endpoints"
}

resource "aws_api_gateway_resource" "rest_api_path_root" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_rest_api.rest_api.root_resource_id
  path_part   = "pathfinder-api"
}

resource "aws_api_gateway_deployment" "rest_api" {
  depends_on = [
    aws_api_gateway_integration.get_unsafe_areas,
    aws_api_gateway_integration.get_direction,
    aws_api_gateway_integration.get_safe_direction
  ]
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.rest_api.id
  stage_name    = "prod"
  depends_on    = [aws_cloudwatch_log_group.api_gateway]

  lifecycle {
    create_before_destroy = true
  }
}

########################################################################################
# API Gateway endpoint to get unsafe areas
########################################################################################

resource "aws_api_gateway_resource" "get_unsafe_areas" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_path_root.id
  path_part   = "get-unsafe-areas"
}

resource "aws_api_gateway_method" "get_unsafe_areas" {
  rest_api_id      = aws_api_gateway_rest_api.rest_api.id
  resource_id      = aws_api_gateway_resource.get_unsafe_areas.id
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "get_unsafe_areas" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_unsafe_areas.id
  http_method = aws_api_gateway_method.get_unsafe_areas.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_unsafe_areas.invoke_arn
}

resource "aws_api_gateway_method_response" "get_unsafe_areas" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_unsafe_areas.id
  http_method = aws_api_gateway_method.get_unsafe_areas.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration_response" "get_unsafe_areas" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_unsafe_areas.id
  http_method = aws_api_gateway_method.get_unsafe_areas.http_method
  status_code = aws_api_gateway_method_response.get_unsafe_areas.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET'"
  }

  depends_on = [aws_api_gateway_integration.get_unsafe_areas]
}

resource "aws_api_gateway_method" "get_unsafe_areas_any" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_unsafe_areas.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_unsafe_areas_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_unsafe_areas.id
  http_method = aws_api_gateway_method.get_unsafe_areas_any.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "get_unsafe_areas_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_unsafe_areas.id
  http_method = aws_api_gateway_method.get_unsafe_areas_any.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "get_unsafe_areas_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_unsafe_areas.id
  http_method = aws_api_gateway_method.get_unsafe_areas_any.http_method
  status_code = aws_api_gateway_method_response.get_unsafe_areas_any.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.get_unsafe_areas]
}

########################################################################################
# API Gateway endpoint to get direction
########################################################################################

resource "aws_api_gateway_resource" "get_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_path_root.id
  path_part   = "get-direction"
}

resource "aws_api_gateway_method" "get_direction" {
  rest_api_id      = aws_api_gateway_rest_api.rest_api.id
  resource_id      = aws_api_gateway_resource.get_direction.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "get_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_direction.id
  http_method = aws_api_gateway_method.get_direction.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_direction.invoke_arn
}

resource "aws_api_gateway_method_response" "get_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_direction.id
  http_method = aws_api_gateway_method.get_direction.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }

  depends_on = [aws_api_gateway_integration.get_direction]
}

resource "aws_api_gateway_integration_response" "get_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_direction.id
  http_method = aws_api_gateway_method.get_direction.http_method
  status_code = aws_api_gateway_method_response.get_direction.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }

  depends_on = [aws_api_gateway_integration.get_direction]
}

resource "aws_api_gateway_method" "get_direction_any" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_direction.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_direction_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_direction.id
  http_method = aws_api_gateway_method.get_direction_any.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "get_direction_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_direction.id
  http_method = aws_api_gateway_method.get_direction_any.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "get_direction_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_direction.id
  http_method = aws_api_gateway_method.get_direction_any.http_method
  status_code = aws_api_gateway_method_response.get_direction_any.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  response_templates = {
    "application/json" = "{\"statusCode\":200}"
  }

  depends_on = [aws_api_gateway_integration.get_direction]
}

############################################
# API Gateway endpoint to get safe direction
############################################


resource "aws_api_gateway_resource" "get_safe_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  parent_id   = aws_api_gateway_resource.rest_api_path_root.id
  path_part   = "get-safe-direction"
}

resource "aws_api_gateway_method" "get_safe_direction" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_safe_direction.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "get_safe_direction" {
  rest_api_id             = aws_api_gateway_rest_api.rest_api.id
  resource_id             = aws_api_gateway_resource.get_safe_direction.id
  http_method             = aws_api_gateway_method.get_safe_direction.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_safe_direction.invoke_arn
}

resource "aws_api_gateway_method_response" "get_safe_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_safe_direction.id
  http_method = aws_api_gateway_method.get_safe_direction.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

resource "aws_api_gateway_integration_response" "get_safe_direction" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_safe_direction.id
  http_method = aws_api_gateway_method.get_safe_direction.http_method
  status_code = aws_api_gateway_method_response.get_safe_direction.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
  }

  depends_on = [aws_api_gateway_integration.get_safe_direction]
}

resource "aws_api_gateway_method" "get_safe_direction_any" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  resource_id   = aws_api_gateway_resource.get_safe_direction.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_safe_direction_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_safe_direction.id
  http_method = aws_api_gateway_method.get_safe_direction_any.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "get_safe_direction_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_safe_direction.id
  http_method = aws_api_gateway_method.get_safe_direction_any.http_method
  status_code = "200"


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "get_safe_direction_any" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id
  resource_id = aws_api_gateway_resource.get_safe_direction.id
  http_method = aws_api_gateway_method.get_safe_direction_any.http_method
  status_code = aws_api_gateway_method_response.get_safe_direction_any.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.get_safe_direction]
}
