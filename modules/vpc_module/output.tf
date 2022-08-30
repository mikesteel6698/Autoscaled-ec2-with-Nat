output "vpc_id" {
  value = aws_vpc.pro_vpc.id
}

output "pubsubnet_id" {
  value = aws_subnet.pub_subnet.id
}

output "privsubnet_id" {
  value = aws_subnet.priv_subnet.id
}

