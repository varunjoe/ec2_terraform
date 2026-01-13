## 5️⃣ outputs.tf

output "instance_public_ip" {
  value = aws_instance.docker_ec2.public_ip
}

