resource "aws_vpc_endpoint" "api-gateway-endpoint" {

  vpc_id             = local.vpc_id
  service_name       = "com.amazonaws.ap-northeast-2.execute-api"
  vpc_endpoint_type  = "Interface"
  security_group_ids = ["sg-0ee1cce9a45b91516"]
  subnet_ids         = values(local.was_subnets)

  private_dns_enabled = true

  tags = {
    Name = "api-gateway-endpoint-",
  }

}
