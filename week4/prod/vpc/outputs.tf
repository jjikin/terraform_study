output "stg-pub-a-sn" { 
  value = aws_subnet.stg-pub-a-sn.id
}
output "stg-pub-c-sn" { 
  value = aws_subnet.stg-pub-c-sn.id
}

output "stg-pri-a-sn" { 
  value = aws_subnet.stg-pri-a-sn.id
}
output "stg-pri-c-sn" { 
  value = aws_subnet.stg-pri-c-sn.id
}

output "stg-vpc-id" {
  value = aws_vpc.jjikin-stg-vpc.id
}
