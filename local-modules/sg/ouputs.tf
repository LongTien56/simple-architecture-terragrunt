output "ec2_sg" {
  value = aws_security_group.ec2_sg.id
}

output "alb_sg" {
  value = aws_security_group.alb_sg.id
}


output "rds_sg" {
  value = aws_security_group.rds_sg.id
}