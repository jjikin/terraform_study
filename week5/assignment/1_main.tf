provider "aws" {
  region = "ap-northeast-2"
  profile = "ljyoon"
}

# 과제1 count 사용
resource "aws_s3_bucket" "count_bucket" {
  count = 3
  bucket = "terraform-bucket-${count.index}"
}

# 과제1 for_each와 map 사용
resource "aws_iam_user" "for_each_map" {
  for_each = {
    jjikin = {
      position = "student"
      terraform_level = "newbie"
    }
    jjikin = {
      position = "student"
      terraform_level = "newbie"
    }
    gasida = {
      position = "teacher"
      terraform_level = "pro"
    }
  }
 
  name = each.key
  tags = each.value
}
 
output "for_each_map_user_arns" {
  value = values(aws_iam_user.for_each_map)[*].arn
}

# 과제1 for, 문자열 지시자 사용
variable "introduce" {
  description = "map"
  type        = map(string)
  default     = {
    jjikin    = "student"
    gasida     = "teacher"
    jesus  = "god's son"
  }
}

output "bios" {
  value = [for name, role in var.introduce : "${name} is the ${role}"]
}


# 과제2 if 문자열 지시자 사용
