resource "aws_efs_file_system" "valhalla" {
  creation_token = "valhalla-efs"
  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
}

resource "aws_efs_mount_target" "valhalla" {
  file_system_id  = aws_efs_file_system.valhalla.id
  for_each        = toset(data.aws_subnets.default.ids)
  subnet_id       = each.value
  security_groups = [aws_security_group.valhalla.id]
}