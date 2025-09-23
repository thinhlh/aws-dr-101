# IAM role for SSM
resource "aws_iam_role" "project_ec2_role" {
  name = "dsr-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "project_ssm_attach" {
  role       = aws_iam_role.project_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "project_dsr_attach" {
  role       = aws_iam_role.project_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticDisasterRecoveryEc2InstancePolicy"
}

resource "aws_iam_instance_profile" "project_ec2_profile" {
  name = "dsr-ec2-profile"
  role = aws_iam_role.project_ec2_role.name
}
