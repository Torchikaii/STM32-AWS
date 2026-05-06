# Connecting to AWS IoT

## CubeMX Configuration

Open `test439/test439.ioc` in STM32CubeMX and apply the following:

1. **Middleware → FREERTOS** → Interface: CMSIS V2
2. **Middleware → FREERTOS → Tasks and Queues** → Add task: `AWS_IoT_Task`, Stack Size (Words): `4096` (16KB), Priority: `Normal`
3. **Middleware → MBEDTLS** → Enable
4. **Security → RNG** → Mode: Activated
5. **Middleware → LwIP → Key Options** → `LWIP_DNS = 1`, `LWIP_SNTP = 1`
6. **Middleware → FREERTOS → Config → Memory Management** → `configTOTAL_HEAP_SIZE = 32768` (minimum)
7. Save (Ctrl+S) to regenerate code

> **Tip:** If you can't find an option, use the search bar (top-right) and type the middleware name (e.g., `RNG`, `MBEDTLS`).

## AWS IoT Setup

### 1. Create Thing
AWS Console → IoT Core → Manage → Things → Create → Create single thing
- Name: `stm32-f439-mvp`
- Device certificate → Auto-generate

### 2. Download Certificates
Place in `secrets/` folder at project root:
- `device.pem.crt`
- `private.pem.key`
- `AmazonRootCA1.pem`

### 3. Create Policy
AWS Console → IoT Core → Security → Policies → Create
- Action: `iot:*`
- Resource ARN: `*`
- Name: `stm32-f439-mvp-policy`

### 4. Attach & Activate
- Attach policy to certificate
- Activate certificate

### 5. Set Endpoint
AWS Console → IoT Core → Settings → Custom endpoint → Copy
Update `AWS_IOT_ENDPOINT` in `test439/Core/Inc/aws_iot_config.h`

---

## Build

```bash
cd test439
make
./compile-flash.sh
```

---

## Test

### Subscribe
IoT Core → Test → MQTT test client → Subscribe
- Topic: `device/stm32-f439-mvp-XXXX/command` (replace XXXX with MAC suffix)

### Publish
IoT Core → Test → MQTT test client → Publish
- Topic: `device/stm32-f439-mvp-XXXX/command`
- Payload: `{"led":"on"}` or `{"led":"off"}`
