########################################################################################
# Security Group for Valhalla Service
########################################################################################

resource "aws_security_group" "valhalla" {
  name        = "pathfinder-valhalla-sg"
  description = "Allow traffic to Valhalla service"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8002
    to_port     = 8002
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}