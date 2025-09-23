# Disaster Recovery Runbook

## Emergency Contact Information

| Role | Primary Contact | Backup Contact | Phone | Email |
|------|----------------|----------------|-------|-------|
| DR Lead | [Name] | [Name] | [Phone] | [Email] |
| AWS Admin | [Name] | [Name] | [Phone] | [Email] |
| Network Admin | [Name] | [Name] | [Phone] | [Email] |
| Application Owner | [Name] | [Name] | [Phone] | [Email] |

## Incident Response Procedures

### Phase 1: Detection and Assessment (0-15 minutes)

#### Detection Methods
- [ ] CloudWatch alarms triggered
- [ ] Application monitoring alerts
- [ ] User reports of outages
- [ ] Manual system checks

#### Initial Assessment Checklist
- [ ] Verify primary region availability
- [ ] Check AWS Service Health Dashboard
- [ ] Confirm scope of impact (single instance vs. region-wide)
- [ ] Assess estimated duration of outage
- [ ] Determine if DR activation is required

#### Decision Matrix
| Scenario | Action | Authority |
|----------|--------|-----------|
| Single instance failure | Restart/replace instance | Operations Team |
| AZ failure | Failover to other AZ | Operations Team |
| Region-wide outage | Activate DR | DR Lead + Management |
| Extended maintenance | Planned DR test | DR Lead |

### Phase 2: Activation Decision (15-30 minutes)

#### Activation Criteria
- [ ] Primary region unavailable for >30 minutes
- [ ] Critical business functions impacted
- [ ] No estimated recovery time from AWS
- [ ] Data integrity concerns in primary region

#### Stakeholder Notification
```
Subject: DR ACTIVATION - [SEVERITY] - [TIMESTAMP]

Primary Region: [REGION]
Issue: [DESCRIPTION]
Impact: [SCOPE]
DR Lead: [NAME]
Expected RTO: [TIME]

Status updates will be provided every 30 minutes.
```

### Phase 3: DR Execution (30-60 minutes)

#### Pre-Execution Checklist
- [ ] Confirm all team members available
- [ ] Verify secondary region readiness
- [ ] Check latest replication timestamp
- [ ] Validate network connectivity to secondary region
- [ ] Confirm DNS change permissions

#### Execution Steps

##### Step 1: Access Secondary Region
```bash
# Switch AWS CLI to secondary region
export AWS_DEFAULT_REGION=us-west-2

# Verify access
aws sts get-caller-identity
aws ec2 describe-instances --filters "Name=tag:Project,Values=aws-dr-101"
```

##### Step 2: Launch Recovery Instances
```bash
# Access DRS console or use CLI
aws drs start-recovery \
    --source-server-id i-xxxxxxxxx \
    --region us-west-2 \
    --recovery-snapshot-id snap-xxxxxxxxx
```

##### Step 3: Monitor Launch Progress
- [ ] Instance launch initiated
- [ ] Instance status checks passed
- [ ] Application services started
- [ ] Basic functionality verified

##### Step 4: Network Configuration
```bash
# Update Route 53 records to point to DR instances
aws route53 change-resource-record-sets \
    --hosted-zone-id Z123456789 \
    --change-batch file://dns-failover.json

# Verify DNS propagation
nslookup app.company.com
```

##### Step 5: Application Verification
- [ ] Web application accessible
- [ ] Database connectivity confirmed
- [ ] Critical business functions working
- [ ] Performance within acceptable limits

### Phase 4: Communication and Monitoring (Ongoing)

#### Communication Schedule
- **Immediate**: DR activation notification
- **Every 30 minutes**: Status updates during execution
- **Every hour**: Progress updates during operations
- **Upon completion**: Full restoration notification

#### Monitoring Tasks
- [ ] Application performance metrics
- [ ] User access and authentication
- [ ] Data synchronization status
- [ ] Security monitoring in new region
- [ ] Cost monitoring (DR resources)

### Phase 5: Failback Preparation

#### Readiness Criteria
- [ ] Primary region fully operational
- [ ] Root cause identified and resolved
- [ ] Network connectivity restored
- [ ] Data synchronization plan in place

#### Failback Execution
```bash
# Sync data from DR to primary (if needed)
aws s3 sync s3://dr-backup-bucket s3://primary-backup-bucket

# Prepare primary instances
aws ec2 start-instances --instance-ids i-primary-instance

# Verify primary instance health
aws ec2 describe-instance-status --instance-ids i-primary-instance
```

#### DNS Switchback
```bash
# Update Route 53 to point back to primary
aws route53 change-resource-record-sets \
    --hosted-zone-id Z123456789 \
    --change-batch file://dns-failback.json
```

### Testing Procedures

#### Monthly DR Drill
1. **Schedule**: Third Tuesday of each month, 2-4 PM EST
2. **Scope**: Limited functionality test
3. **Duration**: 2 hours maximum
4. **Participants**: DR team + Application owners

#### Quarterly Full Test
1. **Schedule**: Last Saturday of quarter, 6 AM - 12 PM EST
2. **Scope**: Complete failover and failback
3. **Duration**: 6 hours maximum
4. **Participants**: All stakeholders

#### Test Scenarios
- [ ] Primary instance failure
- [ ] AZ-wide outage simulation
- [ ] Network connectivity loss
- [ ] Database corruption scenario
- [ ] Extended region outage

### Key Commands Reference

#### AWS DRS Commands
```bash
# List source servers
aws drs describe-source-servers

# Check replication status
aws drs describe-replication-configuration-templates

# Start recovery
aws drs start-recovery --source-server-id i-xxxxx

# Launch drill
aws drs start-source-network-recovery --deployment-id d-xxxxx
```

#### Monitoring Commands
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids i-xxxxx

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=InstanceId,Value=i-xxxxx \
    --start-time 2023-01-01T00:00:00Z \
    --end-time 2023-01-01T01:00:00Z \
    --period 300 \
    --statistics Average
```

#### Network Commands
```bash
# Test connectivity
ping -c 4 recovery-instance-ip
telnet recovery-instance-ip 3389
curl -I http://recovery-instance-ip

# Check DNS resolution
nslookup app.company.com
dig app.company.com
```

### Recovery Time Objectives (RTO)

| Service Tier | Target RTO | Maximum RTO |
|-------------|------------|-------------|
| Critical (Tier 1) | 1 hour | 2 hours |
| Important (Tier 2) | 4 hours | 8 hours |
| Standard (Tier 3) | 24 hours | 48 hours |

### Recovery Point Objectives (RPO)

| Data Type | Target RPO | Maximum RPO |
|-----------|------------|-------------|
| Transactional Data | 15 minutes | 1 hour |
| Configuration Data | 1 hour | 4 hours |
| Log Data | 1 hour | 8 hours |
| Static Content | 24 hours | 48 hours |

### Post-Incident Review

#### Required Documentation
- [ ] Timeline of events
- [ ] Actions taken
- [ ] Lessons learned
- [ ] Improvement recommendations
- [ ] Cost impact analysis

#### Review Meeting Agenda
1. Incident summary
2. Response timeline review
3. What worked well
4. Areas for improvement
5. Action items and owners
6. Runbook updates needed

### Useful Links

- [AWS DRS Console](https://console.aws.amazon.com/drs/)
- [CloudWatch Dashboard](https://console.aws.amazon.com/cloudwatch/)
- [Route 53 Console](https://console.aws.amazon.com/route53/)
- [AWS Service Health](https://status.aws.amazon.com/)
- [Company Status Page](https://status.company.com/)

### Notes Section

```
Date: ___________
Incident ID: ___________
DR Lead: ___________

Actions Taken:
_________________________________
_________________________________
_________________________________

Issues Encountered:
_________________________________
_________________________________
_________________________________

Follow-up Required:
_________________________________
_________________________________
_________________________________
```