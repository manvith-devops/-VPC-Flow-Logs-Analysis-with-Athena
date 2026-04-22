##############################################################
# Outputs – Assignment 15
# Owner: Manvith
##############################################################

output "manvith_vpc_id" {
  description = "Manvith VPC ID"
  value       = aws_vpc.manvith_vpc.id
}

output "manvith_public_instance_ip" {
  description = "Public IP of Manvith public EC2 instance"
  value       = aws_instance.manvith_public_ec2.public_ip
}

output "manvith_private_instance_ip" {
  description = "Private IP of Manvith private EC2 instance"
  value       = aws_instance.manvith_private_ec2.private_ip
}

output "manvith_flow_logs_bucket" {
  description = "S3 bucket name for Manvith VPC Flow Logs"
  value       = aws_s3_bucket.manvith_flow_logs.bucket
}

output "manvith_athena_results_bucket" {
  description = "S3 bucket name for Manvith Athena query results"
  value       = aws_s3_bucket.manvith_athena_results.bucket
}

output "manvith_athena_database" {
  description = "Athena database name for Manvith Flow Logs"
  value       = aws_athena_database.manvith_db.name
}

output "manvith_athena_workgroup" {
  description = "Athena workgroup name for Manvith"
  value       = aws_athena_workgroup.manvith_wg.id
}

output "manvith_ssh_command" {
  description = "SSH command to connect to Manvith public instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.manvith_public_ec2.public_ip}"
}

output "manvith_traffic_generation_steps" {
  description = "Steps to generate traffic for Flow Logs testing"
  value = <<-EOT
    === Manvith – Traffic Generation Steps ===

    1. SSH to public instance:
       ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.manvith_public_ec2.public_ip}

    2. Ping between instances (from public):
       ping -c 10 ${aws_instance.manvith_private_ec2.private_ip}

    3. Download external websites:
       wget -q https://www.google.com -O /dev/null
       curl -s https://aws.amazon.com -o /dev/null

    4. Attempt blocked port (will generate REJECT logs):
       nc -zv ${aws_instance.manvith_private_ec2.private_ip} 8080

    5. Wait ~10 minutes, then run Athena queries.

    === Athena Query Order ===
    a) Run "manvith-create-flow-logs-table" first
    b) Then run analysis queries

    === Cost Estimation ===
    Athena charges $5.00 per TB scanned.
    Parquet format reduces scan size by ~10x vs plain text.
    EOT
}
