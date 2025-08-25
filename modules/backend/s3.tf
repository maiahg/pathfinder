############################################
# S3 bucket for Valhalla custom files
############################################

resource "aws_s3_bucket" "custom_files" {
  bucket        = "valhalla-custom-files"
  force_destroy = true
}