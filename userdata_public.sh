#!/bin/bash
# Manvith – Public EC2 user data
# Installs tools and generates traffic for VPC Flow Logs

set -euxo pipefail

# System update
yum update -y

# Install tools
yum install -y nmap-ncat wget curl tcpdump

# Log startup
echo "Manvith public instance started at $(date)" >> /var/log/manvith-startup.log

# Generate traffic after 2-minute delay (to let flow logs initialise)
cat << 'TRAFFIC_SCRIPT' > /tmp/generate_traffic.sh
#!/bin/bash
# Manvith – traffic generation script
sleep 120

PRIVATE_IP="${private_ip}"

echo "[$(date)] Manvith: Starting traffic generation" >> /var/log/manvith-traffic.log

# Ping private instance (ICMP)
ping -c 20 "$PRIVATE_IP" >> /var/log/manvith-traffic.log 2>&1 || true

# Download external websites (TCP/HTTP)
wget -q https://www.google.com    -O /dev/null >> /var/log/manvith-traffic.log 2>&1 || true
wget -q https://www.amazon.com    -O /dev/null >> /var/log/manvith-traffic.log 2>&1 || true
curl -s https://checkip.amazonaws.com        >> /var/log/manvith-traffic.log 2>&1 || true

# SSH attempt to private instance (will log TCP port 22)
nc -zv "$PRIVATE_IP" 22 >> /var/log/manvith-traffic.log 2>&1 || true

# Attempt blocked port (will generate REJECT in flow logs)
nc -zv "$PRIVATE_IP" 8080 -w 2 >> /var/log/manvith-traffic.log 2>&1 || true
nc -zv "$PRIVATE_IP" 3389 -w 2 >> /var/log/manvith-traffic.log 2>&1 || true

echo "[$(date)] Manvith: Traffic generation complete" >> /var/log/manvith-traffic.log
TRAFFIC_SCRIPT

chmod +x /tmp/generate_traffic.sh
nohup bash /tmp/generate_traffic.sh &
