# Phase 3: AWS IoT Core MVP

**Goal:** Establish MQTT connection between STM32 and AWS IoT Core with basic telemetry publishing.

**Prerequisites:**
- Ethernet connectivity working (ping verified)
- STM32CubeMX project with LwIP enabled

---

#### Task 1: Create Terraform Infrastructure for IoT Core

**Description:** Create minimal Terraform setup for AWS IoT Core (thing + policy only). Certificate handling is manual by user via AWS Console to avoid leaking secrets.

**New files to create:**
- `Terraform/main.tf` - AWS provider and backend
- `Terraform/variables.tf` - Input variables (region, project name)
- `Terraform/iot-core.tf` - IoT Thing and policy (no certs)
- `Terraform/outputs.tf` - IoT endpoint URL
- `Terraform/.gitignore` - Ignore state files

**Note:** Certificates must be created manually by user via AWS Console or AWS CLI. See `docs/aws-setup.md` for instructions.

**Validation:**
- [ ] `terraform init` succeeds
- [ ] `terraform plan` shows 2 resources (thing + policy)
- [ ] `terraform apply` creates IoT thing and outputs endpoint

**Estimated complexity:** Low

---

#### Task 2: Create Device-Side AWS Configuration

**Description:** Create AWS configuration header with endpoint, topics, and paths to local certificate files (not committed to repo).

**New files to create:**
- `test439/Inc/aws_config.h` - AWS endpoint, port, device ID, topic definitions, cert paths
- `test439/Src/aws_config.c` - Default values

**Note:** Certificates (`device.pem`, `device.key`, `AmazonRootCA1.pem`) stored locally by user, not in repo. Config points to paths like `/secrets/device.pem`.

**Validation:**
- [ ] Header compiles without errors
- [ ] Defines match PRD topic structure (`device/{device_id}/telemetry`)

**Estimated complexity:** Low

---

#### Task 2.5: Create AWS Setup Documentation

**Description:** Document how user creates IoT Core thing and certificates manually via AWS Console.

**New files to create:**
- `docs/aws-setup.md` - Step-by-step guide for AWS IoT Core provisioning

**Validation:**
- [ ] User can follow steps to create IoT thing
- [ ] User can download certificates from AWS Console
- [ ] User knows where to place cert files locally

**Estimated complexity:** Low

---

#### Task 3: Implement MQTT Client Module

**Description:** Create MQTT connection wrapper using LwIP's built-in mqtt.c. Implement connect, publish (QoS 0), and subscribe functions.

**New files to create:**
- `test439/Src/aws_mqtt.c` - MQTT client implementation
- `test439/Inc/aws_mqtt.h` - Public API

**Validation:**
- [ ] `mqtt_connect()` establishes connection to AWS endpoint
- [ ] `mqtt_publish()` sends message with QoS 0
- [ ] `mqtt_subscribe()` receives messages on topic

**Estimated complexity:** Medium

---

#### Task 4: Integrate AWS MQTT into Main Application

**Description:** Modify main.c to initialize MQTT on startup, connect to AWS, and publish telemetry periodically.

**Files to modify:**
- `test439/Core/Src/main.c` - Add MQTT initialization and main loop integration

**Validation:**
- [ ] Device connects to AWS IoT Core on startup
- [ ] Telemetry message appears in IoT Core MQTT test client
- [ ] Subscribed commands are received and logged

**Estimated complexity:** Low

---

#### Task 5: Add CI/CD Workflow for Terraform

**Description:** Create GitHub Actions workflow to plan/apply Terraform infrastructure.

**New files to create:**
- `.github/workflows/terraform.yml` - Terraform init, validate, plan, apply

**Validation:**
- [ ] Workflow runs `terraform validate` on PR
- [ ] `terraform plan` output visible in PR checks
- [ ] Manual trigger for `terraform apply` on main branch

**Estimated complexity:** Low

---

## Dependencies

```
Task 1 (Terraform) ──────┐
                        ├──> Task 4 (Integration) ---> Task 5 (CI/CD)
Task 2 (aws_config.h) ──┘
Task 3 (MQTT module) ────┘
```

## Security Notes

- **Certificates never committed to repo**
- User creates IoT Core thing/certs via AWS Console
- Cert files stored in `/secrets/` directory (gitignored)
- `docs/aws-setup.md` will document manual certificate provisioning
- Only public IoT endpoint URL stored in code/config
