# Where flow logs are stored
resource "aws_cloudwatch_log_group" "flow_logs" {
  name              = "/vpc/${var.project_name}-flow-logs"
  retention_in_days = 14

  tags = {
    Name = "${var.project_name}-flow-logs"
  }
}

# Trust policy: let the VPC Flow Logs service assume this role
data "aws_iam_policy_document" "flow_logs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "${var.project_name}-flow-logs"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role.json
}

# Permissions: write to the flow-logs log group only
data "aws_iam_policy_document" "flow_logs" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["${aws_cloudwatch_log_group.flow_logs.arn}:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${var.project_name}-flow-logs"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs.json
}

# Capture all traffic in the VPC
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-flow-logs"
  }
}