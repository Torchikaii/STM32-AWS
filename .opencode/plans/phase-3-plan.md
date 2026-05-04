# Phase 3: AWS IoT Core MVP (FreeRTOS)

**Goal:** Establish MQTT connection between STM32 and AWS IoT Core with controlled telemetry publishing.

**Architecture:**
- Use FreeRTOS with coreMQTT-Agent library (thread-safe MQTT)
- Task-based architecture: MQTT runs as background task
- CRITICAL: Rate limiting on telemetry to prevent billing shock

**Prerequisites:**
- Ethernet connectivity working (ping verified)
- STM32CubeMX project with FreeRTOS enabled
- LwIP configured for FreeRTOS+TCP

---

## CRITICAL: Rate Limiting Requirements

**AWS IoT Core Pricing Context:**
- IoT Core charges per million messages
- Uncontrolled loops can generate 1M+ messages in minutes
- Must implement publish rate limiting IN CODE

**Rate Limit Configuration:**
```c
#define TELEMETRY_PUBLISH_INTERVAL_MS  60000  // 1 message per 60 seconds minimum
#define TELEMETRY_PUBLISH_INTERVAL_MS  300000 // 5 minutes recommended for cost safety
```

**Implementation MUST have:**
- [x] Fixed interval between publishes (no busy-loop)
- [x] Exponential backoff on connection failure
- [x] Publish attempts counter with circuit breaker

---

#### Task 1: Create Terraform Infrastructure for IoT Core

**Description:** Create minimal Terraform setup for AWS IoT Core (thing + policy only). Certificate handling is manual by user via AWS Console to avoid leaking secrets.

**New files to create:**
- `Terraform/main.tf` - AWS provider and backend
- `Terraform/variables.tf` - Input variables (region, project name)
- `Terraform/iot-core.tf` - IoT Thing and policy (no certs)
- `Terraform/outputs.tf` - IoT endpoint URL
- `Terraform/.gitignore` - Ignore state files

**Certificates:** Must be created manually by user via AWS Console. See `docs/aws-setup.md`.

**Validation:**
- [ ] `terraform fmt -check` passes
- [ ] `terraform validate` succeeds

---

#### Task 2: Create Device-Side AWS Configuration (FreeRTOS)

**Description:** AWS configuration header with FreeRTOS-compatible settings. Uses FreeRTOS+TLS sockets.

**New files to create/modify:**
- `test439/Inc/aws_config.h` - Endpoint, port, device ID, topics, CERT PATHS, RATE LIMITS
- `test439/Src/aws_config.c` - Config getter functions

**CRITICAL CONFIG:**
```c
// Rate limiting - prevents billing shock
#define TELEMETRY_PUBLISH_INTERVAL_MS  300000  // 5 minutes (FREERTOS default)
#define MQTT_KEEPALIVE_SECONDS        600     // 10 minutes (reduce IoT Core messages)

#define AWS_IOT_ENDPOINT             "xxxxx.iot.eu-central-1.amazonaws.com"
#define AWS_IOT_PORT                8883
#define AWS_DEVICE_ID               "stm32-device-001"

#define AWS_CERT_PATH               "/secrets/device.pem"
#define AWS_KEY_PATH                "/secrets/device.key"
#define AWS_ROOT_CA_PATH           "/secrets/AmazonRootCA1.pem"
```

**Validation:**
- [ ] Header compiles without errors
- [ ] RATE LIMIT defined (TELEMETRY_PUBLISH_INTERVAL_MS >= 30000)

---

#### Task 2.5: Create AWS Setup Documentation

**Description:** Document how user creates IoT Core thing, certificates, and critical rate limiting settings.

**New files to create:**
- `docs/aws-setup.md` - Full AWS IoT Core provisioning guide

**Must include:**
- [ ] Warning about IoT Core per-message pricing
- [ ] Default rate limit explanation
- [ ] How to change publish interval

---

#### Task 3: Integrate FreeRTOS coreMQTT-Agent Library

**Description:** Add FreeRTOS with coreMQTT-Agent for thread-safe MQTT. Include as git submodule or vendor library.

**Submodules to add:**
- `FreeRTOS/` - Main FreeRTOS kernel (GitHub: FreeRTOS/FreeRTOS)
- `coreMQTT/` - MQTT client (GitHub: FreeRTOS/coreMQTT)
- `coreMQTT-Agent/` - Thread-safe wrapper (GitHub: FreeRTOS/coreMQTT-Agent)
- `corePKCS11/` - TLS/certificates (GitHub: FreeRTOS/corePKCS11)
- `coreJSON/` - JSON parsing (GitHub: FreeRTOS/coreJSON)
- `backoffAlgorithm/` - Retry logic (GitHub: FreeRTOS/backoffAlgorithm)

**Files to create:**
- `.gitmodules` - Submodule configuration
- `freertos-config/` - FreeRTOSConfig.h with IoT settings

**Directory structure:**
```
test439/
├── Middlewares/
│   └── FreeRTOS/           # Submodule
│       ├── FreeRTOS/
│       └── libraries/
│           └── freertos_plus_aws/
│               └── iot_sdk_config.h
```

**CRITICAL: Memory Configuration**
```c
// In FreeRTOSConfig.h
#define configTOTAL_HEAP_SIZE           ( 32 * 1024 )  // 32KB heap for MQTT agent
#define configMQTT_AGENT_TASK_STACK_SIZE ( 4096 )      // 4KB stack
#define configMQTT_AGENT_TASK_PRIORITY  ( tskIDLE_PRIORITY + 2 )
```

**Validation:**
- [ ] FreeRTOS builds without errors
- [ ] Idle task runs

---

#### Task 4: Implement MQTT Application with Rate Limiting

**Description:** Create application code using FreeRTOS MQTT Agent API with CRITICAL rate limiting.

**Files to modify:**
- `test439/Core/Src/main.c` - FreeRTOS app with MQTT
- `test439/Src/app_aws.c` - AWS IoT task with telemetry
- `test439/Inc/app_aws.h` - Task declaration

**Application Architecture:**

```c
// app_aws.h
typedef struct {
    char device_id[32];
    uint32_t telemetry_interval_ms;  // CRITICAL: Must be >= 30000
    uint32_t telemetry_counter;
    MQTTAgentHandle_t mqtt_handle;
    StaticQueue_t command_queue;
} AppAwsContext;

// app_aws.c
void vAwsTelemetryTask(void *pvParameters)
{
    AppAwsContext *ctx = (AppAwsContext *)pvParameters;
    TickType_t last_publish = xTaskGetTickCount();
    
    while (1) {
        // CRITICAL: Wait interval BEFORE publishing (not after!)
        vTaskDelayUntil(&last_publish, pdMS_TO_TICKS(ctx->telemetry_interval_ms));
        
        // Only publish AFTER delay, not in busy loop
        if (mqtt_connected) {
            snprintf(payload, sizeof(payload),
                "{\"device\":\"%s\",\"counter\":%lu}",
                ctx->device_id, ctx->telemetry_counter++);
            MQTT_Publish(ctx->mqtt_handle, TELEMETRY_TOPIC, payload, strlen(payload));
        }
    }
}
```

**CRITICAL IMPLEMENTATION RULES:**
1. [ ] Use `vTaskDelayUntil()` for fixed interval (NOT busy loop)
2. [ ] `telemetry_interval_ms >= 30000` (30 seconds minimum, 5 min recommended)
3. [ ] Interval in config header, not magic number
4. [ ] Error handling with backoff (not retry loop)
5. [ ] Publish counter tracked

**Validation:**
- [ ] Fixed interval between publishes (check with logic analyzer)
- [ ] No more than 1 message per telemetry_interval_ms
- [ ] Connection loss handled gracefully

---

#### Task 5: Integrate FreeRTOS + MQTT into Main Application

**Description:** Initialize FreeRTOS, start MQTT Agent task, start application tasks.

**Files to modify:**
- `test439/Core/Src/main.c` - FreeRTOS startup

**Implementation:**

```c
// FreeRTOS main - simple scheduler
int main(void)
{
    // Hardware init (HAL)
    SystemClock_Config();
    MX_GPIO_Init();
    MX_LWIP_Init();
    
    // Create MQTT Agent task (higher priority)
    xTaskCreate(vAwsMqttAgentTask, "MQTT", 
                configMQTT_AGENT_TASK_STACK_SIZE,
                NULL,
                configMQTT_AGENT_TASK_PRIORITY,
                NULL);
    
    // Create telemetry task (lower priority)
    xTaskCreate(vAwsTelemetryTask, "Telemetry",
                4096,
                NULL,
                tskIDLE_PRIORITY + 1,
                NULL);
    
    // Start scheduler
    vTaskStartScheduler();
    
    // Should not reach here
    while (1);
}
```

**Validation:**
- [ ] FreeRTOS starts successfully
- [ ] MQTT connects to AWS IoT Core
- [ ] Telemetry interval >= 30 seconds

---

#### Task 6: Add CI/CD Workflow for Terraform

**Description:** Create GitHub Actions workflow to plan/apply Terraform infrastructure.

**New files:**
- `.github/workflows/terraform.yml` - Terraform CI/CD

**Validation:**
- [ ] `terraform fmt` check passes in PR
- [ ] `terraform validate` succeeds
- [ ] Plan output visible in PR

---

## Migration: Bare Metal → FreeRTOS

### Remove (Phase 3 bare metal approach):
- `test439/Src/aws_mqtt.c` - LwIP MQTT (deprecated)
- `test439/Inc/aws_mqtt.h` - LwIP MQTT header

### New (FreeRTOS approach):
- `FreeRTOS/` submodule with coreMQTT-Agent
- `test439/Src/app_aws.c` - Application using MQTT Agent API
- Rate limiting in application task

---

## Validation Summary

### Functional:
- [ ] Device connects to AWS IoT Core
- [ ] Telemetry published to `device/{id}/telemetry`
- [ ] Commands received on `device/{id}/command`

### Rate Limiting (CRITICAL):
- [ ] Telemetry interval >= 30 seconds
- [ ] No busy loops in code
- [ ] Publish rate logged for debugging
- [ ] Exponential backoff on failure

### Cost Safety:
- [ ] Maximum ~288 messages/day at 5-minute interval
- [ ] Keep-alive configured (not ping every message)

---

## Security Notes

- **Certificates never committed** - stored in `/secrets/`
- **Endpoint URL public** - OK to commit (not sensitive)
- **Rate limit in header** - Clear for users to modify

---

## Cost Estimation

| Interval | Messages/day | Messages/month | Est. Cost* |
|----------|-------------|----------------|------------|
| 5 sec     | 17,280        | 518,400        | ~$50/mo   |
| 30 sec    | 2,880         | 86,400         | ~$8/mo    |
| 60 sec    | 1,440         | 43,200         | ~$4/mo    |
| 5 min     | 288          | 8,640          | ~$1/mo    |

*AWS IoT Core pricing: ~$0.08/million messages (first 250B free)

---

## Dependencies

```
Task 1 (Terraform) ──────┐
                         ├──> Task 2 (AWS Config) ──> Task 2.5 (Docs)
Task 3 (FreeRTOS) ──────────────────────┤
                                     ├──> Task 4 (App MQTT)
Task 6 (CI/CD) <──────────────────────┘
```