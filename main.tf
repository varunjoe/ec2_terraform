## 4️⃣ main.tf

```hcl
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

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  owners = ["amazon"]
}

resource "aws_instance" "docker_ec2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.all_traffic_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y

              # Install Docker
              yum install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Install Terraform
              yum install -y yum-utils
              yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
              yum install terraform -y

              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Verification
              docker --version > /home/ec2-user/install_check.txt
              terraform --version >> /home/ec2-user/install_check.txt
              aws --version >> /home/ec2-user/install_check.txt

              chown ec2-user:ec2-user /home/ec2-user/install_check.txt
              EOF

  tags = {
    Name = "Terraform-Docker-EC2"
  }
}
```
