output "pri-a-sn" { 
  value = aws_subnet.pri-a-sn.id
}

output "pri-c-sn" { 
  value = aws_subnet.pri-c-sn.id
}

output "rds-sg" {
  value = aws_security_group.rds-sg.id
}

output "vpc-id" {
  value = aws_vpc.jjikin-vpc.id
}
