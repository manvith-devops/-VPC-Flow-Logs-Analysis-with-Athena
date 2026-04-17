##############################################################
# Assignment 15 – VPC Flow Logs Analysis with Athena
# Owner: Moath Malkawi
##############################################################

terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner      = "Moath-Malkawi"
      Assignment = "15"
      Project    = "VPC-FlowLogs-Athena"
      ManagedBy  = "Terraform"
    }
  }
}

##############################################################
# Data sources
##############################################################

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

##############################################################
# VPC
##############################################################

resource "aws_vpc" "moath_malkawi_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "moath-malkawi-vpc"
  }
}

##############################################################
# Internet Gateway
##############################################################

resource "aws_internet_gateway" "moath_malkawi_igw" {
  vpc_id = aws_vpc.moath_malkawi_vpc.id

  tags = {
    Name = "moath-malkawi-igw"
  }
}

##############################################################
# Subnets
##############################################################

resource "aws_subnet" "moath_malkawi_public" {
  vpc_id                  = aws_vpc.moath_malkawi_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "moath-malkawi-public-subnet"
    Tier = "Public"
  }
}

resource "aws_subnet" "moath_malkawi_private" {
  vpc_id            = aws_vpc.moath_malkawi_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "moath-malkawi-private-subnet"
    Tier = "Private"
  }
}

##############################################################
# Route Tables
##############################################################

resource "aws_route_table" "moath_malkawi_public_rt" {
  vpc_id = aws_vpc.moath_malkawi_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.moath_malkawi_igw.id
  }

  tags = {
    Name = "moath-malkawi-public-rt"
  }
}

resource "aws_route_table_association" "moath_malkawi_public_rta" {
  subnet_id      = aws_subnet.moath_malkawi_public.id
  route_table_id = aws_route_table.moath_malkawi_public_rt.id
}

resource "aws_route_table" "moath_malkawi_private_rt" {
  vpc_id = aws_vpc.moath_malkawi_vpc.id

  tags = {
    Name = "moath-malkawi-private-rt"
  }
}

resource "aws_route_table_association" "moath_malkawi_private_rta" {
  subnet_id      = aws_subnet.moath_malkawi_private.id
  route_table_id = aws_route_table.moath_malkawi_private_rt.id
}

##############################################################
# Security Groups
##############################################################

resource "aws_security_group" "moath_malkawi_public_sg" {
  name        = "moath-malkawi-public-sg"
  description = "Moath Malkawi - Public instance SG (SSH + ICMP allowed)"
  vpc_id      = aws_vpc.moath_malkawi_vpc.id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ICMP ping"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "moath-malkawi-public-sg"
  }
}

resource "aws_security_group" "moath_malkawi_private_sg" {
  name        = "moath-malkawi-private-sg"
  description = "Moath Malkawi - Private instance SG (SSH + ICMP from VPC only)"
  vpc_id      = aws_vpc.moath_malkawi_vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "moath-malkawi-private-sg"
  }
}

##############################################################
# Key Pair
##############################################################

resource "aws_key_pair" "moath_malkawi_key" {
  key_name   = "moath-malkawi-key"
  public_key = var.ssh_public_key

  tags = {
    Name = "moath-malkawi-key"
  }
}

##############################################################
# EC2 Instances
##############################################################

resource "aws_instance" "moath_malkawi_public_ec2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.moath_malkawi_public.id
  vpc_security_group_ids = [aws_security_group.moath_malkawi_public_sg.id]
  key_name               = aws_key_pair.moath_malkawi_key.key_name

  user_data = base64encode(templatefile("${path.module}/userdata_public.sh", {
    private_ip = aws_instance.moath_malkawi_private_ec2.private_ip
  }))

  tags = {
    Name = "moath-malkawi-public-ec2"
    Tier = "Public"
  }

  depends_on = [aws_instance.moath_malkawi_private_ec2]
}

resource "aws_instance" "moath_malkawi_private_ec2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.moath_malkawi_private.id
  vpc_security_group_ids = [aws_security_group.moath_malkawi_private_sg.id]
  key_name               = aws_key_pair.moath_malkawi_key.key_name

  user_data = base64encode(file("${path.module}/userdata_private.sh"))

  tags = {
    Name = "moath-malkawi-private-ec2"
    Tier = "Private"
  }
}

##############################################################
# S3 Bucket for VPC Flow Logs
##############################################################

resource "aws_s3_bucket" "moath_malkawi_flow_logs" {
  bucket        = "moath-malkawi-vpc-flow-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "moath-malkawi-flow-logs-bucket"
  }
}

resource "aws_s3_bucket_versioning" "moath_malkawi_flow_logs_versioning" {
  bucket = aws_s3_bucket.moath_malkawi_flow_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "moath_malkawi_flow_logs_sse" {
  bucket = aws_s3_bucket.moath_malkawi_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "moath_malkawi_flow_logs_pab" {
  bucket                  = aws_s3_bucket.moath_malkawi_flow_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "moath_malkawi_flow_logs_lifecycle" {
  bucket = aws_s3_bucket.moath_malkawi_flow_logs.id

  rule {
    id     = "moath-malkawi-flow-logs-expiry"
    status = "Enabled"

    filter {}

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "moath_malkawi_flow_logs_policy" {
  bucket = aws_s3_bucket.moath_malkawi_flow_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.moath_malkawi_flow_logs.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"               = "bucket-owner-full-control"
            "aws:SourceAccount"           = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.moath_malkawi_flow_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

##############################################################
# VPC Flow Logs  (Parquet format, Hive-compatible partitions)
##############################################################

resource "aws_flow_log" "moath_malkawi_vpc_flow_log" {
  vpc_id               = aws_vpc.moath_malkawi_vpc.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = aws_s3_bucket.moath_malkawi_flow_logs.arn
  log_format           = var.flow_log_format

  destination_options {
    file_format                = "parquet"
    hive_compatible_partitions = true
    per_hour_partition         = true
  }

  tags = {
    Name = "moath-malkawi-vpc-flow-log"
  }
}

##############################################################
# Athena – Database, Workgroup, S3 results bucket
##############################################################

resource "aws_s3_bucket" "moath_malkawi_athena_results" {
  bucket        = "moath-malkawi-athena-results-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name = "moath-malkawi-athena-results"
  }
}

resource "aws_s3_bucket_public_access_block" "moath_malkawi_athena_results_pab" {
  bucket                  = aws_s3_bucket.moath_malkawi_athena_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_athena_workgroup" "moath_malkawi_wg" {
  name        = "moath-malkawi-workgroup"
  description = "Moath Malkawi – Athena workgroup for VPC Flow Logs analysis"

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.moath_malkawi_athena_results.bucket}/results/"

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  tags = {
    Name = "moath-malkawi-workgroup"
  }
}

resource "aws_athena_database" "moath_malkawi_db" {
  name   = "moath_malkawi_vpc_flow_logs"
  bucket = aws_s3_bucket.moath_malkawi_athena_results.bucket

  comment = "Moath Malkawi – VPC Flow Logs Athena database"
}

##############################################################
# Athena Table (Parquet + Hive partitions)
##############################################################

resource "aws_athena_named_query" "moath_malkawi_create_table" {
  name      = "moath-malkawi-create-flow-logs-table"
  workgroup = aws_athena_workgroup.moath_malkawi_wg.id
  database  = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – Create VPC Flow Logs Parquet table with Hive partitions"

  query = <<-SQL
    CREATE EXTERNAL TABLE IF NOT EXISTS vpc_flow_logs (
      version        int,
      account_id     string,
      interface_id   string,
      srcaddr        string,
      dstaddr        string,
      srcport        int,
      dstport        int,
      protocol       bigint,
      packets        bigint,
      bytes          bigint,
      start          bigint,
      end            bigint,
      action         string,
      log_status     string,
      vpc_id         string,
      subnet_id      string,
      instance_id    string,
      tcp_flags      int,
      type           string,
      pkt_srcaddr    string,
      pkt_dstaddr    string,
      region         string,
      az_id          string,
      sublocation_type string,
      sublocation_id string,
      pkt_src_aws_service string,
      pkt_dst_aws_service string,
      flow_direction  string,
      traffic_path    int
    )
    PARTITIONED BY (
      aws_account_id string,
      aws_service    string,
      aws_region     string,
      year           string,
      month          string,
      day            string,
      hour           string
    )
    ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
    STORED AS
      INPUTFORMAT  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
      OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
    LOCATION 's3://${aws_s3_bucket.moath_malkawi_flow_logs.bucket}/AWSLogs/'
    TBLPROPERTIES (
      'has_encrypted_data' = 'false',
      'projection.enabled' = 'true',
      'projection.aws_account_id.type'  = 'enum',
      'projection.aws_account_id.values'= '${data.aws_caller_identity.current.account_id}',
      'projection.aws_service.type'     = 'enum',
      'projection.aws_service.values'   = 'vpcflowlogs',
      'projection.aws_region.type'      = 'enum',
      'projection.aws_region.values'    = '${var.aws_region}',
      'projection.year.type'            = 'integer',
      'projection.year.range'           = '2024,2030',
      'projection.month.type'           = 'integer',
      'projection.month.range'          = '1,12',
      'projection.month.digits'         = '2',
      'projection.day.type'             = 'integer',
      'projection.day.range'            = '1,31',
      'projection.day.digits'           = '2',
      'projection.hour.type'            = 'integer',
      'projection.hour.range'           = '0,23',
      'projection.hour.digits'          = '2',
      'storage.location.template'       = 's3://${aws_s3_bucket.moath_malkawi_flow_logs.bucket}/AWSLogs/$${aws_account_id}/$${aws_service}/$${aws_region}/$${year}/$${month}/$${day}/$${hour}'
    );
  SQL
}

##############################################################
# Saved Athena Queries
##############################################################

resource "aws_athena_named_query" "moath_malkawi_top10_src_ips" {
  name        = "moath-malkawi-top10-source-ips"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – Top 10 source IPs by traffic volume (bytes)"

  query = <<-SQL
    -- Moath Malkawi: Top 10 source IPs by total bytes
    SELECT
      srcaddr,
      COUNT(*)          AS flow_count,
      SUM(bytes)        AS total_bytes,
      SUM(packets)      AS total_packets
    FROM vpc_flow_logs
    WHERE srcaddr IS NOT NULL
      AND log_status = 'OK'
    GROUP BY srcaddr
    ORDER BY total_bytes DESC
    LIMIT 10;
  SQL
}

resource "aws_athena_named_query" "moath_malkawi_reject_actions" {
  name        = "moath-malkawi-reject-actions"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – All REJECT actions (blocked traffic)"

  query = <<-SQL
    -- Moath Malkawi: All REJECT actions
    SELECT
      srcaddr,
      dstaddr,
      srcport,
      dstport,
      protocol,
      packets,
      bytes,
      action,
      from_unixtime(start) AS start_time,
      from_unixtime(end)   AS end_time
    FROM vpc_flow_logs
    WHERE action = 'REJECT'
      AND log_status = 'OK'
    ORDER BY start DESC
    LIMIT 1000;
  SQL
}

resource "aws_athena_named_query" "moath_malkawi_traffic_between_ips" {
  name        = "moath-malkawi-traffic-between-ips"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – Traffic between two specific IPs (replace placeholders)"

  query = <<-SQL
    -- Moath Malkawi: Traffic between specific IPs
    -- Replace '10.0.1.x' and '10.0.2.x' with the actual IPs
    SELECT
      srcaddr,
      dstaddr,
      srcport,
      dstport,
      protocol,
      action,
      bytes,
      packets,
      from_unixtime(start) AS start_time
    FROM vpc_flow_logs
    WHERE (
      (srcaddr = '10.0.1.x' AND dstaddr = '10.0.2.x')
      OR
      (srcaddr = '10.0.2.x' AND dstaddr = '10.0.1.x')
    )
    AND log_status = 'OK'
    ORDER BY start DESC;
  SQL
}

resource "aws_athena_named_query" "moath_malkawi_port22_connections" {
  name        = "moath-malkawi-port22-ssh-connections"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – All connections to/from port 22 (SSH)"

  query = <<-SQL
    -- Moath Malkawi: SSH (port 22) connection attempts
    SELECT
      srcaddr,
      dstaddr,
      srcport,
      dstport,
      action,
      bytes,
      packets,
      from_unixtime(start) AS start_time
    FROM vpc_flow_logs
    WHERE (dstport = 22 OR srcport = 22)
      AND protocol = 6
      AND log_status = 'OK'
    ORDER BY start DESC;
  SQL
}

resource "aws_athena_named_query" "moath_malkawi_traffic_by_protocol" {
  name        = "moath-malkawi-traffic-by-protocol"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – Traffic breakdown by protocol (TCP/UDP/ICMP)"

  query = <<-SQL
    -- Moath Malkawi: Traffic by protocol
    -- IANA protocol numbers: 6=TCP, 17=UDP, 1=ICMP
    SELECT
      CASE protocol
        WHEN 1  THEN 'ICMP'
        WHEN 6  THEN 'TCP'
        WHEN 17 THEN 'UDP'
        ELSE CAST(protocol AS VARCHAR)
      END                   AS protocol_name,
      protocol,
      COUNT(*)              AS flow_count,
      SUM(bytes)            AS total_bytes,
      SUM(packets)          AS total_packets,
      SUM(CASE WHEN action = 'ACCEPT' THEN 1 ELSE 0 END) AS accepted,
      SUM(CASE WHEN action = 'REJECT' THEN 1 ELSE 0 END) AS rejected
    FROM vpc_flow_logs
    WHERE log_status = 'OK'
    GROUP BY protocol
    ORDER BY total_bytes DESC;
  SQL
}

resource "aws_athena_named_query" "moath_malkawi_security_events" {
  name        = "moath-malkawi-security-events-summary"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – Security events: rejected traffic + port scans"

  query = <<-SQL
    -- Moath Malkawi: Security event detection
    SELECT
      srcaddr,
      COUNT(DISTINCT dstport) AS distinct_ports_targeted,
      COUNT(*)                AS total_attempts,
      SUM(CASE WHEN action = 'REJECT' THEN 1 ELSE 0 END) AS rejected_count,
      MIN(from_unixtime(start)) AS first_seen,
      MAX(from_unixtime(end))   AS last_seen
    FROM vpc_flow_logs
    WHERE action = 'REJECT'
      AND log_status = 'OK'
    GROUP BY srcaddr
    HAVING COUNT(*) > 5
    ORDER BY rejected_count DESC
    LIMIT 50;
  SQL
}

resource "aws_athena_named_query" "moath_malkawi_cost_estimate" {
  name        = "moath-malkawi-data-scanned-cost-estimate"
  workgroup   = aws_athena_workgroup.moath_malkawi_wg.id
  database    = aws_athena_database.moath_malkawi_db.name
  description = "Moath Malkawi – Row count to help estimate Athena data-scanned cost"

  query = <<-SQL
    -- Moath Malkawi: Row count per day for cost estimation
    -- Athena costs $5 per TB scanned; Parquet compression typically 10x smaller
    SELECT
      year,
      month,
      day,
      COUNT(*) AS row_count
    FROM vpc_flow_logs
    WHERE log_status = 'OK'
    GROUP BY year, month, day
    ORDER BY year DESC, month DESC, day DESC;
  SQL
}
