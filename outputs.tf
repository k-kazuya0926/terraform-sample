output "domain_name" {
  value = aws_route53_record.example.name
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
