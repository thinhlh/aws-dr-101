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


                  # Install PM2
                  npm install pm2 -g
              </powershell>
                EOF

  tags = {
    Name = "dsr-windows-server-${each.value.availability_zone}"
  }
}
