provider "aws" {
  region = "us-east-1"
}

resource "aws_key_pair" "my_key_pair" {
  key_name   = "terraform-demo-zia"  # Replace with your desired key name
  public_key = file("~/.ssh/id_rsa.pub")  # Replace with the path to your public key file

}



resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# resource "aws_route_table" "my_route_table" {
#   vpc_id = aws_vpc.my_vpc.id
# }

resource "aws_subnet" "my_public_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

}
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
# resource "aws_subnet" "private_subnet" {
#   vpc_id = aws_vpc.my_vpc.id
#   cidr_block = "10.0.2.0/24"
#   availability_zone = "us-east-1a"
# }
resource "aws_security_group" "sg1" {
  vpc_id = aws_vpc.my_vpc.id
  ingress{
    description = "HTTP"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  ingress {
    description = "SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

}
resource "aws_instance" "ec2_server" {
  ami = "ami-04b4f1a9cf54c11d0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg1.id]
  key_name = aws_key_pair.my_key_pair.key_name
  subnet_id = aws_subnet.my_public_subnet.id
  tags = {
    Name = "my_ec2_server"
  }
  connection {
  type        = "ssh"
  user        = "ubuntu"  # Change this based on the AMI (e.g., "ec2-user" for Amazon Linux)
  private_key = file("~/.ssh/id_rsa")  # Ensure this path is correct
  host        = self.public_ip
}

  #   provisioner "file" {
  #   source      = "./Full-Fledge-Blog-Website"  # Replace with the path to your local file
  #   destination = "/home/ubuntu/Full-Fledge-Blog-Website"  # Replace with the path on the remote instance
  # }

provisioner "remote-exec" {
  inline = [
    "echo 'Hello from the remote instance'",
    "sudo apt update && sudo apt install -y git", # Update package lists (for Ubuntu)
    "sudo apt-get install -y python3-pip", 
    "sudo apt install -y python3 python3-venv python3-pip",
    "git clone https://github.com/Zia-Saeed/Full-Fledge-Blog-Website.git",  # Clone the repository
    "cd Full-Fledge-Blog-Website",
    "python3 -m venv venv",
    "source venv/bin/activate",
    "pip install -r requirements.txt",
    "python3 main.py",
  ]
}
}
output "public_ip" {
  value = aws_instance.ec2_server.public_ip
}