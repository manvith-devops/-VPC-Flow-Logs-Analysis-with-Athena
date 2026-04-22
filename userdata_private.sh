#!/bin/bash
# Manvith – Private EC2 user data

set -euxo pipefail

yum update -y
yum install -y nmap-ncat wget curl

echo "Manvith private instance started at $(date)" >> /var/log/manvith-startup.log
