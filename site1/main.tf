terraform {
  backend "s3" {
    bucket = "ibutsko"
    key    = "terraform.tfstate"
    region = "eu-central-1"
  }
}
provider "aws" {
    region = "eu-central-1"
}

#####---------------------------------------------#####
################--VPC--################################

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Main_VPC_Butsko"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "Public_Subnet_Butsko"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "Private_Subnet_Butsko"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main_IGW_Butsko"
  }
}

resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.igw]
  tags = {
    Name = "NAT_Gateway_EIP_Butsko"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "Main_NAT_Gateway_Butsko"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public_Route_Table_Butsko"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private_Route_Table_Butsko"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}


###############################################################################
###########----BASTION-----####################################################
###############################################################################


locals {
  bastion_key = "webserver1"
 }

#data "aws_instance" "ubuntu" {
#  
#    filter{
#        name   = "Name"
#        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20210430"]
#   }
#}

resource "aws_iam_role" "bastion" {
  name = "bastion"
  assume_role_policy = file("/home/user/local/terraform/site/templates/bastion/instance-profile-policy.json")

}

resource "aws_iam_role_policy_attachment" "bastion_attach_policy" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-instance-profile2"
  role = aws_iam_role.bastion.name
}

resource "aws_instance" "bastion" {
    
    ami = "ami-05f7491af5eef733a"  
    instance_type = "t2.micro"
    subnet_id = aws_subnet.public.id
    iam_instance_profile = aws_iam_instance_profile.bastion.name
    key_name = "${var.bastion_key}"
     vpc_security_group_ids = [aws_security_group.bastion.id]
   
    tags = {
        Name  = "bastion"
        Owner = "ivan"
    }
}

resource "aws_security_group" "bastion"{
    description = "bastion inbound and outbound (Butsko)"
    name = "bastion"
    vpc_id = aws_vpc.main.id

    ingress {
        protocol = "tcp"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true
}

