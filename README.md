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

              # 2. Install Terraform (Fixed URL and added https)
              apt-get update && apt-get install -y gnupg software-properties-common curl wget
              wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
              apt-get update && apt-get install terraform -y

              # 3. Install AWS CLI v2 (Fixed direct download URL)
              apt-get install unzip -y
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
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
-------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
 # ADD THIS BLOCK BELOW
  backend "s3" {
    bucket         = "919466768284-terraform-states"
    key            = "ec2-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region  = "us-east-1"
}

resource "aws_instance" "app_server" {
  ami           = "ami-0ecb62995f68bb549"
  instance_type = "t3.micro"

  tags = {
    Name = "Terraform_Demo"
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
