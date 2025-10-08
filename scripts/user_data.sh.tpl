#!/bin/bash

# Install Node.js
curl -o /tmp/nodejs.tar.xz https://nodejs.org/dist/v18.18.0/node-v18.18.0-linux-x64.tar.xz
mkdir -p /usr/local/lib/nodejs
tar -xJf /tmp/nodejs.tar.xz -C /usr/local/lib/nodejs
echo "export PATH=/usr/local/lib/nodejs/node-v18.18.0-linux-x64/bin:\$PATH" >> /etc/profile.d/nodejs.sh

# Install DRS Agent
curl -o aws-replication-installer-init https://aws-elastic-disaster-recovery-${region}.s3.${region}.amazonaws.com/latest/linux/aws-replication-installer-init
chmod +x aws-replication-installer-init
sudo ./aws-replication-installer-init --no-prompt --region ${region} # DRS Drill for all devices

echo "Finished installing DRS Agent"
# Clean up
rm -f /tmp/nodejs.tar.xz
rm -f aws-replication-installer-init