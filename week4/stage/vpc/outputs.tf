output "pub-a-sn" { 
  value = aws_subnet.pub-a-sn.id
}
output "pub-c-sn" { 
  value = aws_subnet.pub-c-sn.id
}

output "pri-a-sn" { 
  value = aws_subnet.pri-a-sn.id
}
output "pri-c-sn" { 
  value = aws_subnet.pri-c-sn.id
}

output "vpc-id" {
  value = aws_vpc.jjikin-vpc.id
}
