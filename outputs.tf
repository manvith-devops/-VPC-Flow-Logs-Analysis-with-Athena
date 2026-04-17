##############################################################
# Outputs – Assignment 15
# Owner: Moath Malkawi
##############################################################

output "moath_malkawi_vpc_id" {
  description = "Moath Malkawi VPC ID"
  value       = aws_vpc.moath_malkawi_vpc.id
}

output "moath_malkawi_public_instance_ip" {
  description = "Public IP of Moath Malkawi public EC2 instance"
  value       = aws_instance.moath_malkawi_public_ec2.public_ip
}

output "moath_malkawi_private_instance_ip" {
  description = "Private IP of Moath Malkawi private EC2 instance"
  value       = aws_instance.moath_malkawi_private_ec2.private_ip
}

output "moath_malkawi_flow_logs_bucket" {
  description = "S3 bucket name for Moath Malkawi VPC Flow Logs"
  value       = aws_s3_bucket.moath_malkawi_flow_logs.bucket
}

output "moath_malkawi_athena_results_bucket" {
  description = "S3 bucket name for Moath Malkawi Athena query results"
  value       = aws_s3_bucket.moath_malkawi_athena_results.bucket
}

output "moath_malkawi_athena_database" {
  description = "Athena database name for Moath Malkawi Flow Logs"
  value       = aws_athena_database.moath_malkawi_db.name
}

output "moath_malkawi_athena_workgroup" {
  description = "Athena workgroup name for Moath Malkawi"
  value       = aws_athena_workgroup.moath_malkawi_wg.id
}

output "moath_malkawi_ssh_command" {
  description = "SSH command to connect to Moath Malkawi public instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.moath_malkawi_public_ec2.public_ip}"
}

output "moath_malkawi_traffic_generation_steps" {
  description = "Steps to generate traffic for Flow Logs testing"
  value = <<-EOT
    === Moath Malkawi – Traffic Generation Steps ===

    1. SSH to public instance:
       ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.moath_malkawi_public_ec2.public_ip}

    2. Ping between instances (from public):
       ping -c 10 ${aws_instance.moath_malkawi_private_ec2.private_ip}

    3. Download external websites:
       wget -q https://www.google.com -O /dev/null
       curl -s https://aws.amazon.com -o /dev/null

    4. Attempt blocked port (will generate REJECT logs):
       nc -zv ${aws_instance.moath_malkawi_private_ec2.private_ip} 8080

    5. Wait ~10 minutes, then run Athena queries.

    === Athena Query Order ===
    a) Run "moath-malkawi-create-flow-logs-table" first
    b) Then run analysis queries

    === Cost Estimation ===
    Athena charges $5.00 per TB scanned.
    Parquet format reduces scan size by ~10x vs plain text.
    EOT
}
