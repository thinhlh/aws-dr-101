resource "aws_instance" "windows" {
  for_each               = aws_subnet.project_subnet_private_us_east_1
  ami                    = local.ami
  instance_type          = local.instance_type
  subnet_id              = each.value.id
  vpc_security_group_ids = [aws_security_group.windows_sg.id]

  iam_instance_profile = aws_iam_instance_profile.project_ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
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
                  Invoke-WebRequest -Uri https://aws-elastic-disaster-recovery-us-east-1.s3.us-east-1.amazonaws.com/latest/windows/AwsReplicationWindowsInstaller.exe -OutFile "C:\\AWSDRSAgentSetup.exe"
                  C:\\AWSDRSAgentSetup.exe --region us-east-1 --no-prompt # DRS Drill for all devices

                  # Clean up
                  Remove-Item "C:\\nodejs.msi"
                  Remove-Item "C:\\AWSDRSAgentSetup.exe"
              </powershell>
                EOF

  tags = {
    Name = "drs-windows-server-${each.value.availability_zone}"
  }
}
