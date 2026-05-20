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

### Post-generation: Bare-metal → FreeRTOS transition

When you enable FreeRTOS in CubeMX, the generated LwIP code switches from polling (bare-metal) to interrupt mode. The following manual changes are needed:

#### 0. main.c — call MX_LWIP_Init()

CubeMX generates `MX_LWIP_Init()` in `LWIP/App/lwip.c` but does **not** always insert the call into `main.c`. Without it, LwIP and the Ethernet hardware are never initialized — no traffic flows.

Open `test439/Core/Src/main.c` and add the include and call:

```c
/* USER CODE BEGIN Includes */
#include "lwip.h"
/* USER CODE END Includes */
```

```c
  /* USER CODE BEGIN 2 */

  /* USER CODE END 2 */

  MX_LWIP_Init();             // ← add this before kernel start

  /* Init scheduler */
  osKernelInitialize();
```

`MX_LWIP_Init()` calls `tcpip_init()`, creates the Ethernet interface, and spawns the link-monitoring thread.

#### 1. main.c — remove polling loop

CubeMX generates `MX_LWIP_Process()` inside `main.c`'s while loop. This is for bare-metal mode. Since we use FreeRTOS, LwIP runs in its own `tcpip_thread` — replace it with `osDelay(100)`:

Open `test439/Core/Src/main.c`, find the while loop inside `/* USER CODE BEGIN WHILE */` and change:

```c
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */
    MX_LWIP_Process();       // ← remove this line
    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
```

to:

```c
  /* USER CODE BEGIN WHILE */
  while (1)
  {
    /* USER CODE END WHILE */
    osDelay(100);            // ← add this instead
    /* USER CODE BEGIN 3 */
  }
  /* USER CODE END 3 */
```

This change is inside `USER CODE` sections and survives re-generation.

#### 2. stm32f4xx_it.c — add ETH interrupt handler

CubeMX may not generate `ETH_IRQHandler`. Without it, the Ethernet interrupt goes to `Default_Handler` (system hang). Open `test439/Core/Src/stm32f4xx_it.c` and add inside `/* USER CODE BEGIN Includes */`:

```c
/* USER CODE BEGIN Includes */
#include "stm32f4xx_hal_eth.h"
extern ETH_HandleTypeDef heth;
/* USER CODE END Includes */
```

Then add the handler inside `/* USER CODE BEGIN 1 */` at the bottom:

```c
/* USER CODE BEGIN 1 */
void ETH_IRQHandler(void)
{
  HAL_ETH_IRQHandler(&heth);
}
/* USER CODE END 1 */
```

#### 3. ethernetif.c — enable ETH interrupt in NVIC

The ETH HAL driver needs the NVIC interrupt unmasked. Open `test439/LWIP/Target/ethernetif.c`, find `HAL_ETH_MspInit()` and add inside `/* USER CODE BEGIN ETH_MspInit 1 */`:

```c
  /* USER CODE BEGIN ETH_MspInit 1 */
  HAL_NVIC_SetPriority(ETH_IRQn, 0x5, 0);
  HAL_NVIC_EnableIRQ(ETH_IRQn);
  /* USER CODE END ETH_MspInit 1 */
```

This configures the NVIC to route Ethernet interrupts to `ETH_IRQHandler`.

## SNTP Time Sync

mbedTLS needs valid system time to verify AWS certificate expiry dates. This task fetches time from `pool.ntp.org`.

Create `test439/Core/Inc/sntp_task.h`:

```c
#ifndef SNTP_TASK_H
#define SNTP_TASK_H

#include <time.h>

extern volatile time_t g_unix_epoch;

void Start_SntpTask(void *argument);

#endif
```

Create `test439/Core/Src/sntp_task.c`:

```c
#include "sntp_task.h"
#include "lwip/apps/sntp.h"
#include "cmsis_os2.h"
#include <stdio.h>

volatile time_t g_unix_epoch = 0;

static void sntp_sync_callback(uint32_t secs, uint32_t frac, int8_t offset)
{
    (void)frac;
    (void)offset;
    g_unix_epoch = (time_t)secs;
}

time_t platform_time(time_t *t)
{
    time_t now = g_unix_epoch;
    if (t) *t = now;
    return now;
}

void Start_SntpTask(void *argument)
{
    (void)argument;

    sntp_setoperatingmode(SNTP_OPMODE_POLL);
    sntp_setservername(0, "pool.ntp.org");
    sntp_set_sync_callback(sntp_sync_callback);
    sntp_init();

    printf("[SNTP] Waiting for time sync...\n");
    while (g_unix_epoch == 0) {
        osDelay(100);
    }
    printf("[SNTP] Time synced: %lu\n", (unsigned long)g_unix_epoch);

    for (;;) {
        osDelay(60000);
    }
}
```

In `test439/MBEDTLS/App/mbedtls_config.h`:
- Uncomment `#define MBEDTLS_PLATFORM_TIME_ALT` (around line 216)

This makes mbedTLS call `platform_time()` instead of `time()`, returning our SNTP-synced epoch.

---

## AWS IoT Setup

### 1. Create Thing
AWS Console → IoT Core → Manage → Things → Create → Create single thing
- Name: `stm32-f439-mvp`
- Device certificate → Auto-generate

### 2. Download Certificates
AWS Console → Thing → Security → click on certificate → Download

Place the 3 required files in `~/.secrets/` and rename them as follows:

| Original (AWS Console) | Rename to |
|------------------------|-----------|
| `xxx-certificate.pem.crt` | `stm32-aws-certificate.pem.crt` |
| `xxx-private.pem.key` | `stm32-aws-private.pem.key` |
| `AmazonRootCA1.pem` | `AmazonRootCA1.pem` (keep as-is) |

> `AmazonRootCA3.pem` and `public.pem.key` are also downloaded but not needed for the device.

---

## CoreMQTT Library

This project uses [CoreMQTT](https://github.com/FreeRTOS/coreMQTT) (from the FreeRTOS team) instead of LwIP's built-in MQTT client. Add it as a git submodule:

```bash
git submodule add https://github.com/FreeRTOS/coreMQTT.git libs/coreMQTT
```

This creates `libs/coreMQTT/` with the MQTT source files and a `.gitmodules` entry pinning the version. Anyone cloning the repo should use `git clone --recursive` or run `git submodule update --init` after clone.

> **Note:** If you already cloned the repo without `--recursive`, run `git submodule update --init` to fetch all submodules.

Create `test439/Core/Inc/core_mqtt_config.h`:

```c
#ifndef CORE_MQTT_CONFIG_H
#define CORE_MQTT_CONFIG_H

#include <stdio.h>

#define MQTT_STATE_ARRAY_SIZE            128
#define MQTT_MAX_CONCURRENT_OPERATIONS   1

#define LogError( x )  printf x
#define LogWarn( x )   printf x
#define LogInfo( x )   printf x
#define LogDebug( x )

#endif
```

### 3. Create Policy
AWS Console → IoT Core → Security → Policies → Create
- Action: `iot:*`
- Resource ARN: `*`
- Name: `stm32-f439-mvp-policy`

### 4. Attach & Activate
- Attach policy to certificate
- Activate certificate

### 5. Set Endpoint
AWS Console → IoT Core → Connect → Domain configurations → Domain name

Create `test439/Core/Inc/aws_iot_config.h` with your endpoint:

```c
#ifndef AWS_IOT_CONFIG_H
#define AWS_IOT_CONFIG_H

#define AWS_IOT_ENDPOINT "your-endpoint.iot.us-east-1.amazonaws.com"

#endif
```

---

### 6. Secrets Build Integration

The PEM certificates must be embedded into the firmware binary. A script converts them to C arrays at build time.

```bash
# Ensure the script is executable
chmod +x scripts/generate_secrets_header.sh
```

The Makefile in `test439/` runs this script automatically before each build. It reads from `~/.secrets/` and generates `Core/Inc/aws_credentials.h`.

**If secrets are missing**, the build will fail with:
```
ERROR: Missing ~/.secrets/stm32-aws-certificate.pem.crt
See docs/connecting-to-AWS.md for setup instructions.
```

The generated `aws_credentials.h` is gitignored — certificates never enter the repository.

---

## Build

The project uses FreeRTOS — LwIP runs in its own thread (`tcpip_thread`). No manual polling needed.

```bash
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
