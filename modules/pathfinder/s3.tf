############################################
# S3 bucket for Valhalla custom files
############################################

resource "aws_s3_bucket" "custom_files" {
  bucket        = "custom-files-valhalla"
  force_destroy = true
}