<powershell>
# Windows Server Initial Configuration Script for AWS DR POC
# Project: ${project_name}
# Environment: ${environment}

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

# Create log directory
$LogDir = "C:\AWS-DR-Logs"
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force
}

# Start transcript
Start-Transcript -Path "$LogDir\UserData-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

Write-Host "Starting AWS DR POC Windows Server Configuration..." -ForegroundColor Green

try {
    # Install Windows features
    Write-Host "Installing Windows Features..." -ForegroundColor Yellow
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All -NoRestart

    # Install Chocolatey
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

    # Install useful tools
    Write-Host "Installing tools via Chocolatey..." -ForegroundColor Yellow
    choco install -y awscli
    choco install -y awstools.powershell
    choco install -y notepadplusplus
    choco install -y 7zip
    choco install -y googlechrome

    # Configure AWS CLI (will be configured via IAM role)
    Write-Host "Configuring AWS CLI..." -ForegroundColor Yellow
    
    # Install AWS PowerShell modules
    Write-Host "Installing AWS PowerShell modules..." -ForegroundColor Yellow
    Install-Module -Name AWS.Tools.Common -Force -AllowClobber
    Install-Module -Name AWS.Tools.EC2 -Force -AllowClobber
    Install-Module -Name AWS.Tools.CloudWatch -Force -AllowClobber
    Install-Module -Name AWS.Tools.DRS -Force -AllowClobber

    # Configure Windows Firewall for DRS
    Write-Host "Configuring Windows Firewall for DRS..." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "DRS Agent" -Direction Inbound -Port 1500 -Protocol TCP -Action Allow
    New-NetFirewallRule -DisplayName "AWS SSM" -Direction Inbound -Port 443 -Protocol TCP -Action Allow

    # Create sample web application
    Write-Host "Creating sample web application..." -ForegroundColor Yellow
    $WebRoot = "C:\inetpub\wwwroot"
    $IndexContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>AWS DR POC - ${project_name}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background-color: #f5f5f5; }
        .container { background-color: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { color: #232f3e; border-bottom: 2px solid #ff9900; padding-bottom: 10px; }
        .status { background-color: #d4edda; border: 1px solid #c3e6cb; padding: 10px; border-radius: 4px; margin: 10px 0; }
        .info { background-color: #d1ecf1; border: 1px solid #b8daff; padding: 10px; border-radius: 4px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">AWS Disaster Recovery POC</h1>
        <div class="status">
            <h3>✅ Server Status: Online</h3>
            <p>This is the primary Windows server for the AWS DR demonstration.</p>
        </div>
        <div class="info">
            <h3>Server Information</h3>
            <p><strong>Project:</strong> ${project_name}</p>
            <p><strong>Environment:</strong> ${environment}</p>
            <p><strong>Server Name:</strong> <span id="serverName"></span></p>
            <p><strong>Current Time:</strong> <span id="currentTime"></span></p>
            <p><strong>Instance ID:</strong> <span id="instanceId"></span></p>
            <p><strong>Region:</strong> <span id="region"></span></p>
        </div>
        <div class="info">
            <h3>Disaster Recovery Features</h3>
            <ul>
                <li>AWS Elastic Disaster Recovery (DRS) enabled</li>
                <li>Real-time data replication to secondary region</li>
                <li>Automated failover capabilities</li>
                <li>Point-in-time recovery options</li>
            </ul>
        </div>
    </div>
    
    <script>
        document.getElementById('serverName').textContent = window.location.hostname;
        document.getElementById('currentTime').textContent = new Date().toLocaleString();
        
        // Fetch instance metadata
        fetch('/meta-data/instance-id').then(r => r.text()).then(id => {
            document.getElementById('instanceId').textContent = id;
        }).catch(() => {
            document.getElementById('instanceId').textContent = 'Unable to fetch';
        });
        
        fetch('/meta-data/placement/region').then(r => r.text()).then(region => {
            document.getElementById('region').textContent = region;
        }).catch(() => {
            document.getElementById('region').textContent = 'Unable to fetch';
        });
    </script>
</body>
</html>
"@
    
    $IndexContent | Out-File -FilePath "$WebRoot\index.html" -Encoding UTF8

    # Create a PowerShell script for DR testing
    Write-Host "Creating DR testing script..." -ForegroundColor Yellow
    $DrTestScript = @"
# AWS DR Testing Script
param(
    [Parameter(Mandatory=`$false)]
    [string]`$Action = "status"
)

function Get-DRStatus {
    Write-Host "=== AWS DR Status ===" -ForegroundColor Green
    try {
        `$instanceId = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/instance-id" -TimeoutSec 5
        `$region = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/placement/region" -TimeoutSec 5
        
        Write-Host "Instance ID: `$instanceId" -ForegroundColor Yellow
        Write-Host "Region: `$region" -ForegroundColor Yellow
        Write-Host "Status: Running" -ForegroundColor Green
        Write-Host "Timestamp: `$(Get-Date)" -ForegroundColor Yellow
    }
    catch {
        Write-Host "Error retrieving instance metadata: `$_" -ForegroundColor Red
    }
}

function Test-Application {
    Write-Host "=== Application Health Check ===" -ForegroundColor Green
    try {
        `$response = Invoke-WebRequest -Uri "http://localhost" -TimeoutSec 10
        if (`$response.StatusCode -eq 200) {
            Write-Host "✅ Web application is responding" -ForegroundColor Green
        } else {
            Write-Host "❌ Web application returned status: `$(`$response.StatusCode)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Web application is not responding: `$_" -ForegroundColor Red
    }
}

function Create-TestData {
    Write-Host "=== Creating Test Data ===" -ForegroundColor Green
    `$dataPath = "C:\TestData"
    if (!(Test-Path `$dataPath)) {
        New-Item -ItemType Directory -Path `$dataPath -Force
    }
    
    `$testFile = "`$dataPath\test-`$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    "Test data created at `$(Get-Date)" | Out-File -FilePath `$testFile
    Write-Host "Created test file: `$testFile" -ForegroundColor Yellow
}

switch (`$Action.ToLower()) {
    "status" { Get-DRStatus }
    "test" { Get-DRStatus; Test-Application }
    "data" { Create-TestData }
    "full" { Get-DRStatus; Test-Application; Create-TestData }
    default { 
        Write-Host "Usage: .\dr-test.ps1 [-Action status|test|data|full]" -ForegroundColor Yellow
        Get-DRStatus
    }
}
"@
    
    $DrTestScript | Out-File -FilePath "C:\dr-test.ps1" -Encoding UTF8

    # Configure scheduled task for health monitoring
    Write-Host "Creating health monitoring scheduled task..." -ForegroundColor Yellow
    $TaskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\dr-test.ps1 -Action status >> C:\AWS-DR-Logs\health-check.log"
    $TaskTrigger = New-ScheduledTaskTrigger -RepetitionInterval (New-TimeSpan -Minutes 5) -Once -At (Get-Date)
    Register-ScheduledTask -TaskName "AWS-DR-HealthCheck" -Action $TaskAction -Trigger $TaskTrigger -Description "AWS DR POC Health Check"

    Write-Host "AWS DR POC Windows Server Configuration completed successfully!" -ForegroundColor Green

} catch {
    Write-Host "Error during configuration: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Stop transcript
Stop-Transcript

# Signal completion
Write-Host "Configuration script execution completed." -ForegroundColor Green
</powershell>