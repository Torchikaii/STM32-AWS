# Phase 3: AWS IoT LED Control MVP

**Goal:** Connect STM32F439ZI to AWS IoT Core via MQTT and control PB0 (Green LED) from the cloud.

**Prerequisites:**
- Working ethernet connectivity (static IP 192.168.1.40, pinging OK)
- ARM GCC toolchain installed
- AWS account with IoT Core access

**Design choices:**
- Keep FreeRTOS (task-based architecture)
- Only 1 external library: CoreMQTT
- No coreJSON — use `strstr(payload, "\"led\":\"on\"")` for parsing
- No backoffAlgorithm — use `osDelay(2000)` retry loop
- mbedTLS debug logging enabled (`MBEDTLS_DEBUG_C` required in config for all mbedTLS versions, use `mbedtls_debug_set_threshold(3)` at runtime)
- Certificates as `static const char[]` arrays with `__attribute__((section(".rodata")))` (guaranteed flash, no pointer indirection)
- Blocking sockets with timeouts (simpler for MVP)
- LED heartbeat: slow blink = alive, solid = command, fast blink = error/reconnecting
- Client ID = `stm32-f439-mvp-<mac_suffix>` to avoid collisions
- Topic = `device/<client_id>/command` (matches dynamic client ID)

---

## Task 1: AWS IoT Thing & Certificates Setup

**Description:** Create AWS IoT thing, generate certificates, create policy, attach and activate.

**Steps:**
1. Go to AWS Console → IoT Core → Manage → Things → Create thing → Create single thing
2. Name: `stm32-f439-mvp`
3. Device certificate → Auto-generate (recommended)
4. Download all 3 files: certificate PEM, private key PEM, Amazon Root CA 1
5. Store in `secrets/` folder
6. Create IoT Policy:
   - Action: `iot:*`
   - Resource ARN: `*` (permissive for MVP, tighten later)
7. Attach policy to certificate
8. Activate certificate
9. Note AWS IoT endpoint: Settings → Custom endpoint (format: `xxxxxxxxxx-ats.iot.region.amazonaws.com`)

**Files to create:**
- `secrets/device.pem.crt`
- `secrets/private.pem.key`
- `secrets/AmazonRootCA1.pem`

**Validation:**
- [ ] Certificate status is "ACTIVE" in AWS Console
- [ ] Policy attached to certificate
- [ ] `secrets/` is in `.gitignore`

**Estimated complexity:** Low

**Dependencies:** None

---

## Task 2: CubeMX - Add FreeRTOS, mbedTLS, RNG

**Description:** Enable FreeRTOS (CMSIS V2), mbedTLS, and hardware RNG in `test439.ioc`, regenerate project.

**Steps:**
1. Open `test439.ioc` in STM32CubeMX
2. Middleware → FREERTOS → Interface: CMSIS V2
3. Middleware → MBEDTLS → Enable
4. Security → RNG → Activated (required by mbedTLS for entropy)
5. Verify LwIP already enabled with `LWIP_DNS=1` and `LWIP_SNTP=1`
6. MQTT task stack size (8-16KB) will be set in CubeMX when creating the task (Task 8) — no global FreeRTOS config changes needed
7. Check `configTOTAL_HEAP_SIZE` is sufficient (at least 32KB for mbedTLS + LwIP)
8. Save and regenerate code

**Files to modify:**
- `test439/test439.ioc`
- `test439/Makefile` (regenerated)
- `test439/Middlewares/Third_Party/FreeRTOS/Source/include/FreeRTOSConfig.h` (stack/heap sizing)

**Validation:**
- [ ] `make -C test439` compiles successfully
- [ ] FreeRTOS source present in `test439/Middlewares/Third_Party/FreeRTOS/`
- [ ] mbedTLS source present in `test439/Middlewares/Third_Party/mbedtls/`
- [ ] RNG initialized in generated code

**Estimated complexity:** Low

**Dependencies:** None

---

## Task 3: Add CoreMQTT Submodule

**Description:** Add CoreMQTT as git submodule and wire into Makefile.

**Steps:**
1. `git submodule add https://github.com/FreeRTOS/coreMQTT.git libs/coreMQTT`
 2. Add source files and include paths to `test439/Makefile` (relative to Makefile dir):
     - `../libs/coreMQTT/source/core_mqtt.c`
     - `../libs/coreMQTT/source/core_mqtt_state.c`
  3. Create `test439/Core/Inc/core_mqtt_config.h` — minimal config with required macros:
   ```c
   #ifndef CORE_MQTT_CONFIG_H
   #define CORE_MQTT_CONFIG_H

   #include <stdio.h>

   // Required state array size (minimum 128 for MVP)
   #define MQTT_STATE_ARRAY_SIZE 128
   // Max concurrent operations (1 for MVP)
   #define MQTT_MAX_CONCURRENT_OPERATIONS 1

   // Logging macros (map to printf for MVP)
   #define LogError(...) printf("ERROR: " __VA_ARGS__)
   #define LogWarn(...) printf("WARN: " __VA_ARGS__)
   #define LogInfo(...) printf("INFO: " __VA_ARGS__)
   #define LogDebug(...) // Disable debug for MVP

   #endif // CORE_MQTT_CONFIG_H
   ```

**Files to modify:**
- `.gitmodules` (auto-created)
- `test439/Makefile` (add C_SOURCES and C_INCLUDES to USER CODE sections)

**New files to create:**
- `libs/coreMQTT/` (submodule)
- `test439/Core/Inc/core_mqtt_config.h`

**Validation:**
- [ ] `git submodule status` shows coreMQTT checked out
- [ ] `make -C test439` compiles with coreMQTT sources included

**Estimated complexity:** Medium

**Dependencies:** Task 2

---

## Task 4: SNTP Time Sync Task

**Description:** SNTP is required — mbedTLS will reject AWS certificates without valid system time.

**Steps:**
1. Enable `LWIP_SNTP` in `lwipopts.h` (if not already set by CubeMX)
2. Create `test439/Core/Src/sntp_task.c` — FreeRTOS task that:
    - Calls `sntp_setoperatingmode(SNTP_OPMODE_POLL)`
    - Calls `sntp_setservername(0, "pool.ntp.org")`
    - Defines SNTP sync callback to update `g_unix_epoch`:
      ```c
      volatile time_t g_unix_epoch = 0;

      static void sntp_sync_callback(uint32_t secs, uint32_t frac, int8_t offset) {
          (void)frac; (void)offset;
          g_unix_epoch = (time_t)secs;
      }
      ```
    - Calls `sntp_set_sync_callback(sntp_sync_callback)`
    - Calls `sntp_init()`
    - Polls `g_unix_epoch` in a loop until non-zero (first sync received)
     - Then continues running in background to keep time updated (do NOT terminate task — add `osDelay(60000)` in loop to avoid CPU spin)
  3. Create `test439/Core/Inc/sntp_task.h`
  4. Implement `time_t platform_time(time_t *t)` — returns `volatile time_t g_unix_epoch` that SNTP updates, to be used by mbedTLS:
     ```c
     extern volatile time_t g_unix_epoch;

     time_t platform_time(time_t *t) {
         // 32-bit atomic read (aligned on Cortex-M4, naturally atomic)
         time_t now = g_unix_epoch;
         if (t) *t = now;
         return now;
     }
     ```
      Place this in `sntp_task.c`. Configure mbedTLS to use `platform_time()` via `MBEDTLS_PLATFORM_TIME_ALT` in mbedTLS config (define `MBEDTLS_PLATFORM_TIME_MACRO platform_time`). Do NOT override newlib's `time()` directly (it is not a weak symbol, causing linker errors).

**Files to create:**
- `test439/Core/Src/sntp_task.c`
- `test439/Core/Inc/sntp_task.h`

**Files to modify:**
- `test439/Makefile` (add sources to USER CODE sections)
- `test439/LWIP/Target/lwipopts.h` (enable SNTP via `LWIP_SNTP=1` and configure server with `sntp_setservername()`)
- `test439/Core/Src/stm32f4xx_it.c` or main.c (add `platform_time()` implementation, configure mbedTLS to use it via `MBEDTLS_PLATFORM_TIME_ALT`)

**Validation:**
- [ ] SNTP task starts after `MX_LWIP_Init()`
- [ ] `g_unix_epoch` is set to a reasonable value (> 1700000000)
- [ ] SNTP task does NOT terminate after first sync — keeps updating time

**Estimated complexity:** Medium

**Dependencies:** Task 2

---

## Task 5: Secrets Build Integration & .gitignore

**Description:** Automate converting PEM files to C header at build time, ensure secrets stay out of git.

**Steps:**
1. Add `secrets/` and `test439/Core/Inc/aws_credentials.h` to `.gitignore`
2. Create `scripts/generate_secrets_header.sh` that:
   - Reads `secrets/device.pem.crt`, `secrets/private.pem.key`, `secrets/AmazonRootCA1.pem`
   - Outputs `test439/Core/Inc/aws_credentials.h` with PEM content as `const char[]` arrays (not pointers) in flash
   - Example: `static const char device_cert[] __attribute__((section(".rodata"))) = "...";`
   - Each line properly escaped: `"line\n"`
   - Null-terminated arrays (guaranteed flash storage — avoids pointer indirection/relocation)
3. Add to Makefile: run script as pre-build step
4. If `secrets/` files missing, print: "Missing AWS certificates. See docs/connecting-to-AWS.md"

**Files to create:**
- `scripts/generate_secrets_header.sh`

**Files to modify:**
- `.gitignore`
- `test439/Makefile` (pre-build hook)

**Validation:**
- [ ] `secrets/` not tracked by git
- [ ] `aws_credentials.h` generated before build
- [ ] Generated header declares `static const char[]` arrays (not `const char*` pointers) with `.rodata` attribute
- [ ] Build fails with clear message if secrets missing

**Estimated complexity:** Low

**Dependencies:** Task 1

---

## Task 6: mbedTLS Transport Interface for CoreMQTT

**Description:** Implement the network transport layer — mbedTLS over LwIP blocking sockets with timeouts, SNI, explicit server certificate verification, and debug logging.

**Steps:**
1. Create `test439/Core/Src/mbedtls_transport.c`
   - **Zero-init all mbedTLS structs** before first use: `mbedtls_ssl_init(&ssl); mbedtls_ssl_config_init(&conf);` etc. — makes `_free()` always safe even on partial init
2. Enable mbedTLS debug at init (requires `MBEDTLS_DEBUG_C` in mbedTLS config for all versions):
    ```c
    mbedtls_ssl_conf_dbg(&conf, mbedtls_debug_cb, NULL);
    mbedtls_debug_set_threshold(3);
    ```
3. Configure certificate verification (critical — do NOT skip):
   ```c
   mbedtls_ssl_conf_authmode(&conf, MBEDTLS_SSL_VERIFY_REQUIRED);
   mbedtls_ssl_conf_ca_chain(&conf, &cacert, NULL);
   ```
4. Check `mbedtls_ssl_setup()` return value — fails on memory/config issues:
   ```c
   if (mbedtls_ssl_setup(&ssl, &conf) != 0) {
       printf("FATAL: mbedtls_ssl_setup failed\n");
       return -1;
   }
   ```
5. Use **blocking sockets** with timeouts — simpler for MVP. Handle `MBEDTLS_ERR_SSL_WANT_READ/WRITE` in send/recv loops (these occur at TLS record layer when more data needed, not related to socket mode).
   6. Implement network functions for CoreMQTT:
      - `Transport_Send()` — `mbedtls_ssl_write()` with socket timeout via `SO_SNDTIMEO`
      - `Transport_Recv()` — `mbedtls_ssl_read()` with socket timeout via `SO_RCVTIMEO`
      - Populate `TransportInterface_t` with `send`, `recv`, and `pNetworkContext` (not `Transport_Connect`/`Transport_Disconnect`)
    - Separate `tls_connect()` function — TCP blocking socket to port 8883 → TLS handshake with SNI:
      - Print: `printf("Connecting to %s:8883\n", endpoint);`
      - **Critical:** `mbedtls_ssl_set_hostname(&ssl, endpoint)` for SNI
       - After handshake, verify and log result:
         ```c
         uint32_t flags = mbedtls_ssl_get_verify_result(&ssl);
         if (flags != 0) {
             printf("TLS verify failed: flags=0x%08lx\n", flags);
             char verify_buf[256];
             mbedtls_x509_crt_verify_info(verify_buf, sizeof(verify_buf), "", flags);
             printf("Verify details: %s\n", verify_buf);
         }
         printf("TLS: %s\n", mbedtls_ssl_get_ciphersuite(&ssl));
         ```
    - Separate `tls_disconnect()` function:
      - If `socket_fd >= 0` { close(socket_fd); socket_fd = -1; }
      - Then `mbedtls_ssl_free(&ssl)`, `mbedtls_x509_crt_free(&cacert)`, etc.
  7. Use hardware RNG for entropy: implement `mbedtls_hardware_poll()` that reads from STM32 RNG peripheral:
    ```c
    int mbedtls_hardware_poll(void *data, unsigned char *output, size_t len, size_t *olen) {
        (void)data;
        uint32_t rng_val;
        size_t generated = 0;
        while (generated < len) {
            // Wait for RNG data ready with timeout (prevent hang)
            uint32_t timeout = 1000000;
            while ((RNG->SR & RNG_SR_DRDY) == 0) {
                if (--timeout == 0) return MBEDTLS_ERR_ENTROPY_SOURCE_FAILED;
            }
            rng_val = RNG->DR;
            size_t to_copy = len - generated;
            if (to_copy > 4) to_copy = 4;
            memcpy(output + generated, &rng_val, to_copy);
            generated += to_copy;
        }
        *olen = generated;
        return 0;
    }
    ```
    Use `mbedtls_ctr_drbg_seed(&ctr_drbg, mbedtls_hardware_poll, NULL, NULL, 0);`
8. Set socket timeouts: 1-2 seconds on both `SO_RCVTIMEO` and `SO_SNDTIMEO`
9. On any mbedTLS error, print human-readable message:
   ```c
   char err_buf[128];
   mbedtls_strerror(ret, err_buf, sizeof(err_buf));
   printf("TLS error (%d): %s\n", ret, err_buf);
   ```
10. Create `test439/Core/Inc/mbedtls_transport.h`

**Files to create:**
- `test439/Core/Src/mbedtls_transport.c`
- `test439/Core/Inc/mbedtls_transport.h`

**Files to modify:**
- `test439/Makefile` (add transport files to USER CODE sections)

**Validation:**
- [ ] Compiles without errors
- [ ] Transport functions match CoreMQTT `TransportInterface_t` spec
- [ ] `mbedtls_ssl_setup()` return value checked
- [ ] `MBEDTLS_SSL_VERIFY_REQUIRED` set (server cert verified)
- [ ] `mbedtls_ssl_get_verify_result()` checked after handshake
- [ ] `mbedtls_ssl_set_hostname()` called for SNI before handshake
- [ ] TLS ciphersuite printed after successful handshake
- [ ] Connect log shows `endpoint:8883`
- [ ] Sockets are blocking with timeouts set

**Estimated complexity:** High (this is the hardest task)

**Dependencies:** Task 2, Task 4, Task 5

---

## Task 7: DNS + TCP + TLS Smoke Test

**Description:** Before MQTT, verify DNS resolution, TCP connection, and TLS handshake to AWS IoT endpoint independently.

**Steps:**
1. Create `test439/Core/Src/tls_smoke_test.c`
2. Print endpoint and connect target: `printf("Connecting to %s:8883\n", endpoint);`
  3. Resolve AWS endpoint via LwIP's `dns_gethostbyname()` with callback (async):
    ```c
    static ip_addr_t resolved_ip;
    static volatile bool dns_done = false;
    
    static void dns_callback(const char *name, const ip_addr_t *ipaddr, void *callback_arg) {
        (void)name; (void)callback_arg;
        if (ipaddr != NULL) {
            resolved_ip = *ipaddr;
            dns_done = true;
        }
    }
    
    // In smoke test function:
    dns_done = false;
    err_t err = dns_gethostbyname(endpoint, &resolved_ip, dns_callback, NULL);
    if (err == ERR_OK) {
        dns_done = true; // Already resolved from cache
    } else if (err == ERR_INPROGRESS) {
        // Wait for callback (poll with timeout)
        uint32_t wait_start = osKernelGetTickCount();
        while (!dns_done && (osKernelGetTickCount() - wait_start) < 10000) {
            osDelay(100);
        }
    }
     if (!dns_done) { printf("DNS resolution failed (err=%d)\n", err); return -1; }
    printf("Resolved IP: %s\n", ipaddr_ntoa(&resolved_ip));
    ```
  4. Open TCP socket to resolved IP, port 8883
5. Perform TLS handshake with mbedTLS (same certs as MQTT will use)
6. After handshake, check: `uint32_t flags = mbedtls_ssl_get_verify_result(&ssl);` — print if non-zero
7. Print result: "TLS handshake OK (ciphersuite: ...)" or `mbedtls_strerror()` on failure
8. Retry loop with max attempts:
   - If handshake fails, increment `retry_count`, `osDelay(2000)`, retry
   - If `retry_count > 10`, print "FATAL: TLS handshake failed after 10 retries" and halt (bad cert or config)
9. Block until success — used by MQTT task to ensure connectivity before subscribing
10. Call once at startup

**Files to create:**
- `test439/Core/Src/tls_smoke_test.c`
- `test439/Core/Inc/tls_smoke_test.h`

**Validation:**
- [ ] Prints endpoint string and resolved IP address
- [ ] Prints "TLS handshake OK (ciphersuite: ...)" on serial when endpoint/certs are correct
- [ ] Prints human-readable TLS error code on failure (not just negative number)
- [ ] Verification result checked via `mbedtls_ssl_get_verify_result()`

**Estimated complexity:** Medium

**Dependencies:** Task 5, Task 6, Task 1

---

## Task 8: AWS IoT Connection and MQTT Task

**Description:** Implement the FreeRTOS task that connects to AWS IoT Core, subscribes to command topic, toggles LED, and handles reconnection.

**Steps:**
1. Create `test439/Core/Src/aws_iot_task.c`
2. Create `test439/Core/Inc/aws_iot_task.h`
3. Task priority: set **below** SNTP and LwIP tasks (e.g. `osPriorityNormal` or `osPriorityBelowNormal`) — blocking TLS handshake must not starve critical tasks
4. Task flow:
  - Wait for SNTP time sync
  - Call TLS smoke test — block until pass
    - Generate unique client ID from MAC address:
     ```c
     // Read MAC from LwIP netif (guaranteed valid after MX_LWIP_Init())
     extern struct netif *netif_default;
     if (netif_default == NULL) {
         printf("FATAL: netif_default is NULL\n");
         goto reconnect;
     }
     uint8_t mac[6];
     memcpy(mac, netif_default->hwaddr, 6);
     // Last 2 bytes as hex
     char client_id[32];
     snprintf(client_id, sizeof(client_id), "stm32-f439-mvp-%02X%02X", mac[4], mac[5]);
     ```
    (prevents collision on reconnect)
   - Initialize mbedTLS transport with device cert, key, Root CA
   - `MQTT_Init()` → `MQTT_Connect()` (keepalive=60s)
   - Log CONNACK result:
     ```c
     printf("MQTT CONNACK: sessionPresent=%d\n", sessionPresent);
     ```
      If connect fails, print return code and retry.
    - On successful connect: `retry_count = 0;` (reset backoff)
    - Print free heap after connect: `printf("Free heap: %zu\n", xPortGetFreeHeapSize());`
   - `MQTT_Subscribe()` to `device/<client_id>/command` (QoS 0)
     - e.g. `device/stm32-f439-mvp-XXXX/command` — matches generated client ID
   - Loop: call `MQTT_ProcessLoop(..., timeout_ms)` every 250ms (must be < keepalive/2)
     ```c
     for (;;) {
         MQTTStatus_t status = MQTT_ProcessLoop(&ctx, 250);
         if (status != MQTTSuccess) {
             printf("[MQTT] error %d (ProcessLoop)\n", status);
             goto reconnect;
         }
         // MQTT_ProcessLoop(250) already blocks, no extra delay needed
     }
     ```
   - On disconnect: full cleanup before reconnect to avoid resource leaks:
     ```c
     reconnect:
     mbedtls_ssl_free(&ssl);
     mbedtls_ssl_config_free(&conf);
     mbedtls_x509_crt_free(&cacert);
     mbedtls_ctr_drbg_free(&ctr_drbg);
     close(socket_fd);
      // Simple exponential backoff: 2s → 4s → 8s → ... → cap at 30s
      if (retry_count > 4) retry_count = 4; // Cap to prevent overflow
      uint32_t delay = 2000;
      for (int i = 0; i < retry_count; i++) delay *= 2;
      if (delay > 30000) delay = 30000;
      retry_count++;
      osDelay(delay);
      // reinitialize all TLS structures (mbedtls_ssl_init, mbedtls_ssl_config_init, etc.), reconnect, resubscribe
      ```
     Set LED to fast blink during reconnect.
5. Subscribe callback:
   - Parse with `strstr(payload, "\"led\":\"on\"")` and `strstr(payload, "\"led\":\"off\"")`
   - `HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0, GPIO_PIN_SET/RESET)`
   - Toggle a `led_active` flag for heartbeat logic
6. LED heartbeat:
   - Default: slow blink (500ms on/off) = connected, alive
   - When `{"led":"on"}` received: solid ON
   - When `{"led":"off"}` received: solid OFF
   - Fast blink (100ms on/off) = error / reconnecting
7. UART debug at each step: "Connecting TLS...", "MQTT connected", "Subscribed", "Reconnecting..."
 8. Create `test439/Core/Inc/aws_iot_config.h` for AWS endpoint only (client ID is generated at runtime from MAC)
9. Call `aws_iot_task_start()` from `main.c` after LwIP is up

**Files to create:**
- `test439/Core/Src/aws_iot_task.c`
- `test439/Core/Inc/aws_iot_task.h`
- `test439/Core/Inc/aws_iot_config.h`

**Files to modify:**
- `test439/Core/Src/main.c` (add task startup call after LwIP init)
- `test439/Makefile` (add new sources to USER CODE sections)

**Validation:**
- [ ] Compiles without errors
- [ ] Serial output shows: SNTP synced → DNS resolved → TLS OK → MQTT CONNACK logged → Subscribed → Free heap printed
- [ ] AWS Console Test → subscribe to `$aws/events/#` shows device connection
- [ ] LED slow blinks when connected, solid on/off with MQTT commands, fast blinks during reconnect
- [ ] Reconnect works repeatedly (5+ cycles) without memory/resource leaks
- [ ] `goto reconnect` path fully reinitializes all mbedTLS structs (no stale state)

**Estimated complexity:** High

**Dependencies:** Task 1, Task 4, Task 5, Task 6, Task 7

---

## Task 9: Documentation - connecting-to-AWS.md

**Description:** Create minimal step-by-step guide matching existing doc style (see `docs/getting-started.md` format).

**Files to create:**
- `docs/connecting-to-AWS.md`

**General rules for content:**
- Follow `docs/getting-started.md` structure and formatting exactly
- Include only reproducible steps: CubeMX config, AWS setup, cert placement, build, test
- Use concise imperative language ("click", "run", "place", "open")
- Omit explanations, descriptions, architecture rationale, and code snippets not meant for copy-paste
- Use `---` section separators and fenced code blocks for commands
- Validation: A developer can follow the doc end-to-end without needing to read the plan
- **Note:** `LWIP_DNS` and `LWIP_SNTP` are NOT available in CubeMX GUI — instruct users to add them manually to `lwipopts.h` inside `USER CODE BEGIN 1` section

**Validation:**
- [ ] Doc follows same format as `docs/getting-started.md`
- [ ] All reproducible steps included (CubeMX, AWS, Build, Test)
- [ ] No explanatory text or design descriptions

**Estimated complexity:** Low

**Dependencies:** Tasks 1-8 completed
