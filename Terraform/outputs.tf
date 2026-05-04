data "aws_iot_endpoint" "iot_endpoint" {
  endpoint_type = "iot:Data-ATS"
}

output "iot_endpoint_url" {
  description = "AWS IoT Core endpoint URL"
  value       = data.aws_iot_endpoint.iot_endpoint.endpoint_address
}

output "iot_endpoint_port" {
  description = "AWS IoT Core MQTT port"
  value       = 8883
}

output "device_name" {
  description = "IoT device name"
  value       = aws_iot_thing.device.name
}

output "iot_policy_name" {
  description = "IoT policy name"
  value       = aws_iot_policy.device_policy.name
}
