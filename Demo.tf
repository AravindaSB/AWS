provider "aws" {
  access_key="AKIAJH2NLHDNMIXMWU5Q"
  secret_key="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"
  region = "ap-southeast-1"
}



#create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id

 
}

# create custom route table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "prod"
  }
}

#subnet
resource "aws_subnet" "subnet-1" {
  vpc_id = aws_vpc.prod-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-southeast-1b"
  tags = {
    Name = "prod-subnet"
  }
}

#aasociate subnet with route table
  resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#security group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443 
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "SSh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}


#network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  
}

#assign an eip to network interface
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

#create ubuntu server and install/enable apache2
/*resource "aws_instance" "web-server-in" {
  ami           = "ami-54b1cf06"
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1b"
  key_name = "main-key"

  network_interface{
     device_index = 0
     network_interface_id = aws_network_interface.web-server-nic.id
    
  }
  
  user_data = <<-EOF
              #1/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "web-server"
  }
}*/

/*data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}*/

/*resource "aws_key_pair" "app-instance-key" {
  key_name   = "main-key"
  public_key = "ssh-rsa MIIEowIBAAKCAQEAqNr2GXH2nO22/ecrt2DcwtwZC2qrAJtNqjGF1ZlRmNxVzntWcsvdVZzDCecEZPaB0NAEAZeiI5ELStZXUpY/btJNJnHnz9IAL1h26QDTiyr/VmZ5aJOTOcUdB7MD9PznsmATOrh2tMKDbOhYXmNbRPqXx0H3knk0sXR6AZGux8zQx0zfn4zu2LqHYu9o3LSRjl1Qdm1sKKbY9J9vfec/vyF4R3z3bZlyG4oE/9vRZhp9loYaq13G9l68k4vWt83NOG1uirfUnqShmxhICm000dPDekZ8zb0jcwNsBYC8jY7aEO6GtIqC4jkaoVFNsNp3pDWctfvEXYG8qJ86pnmZnQIDAQABAoIBACEwuQMTZZg/GaMa13r6LSqYPMwDsY0y+bckeNwdgO59ENi/YaS68cysPaIqqLB3y9iRqtftSE+ZaRDSxONU6S8NY2DVLu2op6SmzOjL4skOMJZ5GhA2QdAvMJ+czoBPXfOv8tet/pdVTKQRn50eBoiugTsHenRuIq9m57x7OFHJW/7lTvN0dRcCL0SgHcHXBqy4FljemJ94zq6ld1z+KUOfed89GSQE0j69cgyf7FQO0wPfsidwJP0htCm6fVUew2InFIoWx1SBFQ6vdhx8uQGbSuFSkiVglWrKxz4pG0TyIDWgGrSUKqyNREU/kwRQSiQUbqdrauRCrWRPFaq2/YECgYEA8Gy4W5eWy4sQbKaEQfSoeQ4A3H6y/ohne8vMrW1+WtlaQJ8dTY03l3lC5+USrxjSTWYUuF32VQEaICgvhSXphbJqNE4yPVTR/cAGwVd3fgCtHM7+dGjaBWpun5x0x3TUaslQeACoPNUc1xQ6slGGsfFsw7bAk12xUI5LbuiUzc0CgYEAs8tP1rnfoZXG6hJSEKZfT/OHMqWioX4Jvovn0qsl4NkLgpBEycUT8qYZeGX8B2UG3YFFWHZ0g00ryL8rsF7RJt/T9NuEVKZNV795kFGG/loluiv84oSMvB0BqQ7bhOTzuX1EdvshSPA3eR4fTk7tGdT+cxfAsKDKoFkx7uugqxECgYEA76aPhczupOlzb7nz74KeRDxvI1qvtQPmkwGsfdq8rnYlfnCcVudC2Jwo0toF679EMZ5lXPlcR5MXpaIo7AHEal5TetvPPE9GGjfFBAfZtiGabTLvdL3nRKq4piTgSsjry53rthKBoFGVs9YYRBL7vne2QMfz4XDtBC0yh9USLqkCgYBCobaU/Y3DdJ6jYObJBN+N4dLZEkmTUAKMe40Oph8DlWyOlqjnngImiyglVqZwlyBUNvRcNIo5nv/7Bd5LHtikb489z5zbQkannm6O7af5267fsC2oRTdi/9z9qmPwfGlW9PXKoodTYLMuT9uKSfXU/PrP7J2c1/pAMs4unWSOAQKBgBmmDWx1XnojKZbewXpX3ahAU/CLNj85f3CpJqbzxJygchE2m9v9nVO7Co3nXXLjoQxxaeynOR7aaGDmw0+gwOBJ727GPV+UhYEQJd6kOUT2ImIGJz7cs5RFHaYKA/KI50G2k7rxs4XWIHxC/CSQmu5yZyrQtVMI/FHiJt8+waoQ"
  }*/

data "aws_ami" "windows" {
     most_recent = true     
filter {
       name   = "name"
       values = ["Windows_Server-2019-English-Full-Base-*"]  
  }     
filter {
       name   = "virtualization-type"
       values = ["hvm"]  
  }     
owners = ["801119661308"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.windows.id
  instance_type = "t2.micro"
  availability_zone = "ap-southeast-1b"
 # key_name = "${aws_key_pair.app-instance-key.key_name}"
 

  network_interface{
     device_index = 0
     network_interface_id = aws_network_interface.web-server-nic.id
    
  }
  
  user_data = <<-EOF
              #1/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF

  tags = {
    Name = "web-server"
  }
}