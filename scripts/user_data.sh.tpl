#!/bin/bash

# Install DRS Agent
curl -o aws-replication-installer-init https://aws-elastic-disaster-recovery-${region}.s3.${region}.amazonaws.com/latest/linux/aws-replication-installer-init
chmod +x aws-replication-installer-init
sudo ./aws-replication-installer-init --no-prompt --region ${region} # DRS Drill for all devices

echo "Finished installing DRS Agent"
# Clean up
rm -f /tmp/nodejs.tar.xz
rm -f aws-replication-installer-init