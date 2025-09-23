# DRS Agent Installation Script for Windows
# Run this script on the primary Windows instance after deployment

param(
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [Parameter(Mandatory=$true)]
    [string]$StagingSubnetId,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\AWS-DR-Logs\drs-agent-install.log"
)

# Start transcript logging
Start-Transcript -Path $LogPath -Append

Write-Host "Starting DRS Agent Installation..." -ForegroundColor Green
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "Staging Subnet: $StagingSubnetId" -ForegroundColor Yellow

try {
    # Create temp directory
    $TempDir = "C:\temp"
    if (!(Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir -Force
        Write-Host "Created temp directory: $TempDir" -ForegroundColor Green
    }

    # Download DRS agent installer
    $AgentUrl = "https://aws-elastic-disaster-recovery-$Region.s3.$Region.amazonaws.com/latest/windows/AwsReplicationWindowsInstaller.exe"
    $AgentPath = "$TempDir\AwsReplicationWindowsInstaller.exe"
    
    Write-Host "Downloading DRS agent from: $AgentUrl" -ForegroundColor Yellow
    
    try {
        Invoke-WebRequest -Uri $AgentUrl -OutFile $AgentPath -TimeoutSec 300
        Write-Host "✅ DRS agent downloaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to download DRS agent: $_" -ForegroundColor Red
        throw
    }

    # Verify download
    if (!(Test-Path $AgentPath)) {
        throw "Agent installer not found at $AgentPath"
    }
    
    $FileSize = (Get-Item $AgentPath).Length
    Write-Host "Agent installer size: $([math]::Round($FileSize/1MB, 2)) MB" -ForegroundColor Yellow

    # Install DRS agent silently
    Write-Host "Installing DRS agent..." -ForegroundColor Yellow
    $InstallProcess = Start-Process -FilePath $AgentPath -ArgumentList "/S" -Wait -PassThru
    
    if ($InstallProcess.ExitCode -eq 0) {
        Write-Host "✅ DRS agent installed successfully" -ForegroundColor Green
    } else {
        throw "DRS agent installation failed with exit code: $($InstallProcess.ExitCode)"
    }

    # Wait for agent to be available
    Write-Host "Waiting for DRS agent to initialize..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30

    # Configure DRS agent
    $AgentConfigPath = "C:\Program Files (x86)\AWS Replication Agent"
    if (Test-Path $AgentConfigPath) {
        Write-Host "Configuring DRS agent..." -ForegroundColor Yellow
        
        Set-Location $AgentConfigPath
        
        # Configure agent with staging area
        $ConfigArgs = @(
            "--region", $Region,
            "--staging-area-subnet-id", $StagingSubnetId,
            "--no-prompt"
        )
        
        Write-Host "Running configuration with args: $($ConfigArgs -join ' ')" -ForegroundColor Yellow
        
        try {
            $ConfigProcess = Start-Process -FilePath ".\aws-replication-installer.exe" -ArgumentList $ConfigArgs -Wait -PassThru -NoNewWindow
            
            if ($ConfigProcess.ExitCode -eq 0) {
                Write-Host "✅ DRS agent configured successfully" -ForegroundColor Green
            } else {
                Write-Host "⚠️ DRS agent configuration may have issues (exit code: $($ConfigProcess.ExitCode))" -ForegroundColor Yellow
                Write-Host "Check DRS console for agent status and complete configuration manually if needed" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "⚠️ Error during agent configuration: $_" -ForegroundColor Yellow
            Write-Host "You may need to complete configuration manually in DRS console" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "❌ DRS agent installation directory not found" -ForegroundColor Red
        throw "DRS agent not properly installed"
    }

    # Check agent service
    Write-Host "Checking DRS agent service status..." -ForegroundColor Yellow
    
    $AgentService = Get-Service -Name "AWS Replication Agent" -ErrorAction SilentlyContinue
    if ($AgentService) {
        Write-Host "DRS Agent Service Status: $($AgentService.Status)" -ForegroundColor Yellow
        if ($AgentService.Status -eq "Running") {
            Write-Host "✅ DRS agent service is running" -ForegroundColor Green
        } else {
            Write-Host "⚠️ DRS agent service is not running. Starting service..." -ForegroundColor Yellow
            Start-Service -Name "AWS Replication Agent"
            Write-Host "✅ DRS agent service started" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ DRS agent service not found" -ForegroundColor Yellow
    }

    # Provide next steps
    Write-Host "`n=== Next Steps ===" -ForegroundColor Cyan
    Write-Host "1. Open AWS DRS Console in region: $Region" -ForegroundColor White
    Write-Host "2. Navigate to 'Source servers' section" -ForegroundColor White
    Write-Host "3. Verify this server appears in the list" -ForegroundColor White
    Write-Host "4. Monitor initial sync progress" -ForegroundColor White
    Write-Host "5. Configure launch settings when ready" -ForegroundColor White
    Write-Host "`nDRS Console URL: https://console.aws.amazon.com/drs/home?region=$Region" -ForegroundColor Cyan

    Write-Host "`n✅ DRS agent installation completed successfully!" -ForegroundColor Green

} 
catch {
    Write-Host "`n❌ Error during DRS agent installation: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    
    Write-Host "`n=== Troubleshooting Tips ===" -ForegroundColor Yellow
    Write-Host "1. Verify internet connectivity from this instance" -ForegroundColor White
    Write-Host "2. Check IAM permissions for DRS operations" -ForegroundColor White
    Write-Host "3. Ensure security groups allow DRS agent communication" -ForegroundColor White
    Write-Host "4. Try manual installation from DRS console" -ForegroundColor White
    Write-Host "5. Check Windows Event Logs for additional error details" -ForegroundColor White
}
finally {
    # Stop transcript
    Stop-Transcript
    
    # Cleanup installer if requested
    if (Test-Path "$TempDir\AwsReplicationWindowsInstaller.exe") {
        Write-Host "Cleaning up installer file..." -ForegroundColor Yellow
        Remove-Item "$TempDir\AwsReplicationWindowsInstaller.exe" -Force
    }
}

Write-Host "`nInstallation log saved to: $LogPath" -ForegroundColor Cyan
Write-Host "Press any key to continue..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")