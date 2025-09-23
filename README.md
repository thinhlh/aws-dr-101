# AWS Windows EC2 with DRS POC

A comprehensive Proof of Concept (POC) demonstrating AWS Elastic Disaster Recovery (DRS) for Windows EC2 instances across multiple regions.

## 🏗️ Architecture Overview

This POC creates a disaster recovery setup with:
- **Primary Region**: Windows EC2 instance with sample web application
- **Secondary Region**: Staging area and recovery infrastructure
- **AWS DRS**: Continuous replication and automated recovery
- **Monitoring**: CloudWatch dashboards and SNS notifications
- **Automation**: Terraform infrastructure as code

## 🎯 Features

- ✅ **Multi-Region Setup**: Primary (us-east-1) and Secondary (us-west-2) regions
- ✅ **Windows Server 2022**: Latest AMI with IIS and sample application
- ✅ **AWS DRS Integration**: Elastic Disaster Recovery with automated failover
- ✅ **Security**: IAM roles, security groups, and KMS encryption
- ✅ **Monitoring**: CloudWatch alarms, dashboards, and SNS notifications
- ✅ **Automation**: Terraform infrastructure deployment
- ✅ **Documentation**: Comprehensive setup guides and runbooks

## 📋 Prerequisites

Before deploying this POC, ensure you have:

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** installed (version >= 1.0)
3. **EC2 Key Pair** created in both regions
4. **AWS DRS service** enabled in your account
5. **Appropriate IAM permissions** for:
   - EC2 (full access)
   - DRS (service role policy)
   - IAM (role creation)
   - KMS (key management)
   - CloudWatch (monitoring)

## 🚀 Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/thinhlh/aws-dr-101.git
cd aws-dr-101

# Create terraform variables file
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit the variables file with your specific values
nano terraform/terraform.tfvars
```

### 2. Deploy Infrastructure

```bash
# Make deploy script executable
chmod +x scripts/deploy.sh

# Plan and deploy (interactive)
./scripts/deploy.sh full

# Or deploy step by step
./scripts/deploy.sh plan
./scripts/deploy.sh apply
```

### 3. Configure DRS

After infrastructure deployment:

1. Connect to the primary Windows instance via RDP
2. Follow the [DRS Setup Guide](docs/drs-setup-guide.md)
3. Install and configure the DRS agent
4. Configure replication settings in DRS console

### 4. Test the Setup

```bash
# Check deployment outputs
./scripts/deploy.sh output

# Access the web applications
# Primary: http://<primary-ip>
# Secondary: http://<secondary-ip>
```

## 📁 Project Structure

```
aws-dr-101/
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Variable definitions
│   ├── vpc.tf                # VPC and networking
│   ├── security_groups.tf    # Security group rules
│   ├── iam.tf                # IAM roles and policies
│   ├── ec2.tf                # EC2 instances
│   ├── drs.tf                # DRS configuration
│   ├── monitoring.tf         # CloudWatch and SNS
│   ├── outputs.tf            # Output definitions
│   ├── terraform.tfvars.example  # Example variables
│   └── scripts/
│       └── windows_userdata.ps1  # Windows initialization script
├── scripts/
│   └── deploy.sh             # Deployment automation script
├── docs/
│   ├── drs-setup-guide.md    # Detailed DRS setup instructions
│   └── disaster-recovery-runbook.md  # Emergency procedures
└── README.md                 # This file
```

## 🔧 Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `primary_region` | Primary AWS region | `us-east-1` |
| `secondary_region` | Secondary AWS region | `us-west-2` |
| `instance_type` | EC2 instance type | `t3.medium` |
| `key_pair_name` | EC2 Key Pair name | **REQUIRED** |
| `enable_drs` | Enable DRS resources | `true` |

### Security Configuration

⚠️ **Important**: Update these settings for production:

```hcl
# Restrict access to specific IP ranges
allowed_cidr_blocks = ["203.0.113.0/24"]  # Your office IP range

# Use larger instance types for production
instance_type = "m5.xlarge"

# Enable detailed monitoring
enable_detailed_monitoring = true
```

## 🏥 Disaster Recovery Procedures

### Automated Failover
1. Monitor CloudWatch alarms for primary region health
2. Access DRS console in secondary region
3. Launch recovery instances from latest snapshot
4. Update DNS records to point to recovery instances
5. Verify application functionality

### Manual Testing
```bash
# Connect to primary instance
rdp <primary-ip>:3389

# Run DR testing script
PowerShell.exe -File C:\dr-test.ps1 -Action full

# Monitor replication lag in DRS console
# Perform drill testing monthly
```

For detailed procedures, see [Disaster Recovery Runbook](docs/disaster-recovery-runbook.md).

## 📊 Monitoring and Alerts

### CloudWatch Dashboards
- **DR Dashboard**: Monitor both primary and secondary instances
- **DRS Metrics**: Replication lag and agent status
- **Application Health**: Response times and error rates

### SNS Notifications
- Instance status check failures
- High CPU utilization alerts
- DRS replication issues

### Key Metrics
- **RTO (Recovery Time Objective)**: < 1 hour
- **RPO (Recovery Point Objective)**: < 15 minutes
- **Replication Lag**: < 1 minute

## 💰 Cost Considerations

### Estimated Monthly Costs (us-east-1/us-west-2)

| Component | Cost/Month |
|-----------|------------|
| Primary EC2 (t3.medium) | ~$30 |
| Secondary EC2 (t3.medium) | ~$30 |
| DRS Staging (t3.small) | ~$15 |
| EBS Storage (300GB) | ~$30 |
| Data Transfer | ~$10 |
| **Total** | **~$115** |

### Cost Optimization Tips
- Use Spot instances for non-critical staging
- Implement lifecycle policies for old snapshots
- Monitor and optimize data transfer
- Schedule instances to run only when needed

## 🔒 Security Features

### Encryption
- **EBS volumes**: Encrypted with customer-managed KMS keys
- **Data in transit**: DRS agent uses encrypted channels
- **Snapshots**: Automatically encrypted

### Network Security
- Private subnets for staging area
- Security groups with minimal required access
- VPC flow logs for network monitoring

### Access Control
- IAM roles with least privilege principle
- Instance profiles for EC2 service access
- MFA recommended for console access

## 🧪 Testing

### Automated Tests
```bash
# Validate Terraform configuration
cd terraform
terraform validate
terraform plan

# Test connectivity
ping <instance-ip>
curl -I http://<instance-ip>
```

### Manual Testing Checklist
- [ ] RDP access to both instances
- [ ] Web application accessibility
- [ ] DRS agent status and replication
- [ ] CloudWatch metrics collection
- [ ] SNS alert delivery
- [ ] DNS failover functionality

## 📚 Documentation

- [DRS Setup Guide](docs/drs-setup-guide.md) - Step-by-step DRS configuration
- [Disaster Recovery Runbook](docs/disaster-recovery-runbook.md) - Emergency procedures
- [AWS DRS Documentation](https://docs.aws.amazon.com/drs/) - Official AWS docs

## 🐛 Troubleshooting

### Common Issues

**DRS Agent Connection Issues**
```powershell
# Check agent status
Get-Service "AWS Replication Agent"

# View agent logs
Get-Content "C:\Program Files (x86)\AWS Replication Agent\logs\agent.log" -Tail 50
```

**High Replication Lag**
- Check network bandwidth between regions
- Verify staging area instance performance
- Monitor disk I/O on source instance

**Launch Template Issues**
- Verify IAM instance profile permissions
- Check security group configurations
- Ensure subnet has available IP addresses

### Support Resources
- AWS Support (if you have a support plan)
- [AWS DRS Troubleshooting Guide](https://docs.aws.amazon.com/drs/latest/userguide/troubleshooting.html)
- Community forums and documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AWS Documentation team for comprehensive DRS guides
- Terraform AWS provider maintainers
- Community contributors and feedback

---

**⚠️ Disclaimer**: This is a POC for learning and demonstration purposes. For production use, implement additional security measures, monitoring, and testing procedures appropriate for your environment.