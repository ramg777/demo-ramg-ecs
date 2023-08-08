

resource "aws_acm_certificate" "my_certificate" {
  domain_name       = "test.ryntech.link"  # Replace with your domain name
  validation_method = "DNS"

  tags = {
    Name = "MyCertificate"
  }
}

resource "aws_route53_record" "validation_record" {
  name    = aws_acm_certificate.my_certificate.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.my_certificate.domain_validation_options.0.resource_record_type
  zone_id = "Z03223641Z7R6QZLO18J9"


  records = [aws_acm_certificate.my_certificate.domain_validation_options.0.resource_record_value]

  ttl = 300
}

resource "aws_acm_certificate_validation" "certificate_validation" {
  certificate_arn         = aws_acm_certificate.my_certificate.arn
  validation_record_fqdns = [aws_route53_record.validation_record.fqdn]
}
