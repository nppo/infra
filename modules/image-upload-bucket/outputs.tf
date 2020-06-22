output "image_bucket_arn" {
  value = aws_s3_bucket.surfpol-image-uploads.arn
  description = "The arn of the image upload s3 bucket"
}
