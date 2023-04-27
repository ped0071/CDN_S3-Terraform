# Define as credenciais para acessar a AWS
provider "aws" {
  region     = "us-west-2"
}

resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_ownership_controls" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_object" "bucket_name" {
  bucket = aws_s3_bucket.bucket.id
  key    = "index.html"
  source = "./index.html"
  content_type = "text/html"
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "bucket" {
  depends_on = [
    aws_s3_bucket_ownership_controls.bucket,
    aws_s3_bucket_public_access_block.bucket,
  ]

  bucket = aws_s3_bucket.bucket.id
  acl    = "public-read"
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "blacklist"
      locations        = ["DE"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }


    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
