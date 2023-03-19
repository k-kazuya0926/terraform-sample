#data "aws_route53_zone" "example" { # 参照
#  name = "example.com"
#}

resource "aws_route53_zone" "example" { # 作成
  name = "test.example.com"
}

resource "aws_route53_record" "example" {
  #  name    = data.aws_route53_zone.example.name
  name = aws_route53_zone.example.name
  type = "A"
  #  zone_id = data.aws_route53_zone.example.zone_id
  zone_id = aws_route53_zone.example.zone_id

  alias { # ドメイン名 → IPアドレス
    evaluate_target_health = true
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
  }
}

output "domain_name" {
  value = aws_route53_record.example.name
}
