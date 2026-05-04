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
- mbedTLS debug logging enabled (`MBEDTLS_DEBUG_C` for 3.x or `mbedtls_debug_set_threshold(3)` for 2.x)
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
6. Set MQTT task stack size to 8-16KB in FreeRTOS config
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
2. Add source files and include paths to `test439/Makefile`:
   - `source/core_mqtt.c`
   - `source/core_mqtt_state.c`
   - `source/core_mqtt_serializer.c`
3. Create `libs/coreMQTT/source/include/core_mqtt_config.h` — minimal config defining logging macros

**Files to modify:**
- `.gitmodules` (auto-created)
- `test439/Makefile` (add C_SOURCES and C_INCLUDES)

**New files to create:**
- `libs/coreMQTT/` (submodule)
- `libs/coreMQTT/source/include/core_mqtt_config.h`

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
   - Calls `sntp_init()`
   - Blocks until first SNTP sync received
   - Then continues running in background to keep time updated (do NOT terminate task)
3. Create `test439/Core/Inc/sntp_task.h`
4. Implement `time_t time(time_t *t)` override — returns `volatile time_t g_unix_epoch` (signed, toolchain-safe) that SNTP updates:
   ```c
   volatile time_t g_unix_epoch;

   time_t time(time_t *t) {
       // 32-bit atomic read (aligned on Cortex-M4, naturally atomic)
       time_t now = g_unix_epoch;
       if (t) *t = now;
       return now;
   }
   ```
   mbedTLS will use this automatically.

**Files to create:**
- `test439/Core/Src/sntp_task.c`
- `test439/Core/Inc/sntp_task.h`

**Files to modify:**
- `test439/Makefile` (add sources)
- `test439/LWIP/Target/lwipopts.h` (enable SNTP, or use modern LwIP 2.x `sntp_get_servers()` API)
- `test439/Core/Src/stm32f4xx_it.c` or main.c (add `time()` override)

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
2. Enable mbedTLS debug at init (use `MBEDTLS_DEBUG_C` config for 3.x, or `mbedtls_debug_set_threshold(3)` for 2.x):
   ```c
   mbedtls_ssl_conf_dbg(&conf, mbedtls_debug_cb, NULL);
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
6. Implement CoreMQTT `TransportInterface_t`:
   - `Transport_Connect()` — TCP blocking socket to port 8883 → TLS handshake with SNI
     - Print: `printf("Connecting to %s:8883\n", endpoint);`
     - **Critical:** `mbedtls_ssl_set_hostname(&ssl, endpoint)` for SNI
     - After handshake, verify and log result:
       ```c
       uint32_t flags = mbedtls_ssl_get_verify_result(&ssl);
       if (flags != 0) {
           printf("TLS verify failed: flags=0x%08lx\n", flags);
       }
       printf("TLS: %s\n", mbedtls_ssl_get_ciphersuite(&ssl));
       ```
   - `Transport_Send()` — `mbedtls_ssl_write()` with socket timeout via `SO_SNDTIMEO`
   - `Transport_Recv()` — `mbedtls_ssl_read()` with socket timeout via `SO_RCVTIMEO`
   - `Transport_Disconnect()` — close socket, `mbedtls_ssl_free()`, `mbedtls_net_free()`
7. Use hardware RNG for entropy: `mbedtls_ctr_drbg_seed()` with `mbedtls_hardware_poll()` via STM32 RNG peripheral
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
- `test439/Makefile` (add transport files)

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
3. Resolve AWS endpoint via `getaddrinfo()` — print resolved IP: `printf("Resolved IP: %s\n", ip);`
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
3. Task flow:
   - Wait for SNTP time sync
   - Call TLS smoke test — block until pass
   - Generate unique client ID: `stm32-f439-mvp-XXXX` where `XXXX` = last 2 bytes of MAC address (prevents collision on reconnect)
   - Initialize mbedTLS transport with device cert, key, Root CA
   - `MQTT_Init()` → `MQTT_Connect()` (keepalive=60s)
   - Log CONNACK result:
     ```c
     printf("MQTT CONNACK: sessionPresent=%d\n", sessionPresent);
     ```
     If connect fails, print return code and retry.
   - Print free heap after connect: `printf("Free heap: %zu\n", xPortGetFreeHeapSize());`
   - `MQTT_Subscribe()` to `device/<client_id>/command` (QoS 0)
     - e.g. `device/stm32-f439-mvp-XXXX/command` — matches generated client ID
   - Loop: call `MQTT_ProcessLoop(..., timeout_ms)` every 250ms (must be < keepalive/2)
     ```c
     for (;;) {
         MQTTStatus_t status = MQTT_ProcessLoop(&ctx, 250);
         if (status != MQTTSuccess) {
             printf("MQTT error %d, reconnecting...\n", status);
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
     osDelay(2000);
     // reinitialize all TLS structures, reconnect, resubscribe
     ```
     Set LED to fast blink during reconnect.
4. Subscribe callback:
   - Parse with `strstr(payload, "\"led\":\"on\"")` and `strstr(payload, "\"led\":\"off\"")`
   - `HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0, GPIO_PIN_SET/RESET)`
   - Toggle a `led_active` flag for heartbeat logic
5. LED heartbeat:
   - Default: slow blink (500ms on/off) = connected, alive
   - When `{"led":"on"}` received: solid ON
   - When `{"led":"off"}` received: solid OFF
   - Fast blink (100ms on/off) = error / reconnecting
6. UART debug at each step: "Connecting TLS...", "MQTT connected", "Subscribed", "Reconnecting..."
7. Create `test439/Core/Inc/aws_iot_config.h` for endpoint and client identifier
8. Call `aws_iot_task_start()` from `main.c` after LwIP is up

**Files to create:**
- `test439/Core/Src/aws_iot_task.c`
- `test439/Core/Inc/aws_iot_task.h`
- `test439/Core/Inc/aws_iot_config.h`

**Files to modify:**
- `test439/Core/Src/main.c` (add task startup call after LwIP init)
- `test439/Makefile` (add new sources)

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

**Exact content structure:**

```markdown
# Connecting to AWS IoT

## One-time Setup

### 1. Create IoT Thing
AWS Console → IoT Core → Manage → Things → Create → Create single thing
- Name: `stm32-f439-mvp`
- Device certificate → Auto-generate

### 2. Download Certificates
Download all 3 files and place in `secrets/` folder in project root:
- Device certificate → `secrets/device.pem.crt`
- Private key → `secrets/private.pem.key`
- Amazon Root CA 1 → `secrets/AmazonRootCA1.pem`

### 3. Create IoT Policy
AWS Console → IoT Core → Security → Policies → Create
- Action: `iot:*`
- Resource ARN: `*`
- Name: `stm32-f439-mvp-policy`

### 4. Attach Policy & Activate
- Attach policy to certificate
- Activate certificate

### 5. Note Your Endpoint
Settings → Custom endpoint → Copy: `xxxxxxxxxx-ats.iot.region.amazonaws.com`
Update in `test439/Core/Inc/aws_iot_config.h`

---

## Build

### Place certificates
Put all 3 PEM files in `secrets/` folder.

### Build firmware
```bash
cd test439
make
```

### Flash
```bash
./compile-flash.sh
```

---

## Test

### Subscribe in AWS Console
IoT Core → Test → MQTT test client → Subscribe
- Topic: `device/stm32-f439-mvp-XXXX/command` (replace XXXX with MAC suffix)

### Publish to control LED
IoT Core → Test → MQTT test client → Publish
- Topic: `device/stm32-f439-mvp-XXXX/command` (replace XXXX with MAC suffix)
- Payload: `{"led":"on"}` or `{"led":"off"}`
```

**Validation:**
- [ ] Doc follows same format as `docs/getting-started.md` (sections, minimal text, code blocks)
- [ ] Someone following the doc can replicate the setup without guessing

**Estimated complexity:** Low

**Dependencies:** Tasks 1-8 completed
