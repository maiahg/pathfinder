resource "aws_ecs_cluster" "valhalla" {
  name = "valhalla-cluster"
}

resource "aws_ecs_task_definition" "valhalla" {
  family                   = "valhalla-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"   # 1 vCPU
  memory                   = "2048"   # 2GB
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  container_definitions = jsonencode([
    {
      name      = "valhalla"
      image     = "ghcr.io/valhalla/valhalla-scripted:latest"
      essential = true
      portMappings = [{
        containerPort = 8002
        hostPort      = 8002
        protocol      = "tcp"
      }]
      mountPoints = [{
        sourceVolume  = "valhalla-efs"
        containerPath = "/custom_files"
        readOnly      = false
      }]
      environment = [
        {
          name  = "tile_urls"
          value = "https://download.geofabrik.de/north-america/canada-latest.osm.pbf"
        }
      ]
    }
  ])

  volume {
    name = "valhalla-efs"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.valhalla.id
      transit_encryption = "ENABLED"
    }
  }
}

resource "aws_ecs_service" "valhalla" {
  name            = "valhalla-service"
  cluster         = aws_ecs_cluster.valhalla.id
  task_definition = aws_ecs_task_definition.valhalla.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.valhalla.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_efs_mount_target.valhalla
  ]
}