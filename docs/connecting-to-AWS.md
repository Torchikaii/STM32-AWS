# Connecting to AWS IoT

## CubeMX Configuration

Open `test439/test439.ioc` in STM32CubeMX and apply the following:

1. **Middleware → FREERTOS** → Interface: CMSIS V2

2. **Middleware → FREERTOS → Tasks and Queues** → 
Add task: Name `AWS_IoT_Task`,
Entry Function `Start_AWS_IoT_Task`,
Stack Size (Words): `3072` (12KB),
Priority: `Normal`

3. **Middleware → MBEDTLS** → Enable
4. **Security → RNG** → Mode: Activated
5. **Middleware → LwIP → Key Options → Show Advanced Parameters** →
`LWIP_NETIF_LINK_CALLBACK = enabled`
6. **Middleware → FREERTOS → Config parameters →
Memory management settings** →
`TOTAL_HEAP_SIZE = 32768` (minimum)
7. System Core → SYS → HAL Timebase Source → Change from SysTick to TIM1 (or TIM6/TIM7)

8. Save (Ctrl+S) and regenerate code

> **Tip:** If you can't find an option, use the search bar (top-right) and type the middleware name (e.g., `RNG`, `MBEDTLS`).

### Post-generation: lwipopts.h

`LWIP_DNS` and `LWIP_SNTP` are not available as CubeMX GUI options. Set them manually:

Open `test439/LWIP/Target/lwipopts.h`, add inside `/* USER CODE BEGIN 1 */`:

```c
/* USER CODE BEGIN 1 */
#define LWIP_DNS 1
#define LWIP_SNTP 1
/* USER CODE END 1 */
```

These defines survive code regeneration.

## AWS IoT Setup

### 1. Create Thing
AWS Console → IoT Core → Manage → Things → Create → Create single thing
- Name: `stm32-f439-mvp`
- Device certificate → Auto-generate

### 2. Download Certificates
Place in `secrets/` folder at project root:
- `device.pem.crt`
- `private.pem.key`
- `public.pem.key`
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
