# Phase 4: Infrastructure as Code (EC2 + PostgreSQL)

**Goal:** Create AWS infrastructure via Terraform — EC2 t2.micro control server + RDS PostgreSQL — that interacts with the pre-existing AWS IoT Core (created in Phase 3).

**Prerequisites:**
- Phase 3 complete: STM32 MCU connects to AWS IoT Core, subscribes to `device/<client_id>/command`, publishes telemetry/response to `device/<client_id>/telemetry` and `device/<client_id>/response`
- AWS IoT Core already exists in your AWS account (created via console in Phase 3)
- Terraform v1.5+ installed locally
- AWS CLI v2 installed and configured (`aws configure`)
- Sufficient AWS IAM credentials (Admin or PowerUser)
- Your public IP address (for EC2 SSH access)

**Design choices:**
- Single-AZ to minimize costs (free tier eligible)
- RDS in public subnet with `publicly_accessible = false` — gets private IP only, reachable from EC2 in same subnet
- No NAT Gateway (RDS managed by AWS, doesn't need internet)
- EC2 uses Instance Profile IAM role (SigV4 WebSocket) — no IoT client certificates needed on EC2
- Python AWS IoT Device SDK v2 for MQTT relay on EC2
- Terraform state stored in S3 with DynamoDB locking
- `send-command.sh` CLI wrapper using `aws iot-data publish` (no SDK needed for one-off publishes)

---

## Task 1: Terraform S3 Backend + DynamoDB Locking

**Description:** Create S3 bucket for remote Terraform state and DynamoDB table for state locking. This enables team collaboration and prevents state corruption.

**Steps:**
1. Create `infrastructure/backend.tf` with S3 backend configuration
2. Create `infrastructure/provider.tf` with AWS provider config
3. Create `infrastructure/init.sh` — bootstrap script that creates S3 bucket + DynamoDB table, then runs `terraform init`

**Files to create:**
- `infrastructure/backend.tf`
- `infrastructure/provider.tf`
- `infrastructure/init.sh`

**Validation:**
- [ ] `terraform init` succeeds and shows "Remote State configured"
- [ ] S3 bucket accessible via AWS Console
- [ ] DynamoDB table exists with `LockID` partition key

**Estimated complexity:** Low

---

## Task 2: VPC & Networking

**Description:** Single-AZ VPC with one public subnet. EC2 gets an Elastic IP for SSH access. RDS gets a private IP in the same subnet (reachable from EC2 without NAT).

**Steps:**
1. Create VPC with CIDR `10.0.0.0/16` (configurable via variable)
2. Create public subnet `10.0.1.0/24`
3. Create Internet Gateway and attach to VPC
4. Create public route table with default route `0.0.0.0/0` → Internet Gateway
5. Associate subnet with public route table
6. Allocate Elastic IP for EC2 (static SSH access)

**Files to create:**
- `infrastructure/vpc.tf`

**Validation:**
- [ ] `terraform plan` shows VPC, subnet, IGW, route table being created
- [ ] `terraform apply` completes without errors
- [ ] Subnet shows "Public" in AWS Console (has direct IGW route)

**Estimated complexity:** Medium

**Dependencies:** Task 1

---

## Task 3: Security Groups

**Description:** Restrictive security groups. EC2 allows SSH only from known IPs. RDS allows PostgreSQL only from EC2.

**Steps:**
1. Create `ec2_sg`:
   - Ingress: TCP/22 from `var.ssh_allow_cidr` (your public IP)
   - Egress: All traffic (0.0.0.0/0)
2. Create `rds_sg`:
   - Ingress: TCP/5432 from `ec2_sg` (by security group reference, not CIDR)
   - Egress: All traffic (0.0.0.0/0)

**Files to create:**
- `infrastructure/security_groups.tf`

**Validation:**
- [ ] Security groups created with correct rules
- [ ] RDS SG references EC2 SG by `aws_security_group.ec2_sg.id` (not CIDR)
- [ ] SSH access works from allowed IP only

**Estimated complexity:** Low

**Dependencies:** Task 2

---

## Task 4: RDS PostgreSQL (db.t3.micro)

**Description:** Amazon RDS PostgreSQL instance in the public subnet with a private IP. Auto-generated password stored in AWS Secrets Manager. Schema applied by EC2 on first launch.

**Steps:**
1. Create RDS subnet group (single subnet)
2. Create RDS PostgreSQL instance:
   - Engine: PostgreSQL 14+
   - Instance class: `db.t3.micro`
   - Storage: 20GB GP2 (minimum)
   - Public accessibility: `false`
   - VPC SG: `rds_sg`
   - Master password: random, stored in Secrets Manager
   - Backup retention: 7 days
   - Deletion protection: `false` (enable later for production)
3. Create `infrastructure/schema.sql` with command_log + telemetry tables
4. Output RDS endpoint to Terraform outputs

**Files to create:**
- `infrastructure/rds.tf`
- `infrastructure/schema.sql`

**Validation:**
- [ ] RDS instance reaches "Available" status
- [ ] EC2 can connect via psql using endpoint from outputs
- [ ] Schema tables created (command_log, telemetry)
- [ ] Secret stored in Secrets Manager

**Estimated complexity:** Medium

**Dependencies:** Task 2, Task 3

---

## Task 5: EC2 IAM Instance Profile

**Description:** IAM role and instance profile that allows EC2 to connect to AWS IoT Core via SigV4 WebSocket (no client certs needed). Also allows IoT publish/subscribe/receive.

**Steps:**
1. Create IAM role `ec2-iot-control-role`
2. Create IAM instance profile
3. Attach policy with IoT permissions:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "iot:Connect",
           "iot:Publish",
           "iot:Subscribe",
           "iot:Receive"
         ],
         "Resource": "*"
       }
     ]
   }
   ```
4. Trust policy: `ec2.amazonaws.com` (EC2 assumes this role)

**Files to create:**
- `infrastructure/iam.tf`

**Validation:**
- [ ] Instance profile created and attachable to EC2
- [ ] Policy allows IoT operations
- [ ] Trust policy shows `ec2.amazonaws.com`

**Estimated complexity:** Low

**Dependencies:** None

---

## Task 6: EC2 t2.micro Instance

**Description:** EC2 instance running Amazon Linux 2023. User data script installs dependencies, deploys MQTT relay script as systemd service, and creates the `send-command.sh` CLI tool.

**Steps:**
1. Create EC2 instance:
   - AMI: `amzn2-ami-hvm-*-x86_64-gp2` or Ubuntu 22.04 LTS
   - Instance type: `t2.micro` (free tier)
   - Subnet: public subnet from Task 2
   - SG: `ec2_sg`
   - IAM instance profile: from Task 5
   - Elastic IP: from Task 2
   - User data: install + deploy scripts
2. User data script (`user_data.sh`):
   ```bash
   # Install dependencies
   apt-get update && apt-get install -y python3-pip postgresql-client
   pip3 install awsiotsdk psycopg2-binary
   
   # Fetch RDS credentials from Secrets Manager
   DB_ENDPOINT=$(terraform output -raw rds_endpoint)  # or via tag/SSM
   DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id rds-master-password --query SecretString --output text)
   
   # Apply schema
   psql "host=$DB_ENDPOINT dbname=iot_db user=postgres password=$DB_PASSWORD" -f /opt/stm32-aws/schema.sql
   
   # Deploy MQTT relay service
   cp /opt/stm32-aws/mqtt_relay.py /usr/local/bin/
   cp /opt/stm32-aws/mqtt-relay.service /etc/systemd/system/
   systemctl enable --now mqtt-relay
   
   # Deploy send-command CLI
   cp /opt/stm32-aws/send-command.sh /usr/local/bin/
   chmod +x /usr/local/bin/send-command.sh
   ```

**Files to create:**
- `infrastructure/ec2.tf`
- `infrastructure/user_data.sh`

**Validation:**
- [ ] EC2 instance reaches "running" state
- [ ] Elastic IP attached and SSH accessible
- [ ] User data script runs (check `/var/log/cloud-init-output.log`)
- [ ] MQTT relay service running (`systemctl status mqtt-relay`)
- [ ] psql can connect to RDS

**Estimated complexity:** Medium

**Dependencies:** Task 2, Task 3, Task 5

---

## Task 7: MQTT Relay Script (Python)

**Description:** Python script using AWS IoT Device SDK v2. Connects to IoT Core via WebSocket (SigV4 from EC2 instance profile), subscribes to device topics, and writes received messages to PostgreSQL. Also exposes a `send-command.sh` CLI wrapper.

**Steps:**
1. Create `infrastructure/scripts/mqtt_relay.py`:
   ```
   - Connect to AWS IoT Core via MQTT over WebSocket (SigV4)
   - Subscribe topics:
     - `device/+/telemetry`   (sensor data from MCU)
     - `device/+/response`    (command responses from MCU)
   - On message received:
     - Parse topic to extract device_id
     - Insert into `telemetry` table (topic, payload, device_id, received_at)
   - Handle reconnection with exponential backoff
   - Graceful shutdown on SIGTERM
   ```
2. Create `infrastructure/scripts/send-command.sh`:
   ```bash
   #!/bin/bash
   # Usage: send-command.sh <device_id> <command_json>
   # Example: send-command.sh stm32-f439-mvp-A1B2 '{"led":"on"}'
   DEVICE_ID=$1
   COMMAND=$2
   TOPIC="device/${DEVICE_ID}/command"
   aws iot-data publish --topic "$TOPIC" --payload "$COMMAND"
   ```
3. Create `infrastructure/scripts/mqtt-relay.service` (systemd unit):
   ```
   [Unit]
   Description=STM32-AWS MQTT Relay
   After=network.target
   
   [Service]
   ExecStart=/usr/local/bin/mqtt_relay.py
   Restart=always
   RestartSec=5
   User=ec2-user
   
   [Install]
   WantedBy=multi-user.target
   ```

**Files to create:**
- `infrastructure/scripts/mqtt_relay.py`
- `infrastructure/scripts/send-command.sh`
- `infrastructure/scripts/mqtt-relay.service`

**Validation:**
- [ ] MQTT relay connects to IoT Core and subscribes to topics
- [ ] MCU telemetry/response messages appear in PostgreSQL telemetry table
- [ ] `send-command.sh stm32-f439-mvp-A1B2 '{"led":"on"}'` publishes to correct topic
- [ ] MCU receives command and toggles LED
- [ ] Script reconnects on network disruption

**Estimated complexity:** High

**Dependencies:** Task 5, Task 6

---

## Task 8: Terraform Variables & Outputs

**Description:** Define all configurable variables and useful outputs for the infrastructure.

**Steps:**
1. Create `infrastructure/variables.tf`:
   ```
   variable "aws_region"       { default = "us-east-1" }
   variable "project_name"     { default = "stm32-aws" }
   variable "vpc_cidr"         { default = "10.0.0.0/16" }
   variable "subnet_cidr"      { default = "10.0.1.0/24" }
   variable "ssh_allow_cidr"   { default = "0.0.0.0/0" }  # CHANGE ME
   variable "db_instance_class" { default = "db.t3.micro" }
   ```
2. Create `infrastructure/outputs.tf`:
   ```
   output "ec2_public_ip"       { value = aws_eip.main.public_ip }
   output "ec2_ssh_command"     { value = "ssh ec2-user@${aws_eip.main.public_ip}" }
   output "rds_endpoint"        { value = aws_db_instance.main.endpoint }
   output "rds_database_name"   { value = aws_db_instance.main.db_name }
   ```

**Files to create:**
- `infrastructure/variables.tf`
- `infrastructure/outputs.tf`

**Validation:**
- [ ] `terraform output` shows all expected values
- [ ] Variables have sensible defaults and descriptions
- [ ] `ssh_allow_cidr` has a clear warning to change from default

**Estimated complexity:** Low

**Dependencies:** Tasks 1-7 (references all created resources)

---

## Dependencies

```
Task 1 ─── (backend init)
  │
Task 2 ───────┐
  │           │
  ├──▶ Task 3 ──▶ Task 4 ──┐
  │           │            │
  │           └──▶ Task 6 ──┤
  │                        │
Task 5 ───────────────────▶ Task 6 ──▶ Task 7
  │                                    │
  └────────────────────────────────────┘
                                       │
                                  Task 8 (after all resources)
```

## Implementation Order

| Step | Action |
|------|--------|
| 1 | Run `infrastructure/init.sh` to create S3 + DynamoDB |
| 2 | Run `terraform init` |
| 3 | Run `terraform plan` — verify VPC, SGs, RDS, EC2 |
| 4 | Run `terraform apply` |
| 5 | SSH into EC2, verify MQTT relay is running |
| 6 | Test: `send-command.sh stm32-f439-mvp-XXXX '{"led":"on"}'` |
| 7 | Test: MCU publishes telemetry, verify it appears in PostgreSQL |

## Success Criteria

- [ ] `terraform apply` creates all resources without errors
- [ ] SSH to EC2 works (`ssh ec2-user@<elastic-ip>`)
- [ ] MQTT relay service is running on EC2
- [ ] MCU telemetry messages appear in PostgreSQL `telemetry` table
- [ ] `send-command.sh` delivers command to MCU and LED toggles
- [ ] MCU command responses appear in PostgreSQL
- [ ] Disconnecting/reconnecting EC2 recovers automatically (systemd)
- [ ] `terraform destroy` cleans up all resources
