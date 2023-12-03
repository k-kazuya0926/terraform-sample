output "first_arn" {
  value       = aws_iam_user.example[0].arn
  description = "The ARN for the first user"
}

output "all_arns" {
  value       = aws_iam_user.example[*].arn
  description = "The ARNs for all users"
}

output "neo_cloudwatch_policy_arn" {
  value = one(concat(
    aws_iam_user_policy_attachment.neo_cloudwatch_full_access[*].policy_arn,
    aws_iam_user_policy_attachment.neo_cloudwatch_read_only[*].policy_arn,
  ))
}

output "for_directive_index_if_strip" {
  value = <<EOF
%{~for i, name in var.user_names~}
${name}%{if i < length(var.user_names) - 1}, %{endif}
%{~endfor~}
EOF
}
