resource "aws_datasync_location_s3" "s3_location" {
  s3_bucket_arn = aws_s3_bucket.custom_files.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync.arn
  }
}

resource "aws_datasync_location_efs" "efs_location" {
  efs_file_system_arn = aws_efs_file_system.valhalla.arn
  subdirectory        = "/"

  ec2_config {
    security_group_arns = [aws_security_group.valhalla_sg.arn]
    subnet_arn          = data.aws_subnet.first.arn
  }

  depends_on = [aws_efs_mount_target.valhalla]

}

############################################
# DataSync Task (S3 → EFS)
############################################
resource "aws_datasync_task" "s3_to_efs" {
  name = "valhalla-sync"

  source_location_arn      = aws_datasync_location_s3.s3_location.arn
  destination_location_arn = aws_datasync_location_efs.efs_location.arn

  options {
    overwrite_mode = "ALWAYS"
    verify_mode    = "POINT_IN_TIME_CONSISTENT"
  }
}