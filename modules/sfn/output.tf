output "drs_recovery_sfn_arn" {
  value = aws_sfn_state_machine.drs_recovery_sfn.arn
}

output "drs_recovery_sfn_id" {
  value = aws_sfn_state_machine.drs_recovery_sfn.id
}

output "drs_recovery_role_arn" {
  value = data.aws_iam_role.drs_recovery_role.arn
}