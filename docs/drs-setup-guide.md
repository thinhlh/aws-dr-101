# AWS Disaster Recovery Setup Guide

This guide walks you through setting up AWS Elastic Disaster Recovery (DRS) for your Windows EC2 instances.

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **EC2 Key Pair** created in both regions
3. **DRS service enabled** in your AWS account
4. **Appropriate IAM permissions** for DRS operations

## Required Permissions

Ensure your AWS user/role has the following permissions:
- `AWSElasticDisasterRecoveryServiceRolePolicy`
- `EC2FullAccess` (or appropriate EC2 permissions)
- `IAMFullAccess` (for role creation)
- `KMSFullAccess` (for encryption keys)

## Step 1: Install DRS Agent on Primary Instance

### Connect to Primary Instance
1. Use RDP to connect to the primary Windows instance
2. Open PowerShell as Administrator

### Download and Install DRS Agent
```powershell
# Download DRS agent installer
$agentUrl = "https://aws-elastic-disaster-recovery-{region}.s3.{region}.amazonaws.com/latest/windows/AwsReplicationWindowsInstaller.exe"
$agentPath = "C:\temp\AwsReplicationWindowsInstaller.exe"

# Create temp directory
New-Item -ItemType Directory -Path "C:\temp" -Force

# Download agent (replace {region} with your primary region)
Invoke-WebRequest -Uri $agentUrl -OutFile $agentPath

# Install agent
Start-Process -FilePath $agentPath -ArgumentList "/S" -Wait
```

### Configure DRS Agent
```powershell
# Navigate to DRS agent directory
cd "C:\Program Files (x86)\AWS Replication Agent"

# Configure agent with your AWS credentials and staging area
.\aws-replication-installer.exe --region {primary-region} --staging-area-subnet-id {staging-subnet-id} --no-prompt
```

## Step 2: Configure Replication in DRS Console

### Access DRS Console
1. Open AWS Console in your primary region
2. Navigate to **Elastic Disaster Recovery (DRS)**
3. Go to **Source servers**

### Add Source Server
1. Click **Add server**
2. Select your primary Windows instance
3. Configure replication settings:
   - **Staging area subnet**: Use the private subnet in secondary region
   - **Instance type**: t3.small (default)
   - **EBS encryption**: Enabled
   - **Staging area tags**: Add appropriate tags

### Monitor Replication
1. Check **Replication status** in DRS console
2. Wait for **Initial sync** to complete (may take several hours)
3. Monitor **Data replication info** for lag metrics

## Step 3: Configure Launch Settings

### Launch Configuration
1. In DRS console, select your source server
2. Click **Launch settings**
3. Configure:
   - **Instance type**: t3.medium (match primary)
   - **Subnet**: Public subnet in secondary region
   - **Security groups**: Use secondary security group
   - **Instance profile**: Use existing IAM instance profile

### Launch Template
1. Review auto-generated launch template
2. Modify if needed:
   - Instance type
   - Key pair
   - User data scripts

## Step 4: Test Recovery

### Drill Testing
1. In DRS console, select your source server
2. Click **Recovery** > **Launch recovery instances**
3. Choose **Drill** for testing
4. Monitor launch progress
5. Verify application functionality
6. Terminate drill instances when testing complete

### Point-in-Time Recovery
1. Select desired recovery point from available snapshots
2. Launch recovery instance with specific point-in-time
3. Test data consistency and application state

## Step 5: Production Failover

### When Disaster Occurs
1. **Immediate Actions**:
   - Access DRS console from secondary region or mobile device
   - Verify primary region unavailability
   - Notify stakeholders

2. **Execute Failover**:
   ```bash
   # Use AWS CLI if console unavailable
   aws drs start-recovery --source-server-id {server-id} --region {secondary-region}
   ```

3. **Launch Recovery Instances**:
   - Select **Recovery** (not Drill)
   - Choose appropriate recovery point
   - Launch instances in secondary region

4. **Update DNS/Load Balancer**:
   - Point application DNS to new instances
   - Update load balancer targets
   - Verify application accessibility

### Post-Failover Actions
1. **Verify Application**:
   - Test all critical functions
   - Verify data integrity
   - Check user access

2. **Monitor Systems**:
   - Watch CloudWatch metrics
   - Review application logs
   - Monitor user reports

3. **Communication**:
   - Update stakeholders on status
   - Provide ETA for full restoration
   - Document lessons learned

## Step 6: Failback Procedure

### When Primary Region Restored
1. **Prepare Failback**:
   - Ensure primary region fully operational
   - Verify network connectivity
   - Update primary instances if needed

2. **Sync Data**:
   - Use DRS reverse replication if available
   - Or manually sync critical data changes
   - Verify data consistency

3. **Execute Failback**:
   - Schedule maintenance window
   - Stop services on recovery instances
   - Start primary instances
   - Update DNS back to primary
   - Verify application functionality

## Monitoring and Maintenance

### Regular Tasks
- **Weekly**: Review replication lag metrics
- **Monthly**: Perform drill testing
- **Quarterly**: Review and update runbooks
- **Annually**: Test full failover and failback procedure

### Key Metrics to Monitor
- **Replication lag**: Should be < 1 minute for most workloads
- **Agent status**: Should be "Healthy"
- **Bandwidth utilization**: Monitor for bottlenecks
- **Storage usage**: In staging area

### Troubleshooting

#### Common Issues
1. **High replication lag**:
   - Check network bandwidth
   - Verify staging area performance
   - Review disk I/O on source

2. **Agent disconnected**:
   - Verify AWS credentials
   - Check network connectivity
   - Restart DRS agent service

3. **Launch failures**:
   - Verify IAM permissions
   - Check subnet/security group configuration
   - Review instance limits

#### Log Locations
- **DRS Agent logs**: `C:\Program Files (x86)\AWS Replication Agent\logs\`
- **Windows Event Logs**: Check Application and System logs
- **CloudWatch**: Monitor DRS service logs

## Security Considerations

### Data Encryption
- All data encrypted in transit and at rest
- KMS keys managed separately per region
- Regular key rotation recommended

### Network Security
- Staging area in private subnet
- Security groups restrict unnecessary access
- VPC flow logs enabled for monitoring

### Access Control
- IAM roles with least privilege
- MFA required for DRS operations
- Regular access reviews

## Cost Optimization

### DRS Costs
- **Staging area**: Pay for instances during replication
- **Storage**: EBS volumes for replication data
- **Data transfer**: Cross-region replication traffic

### Optimization Tips
- Use appropriate staging instance types
- Clean up old snapshots regularly
- Monitor and optimize replication bandwidth
- Consider data deduplication at application level

## Support and Resources

### AWS Support
- Open support cases for DRS issues
- Use AWS Enterprise Support for critical workloads
- Engage AWS Professional Services for complex scenarios

### Documentation
- [AWS DRS User Guide](https://docs.aws.amazon.com/drs/)
- [DRS API Reference](https://docs.aws.amazon.com/drs/latest/APIReference/)
- [Best Practices Guide](https://docs.aws.amazon.com/drs/latest/userguide/best-practices.html)