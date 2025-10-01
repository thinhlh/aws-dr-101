<powershell>
    # Install Node.js
    Invoke-WebRequest -Uri "https://nodejs.org/dist/v18.18.0/node-v18.18.0-x64.msi" -OutFile "C:\\nodejs.msi"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i C:\\nodejs.msi /qn" -Wait

    # Install NSSM - the Non-Sucking Service Manager
    Invoke-WebRequest -Uri "https://nssm.cc/release/nssm-2.24.zip" -OutFile "C:\\nssm.zip"
    Expand-Archive -Path "C:\\nssm.zip" -DestinationPath "C:\\nssm"

    # Install AWS CLI v2
    msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi

    # Install DRS Agent
    Invoke-WebRequest -Uri https://aws-elastic-disaster-recovery-${region}.s3.${region}.amazonaws.com/latest/windows/AwsReplicationWindowsInstaller.exe -OutFile "C:\\AWSDRSAgentSetup.exe"
    C:\\AWSDRSAgentSetup.exe --region ${region} --no-prompt # DRS Drill for all devices

    # Copy below content to file C:\\node.msj

    # Write the Node.js script to a file
    $nodeScript = @"
import os from 'os';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/**
* Get the MAC address of the first network interface
* @returns {string} MAC address or 'Unknown'
*/
function getMacAddress() {
try {
    const networkInterfaces = os.networkInterfaces();

    // Look for the first non-internal interface with a MAC address
    for (const interfaceName in networkInterfaces) {
    const interfaces = networkInterfaces[interfaceName];
    for (const iface of interfaces) {
        if (!iface.internal && iface.mac && iface.mac !== '00:00:00:00:00:00') {
        return iface.mac;
        }
    }
    }
    return 'Unknown';
} catch (error) {
    console.error('Error getting MAC address:', error.message);
    return 'Unknown';
}
}

/**
* Get the local IP address
* @returns {string} IP address or 'Unknown'
*/
function getIpAddress() {
try {
    const networkInterfaces = os.networkInterfaces();

    // Look for the first non-internal IPv4 interface
    for (const interfaceName in networkInterfaces) {
    const interfaces = networkInterfaces[interfaceName];
    for (const iface of interfaces) {
        if (!iface.internal && iface.family === 'IPv4') {
        return iface.address;
        }
    }
    }
    return 'Unknown';
} catch (error) {
    console.error('Error getting IP address:', error.message);
    return 'Unknown';
}
}

/**
* Create log entry with current timestamp, MAC address, and IP address
*/
function createLogEntry() {
const timestamp = new Date().toISOString();
const macAddress = getMacAddress();
const ipAddress = getIpAddress();

return {
    timestamp: timestamp,
    macAddress: macAddress,
    ipAddress: ipAddress,
    hostname: os.hostname(),
    platform: os.platform(),
    arch: os.arch()
};
}

/**
* Write log entry to file
*/
function writeToLog() {
try {
    const logEntry = createLogEntry();
    const logDir = path.join(__dirname, '..', 'logs');

    // Ensure logs directory exists
    if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
    }

    // Create filename with current date
    const date = new Date().toISOString().split('T')[0]; // YYYY-MM-DD format
    const logFile = path.join(logDir, "system-info-" + date + ".log");

    // Format log entry
    const logLine = JSON.stringify(logEntry, null, 2) + '\n' + '-'.repeat(50) + '\n';

    // Append to log file
    fs.appendFileSync(logFile, logLine);

    console.log('System information logged successfully:');
    console.log("Timestamp: " + logEntry.timestamp);
    console.log("MAC Address: " + logEntry.macAddress);
    console.log("IP Address: " + logEntry.ipAddress);
    console.log("Hostname: " + logEntry.hostname);
    console.log("Platform: " + logEntry.platform);
    console.log("Architecture: " + logEntry.arch);

} catch (error) {
    console.error('Error writing to log file:', error.message);
}
}

// Run the script (ES modules equivalent of require.main === module)
if (fileURLToPath(import.meta.url) === process.argv[1]) {
console.log('Starting system info logger - will log every 1 minute...');
console.log('Press Ctrl+C to stop the logger');

// Run immediately on start
writeToLog();

// Then run every 1 minute (60000 milliseconds)
const intervalId = setInterval(writeToLog, 60000);

// Handle graceful shutdown
process.on('SIGINT', () => {
    console.log('\nShutting down system info logger...');
    clearInterval(intervalId);
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\nShutting down system info logger...');
    clearInterval(intervalId);
    process.exit(0);
});
}
"@

    $scriptPath = "C:\\Users\\Administrator\\node.mjs"
    $nodeScript | Out-File -FilePath $scriptPath -Encoding UTF8

    # Install the Node.js script as a Windows service using NSSM
    $nssmPath = "C:\\nssm\\nssm-2.24\\win64\\nssm.exe"
    $serviceName = "NodeLog"
    $nodePath = "C:\\Program Files\\nodejs\\node.exe"
    & $nssmPath install $serviceName $nodePath $scriptPath
    & $nssmPath set $serviceName Start SERVICE_AUTO_START
    Start-Service $serviceName
    Write-Host "Service '$serviceName' installed and started."

    # Clean up
    Remove-Item "C:\\nodejs.msi"
    Remove-Item "C:\\AWSDRSAgentSetup.exe"


    # Download SSM Agent
    [System.Net.ServicePointManager]::SecurityProtocol = 'TLS12'
    $progressPreference = 'silentlyContinue'
    Invoke-WebRequest `
        https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe `
        -OutFile $env:USERPROFILE\Desktop\SSMAgent_latest.exe
    Start-Process `
    -FilePath $env:USERPROFILE\Desktop\SSMAgent_latest.exe `
    -ArgumentList "/S" `
    -Wait
    rm -Force $env:USERPROFILE\Desktop\SSMAgent_latest.exe
    Restart-Service AmazonSSMAgent
</powershell>