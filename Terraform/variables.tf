variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "stm32-aws"
}

variable "device_name" {
  description = "IoT device name"
  type        = string
  default     = "stm32-device-001"
}
