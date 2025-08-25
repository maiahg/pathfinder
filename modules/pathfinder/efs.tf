resource "aws_efs_file_system" "valhalla" {
  creation_token = "valhalla-efs"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "valhalla" {
  file_system_id  = aws_efs_file_system.valhalla.id
  subnet_id       = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.valhalla_sg.id]
}