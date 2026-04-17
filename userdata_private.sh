#!/bin/bash
# Moath Malkawi – Private EC2 user data

set -euxo pipefail

yum update -y
yum install -y nmap-ncat wget curl

echo "Moath Malkawi private instance started at $(date)" >> /var/log/moath-malkawi-startup.log
