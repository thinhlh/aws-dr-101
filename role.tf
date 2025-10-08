# IAM role for SSM
resource "aws_iam_role" "project_ec2_role" {
  name        = "drs-ec2-role"
  description = "IAM role for EC2 instances to access SSM and DRS services"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sts:AssumeRole"
        ],
        Principal = {
          Service = [
            "ec2.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "project_ssm_attach" {
  role       = aws_iam_role.project_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "project_drs_attach" {
  role       = aws_iam_role.project_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticDisasterRecoveryEc2InstancePolicy"
}

resource "aws_iam_role_policy_attachment" "project_drs_recovery_policy_attach" {
  role       = aws_iam_role.project_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticDisasterRecoveryRecoveryInstancePolicy"
}

resource "aws_iam_instance_profile" "project_ec2_profile" {
  name = "drs-ec2-profile"
  role = aws_iam_role.project_ec2_role.name
}