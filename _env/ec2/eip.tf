resource "aws_eip" "eip" {
  instance = aws_instance.this[0].id
  vpc      = true
  tags = {
        Name = "hblab-test"
  }
}