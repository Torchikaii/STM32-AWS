resource "aws_iot_thing" "device" {
  name = var.device_name
  attributes = {
    project = var.project_name
  }
}

resource "aws_iot_policy" "device_policy" {
  name = "${var.project_name}-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${var.aws_region}:*:client/${var.device_name}",
          "arn:aws:iot:${var.aws_region}:*:topic/${var.device_name}/*",
          "arn:aws:iot:${var.aws_region}:*:topicfilter/${var.device_name}/*"
        ]
      }
    ]
  })
}
