Below is a **complete Terraform-based solution** that does everything you asked:

* Creates an **EC2 instance**
* Enables **inbound all traffic (0.0.0.0/0, all ports)** ⚠️ (not recommended for prod)
* Installs **Docker, Terraform, AWS CLI**
* **Configures AWS CLI**
* **Verifies** all installations are up and running

---

## Architecture Overview

* Terraform provisions:

  * EC2 instance (Amazon Linux 2)
  * Security Group (All inbound + outbound)
  * User-data script for installation & verification

---

## 1️⃣ Terraform File Structure

```
ec2-terraform/
│
├── provider.tf
├── main.tf
├── variables.tf
└── outputs.tf
```

---

## 2️⃣ provider.tf

```hcl

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "919466768284-terraform-states"
    key            = "ec2-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock" # Must be pre-created
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

```

---

## 3️⃣ variables.tf

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Github-action-keypair"
}
```

---

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

---

## 5️⃣ outputs.tf

```hcl
output "instance_public_ip" {
  value = aws_instance.docker_ec2.public_ip
}
```

---

## 6️⃣ Deploy the Infrastructure

```bash
terraform init
terraform plan
terraform apply
```

---

## 7️⃣ SSH Into EC2

```bash
ssh -i your-key.pem ec2-user@<PUBLIC_IP>
```

---

## 8️⃣ Verify Installations (Inside EC2)

```bash
docker --version
terraform --version
aws --version
systemctl status docker
```

Or check the auto-generated file:

```bash
cat ~/install_check.txt
```

---

## 9️⃣ Configure AWS CLI (Manual – Best Practice)

```bash
aws configure
```

Enter:

* AWS Access Key
* AWS Secret Key
* Region
* Output format

---

## ⚠️ Important Security Note

* **Inbound all traffic (0.0.0.0/0)** is unsafe
* Recommended to restrict:

  * SSH → your IP only
  * App ports only (e.g., 80, 443)

---

If you want, I can:

* Lock SSH to your IP
* Add IAM Role instead of `aws configure`
* Convert this to **Terraform modules**
* Add **Docker Compose / Kubernetes**

Just tell me 👍
