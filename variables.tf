
## 3️⃣ variables.tf

```hcl
variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t3.small"
}

variable "key_name" {
  description = "Github-action-keypair"
}
```
