variable "users" {
  description = "users to render"
  type        = list(string)
  default     = ["aaa", "bbb", "ccc"]
}

output "for_directive" {
  value = "%{ for name in var.users }${name}, %{ endfor }"
}

output "for_directive_index" {
  value = "%{ for i, name in var.users }(${i}) ${name}, %{ endfor }"
}

output "for_directive_index_if" {
  value = <<EOF
%{ for i, name in var.names }
  \${name}%{ if i < length(var.names) - 1 }, %{ endif }
%{ endfor }
EOF
}