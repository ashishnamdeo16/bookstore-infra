output "db_endpoint" {
  description = "Hostname services use to connect to the database."
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "Database port."
  value       = aws_db_instance.postgres.port
}

# The Secrets Manager secret RDS created, holding the master username + password.
output "db_master_secret_arn" {
  description = "Secrets Manager ARN for the master credentials."
  value       = aws_db_instance.postgres.master_user_secret[0].secret_arn
}

output "initial_database" {
  description = "Name of the initial database."
  value       = aws_db_instance.postgres.db_name
}
