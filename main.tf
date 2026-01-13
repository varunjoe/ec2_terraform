resource "aws_security_group" "all_traffic_sg" {
  name        = "all-traffic-sg"
  description = "Allow all inbound and outbound traffic"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # CORRECT: Official Canonical ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "aws_instance" "docker_ec2" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.all_traffic_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y

              # Install Docker
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu 

              # Install Terraform
              apt-get update && apt-get install -y gnupg software-properties-common curl wget
              wget -O- apt.releases.hashicorp.com | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
              apt-get update && apt-get install terraform -y

              # Install AWS CLI v2
              apt-get install unzip -y
              curl "awscli.amazonaws.com" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Verification (Logged to /home/ubuntu/)
              docker --version > /home/ubuntu/install_check.txt
              terraform --version >> /home/ubuntu/install_check.txt
              aws --version >> /home/ubuntu/install_check.txt

              chown ubuntu:ubuntu /home/ubuntu/install_check.txt
              EOF

  tags = {
    Name = "Terraform-Docker-EC2"
  }
}
