provider "aws" {
   region = "eu-central-1" 
}

resource "aws_instance" "ubuntu" {
ami = "ami-05f7491af5eef733a"
instance_type = "t2.micro"
#security_groups = [data.aws_security_group.selected.name]
security_groups = [aws_security_group.test_for_web_server.name]
key_name = "webserver1"

user_data = file("user_data1.sh")
}

resource "aws_eip" "test" {
  instance = aws_instance.ubuntu.id
  vpc      = true
}

#data "aws_security_group" "test_for_web_server" {
#  name = "test1_webserver"
#}

resource "aws_security_group" "test_for_web_server" {
 name        = "test1_webserver"
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  
}
 ingress {
   # description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}