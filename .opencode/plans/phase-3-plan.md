# Phase 3: AWS IoT LED Control MVP

**Goal:** Connect STM32F439ZI to AWS IoT Core via MQTT and control PB0 (Green LED) from the cloud.

**Prerequisites:**
- Working ethernet connectivity (static IP 192.168.1.40, pinging OK)
- ARM GCC toolchain installed
- AWS account with IoT Core access

---

## Task 1: AWS IoT Thing & Certificates Setup

**Description:** Create AWS IoT thing, generate certificates, create policy, attach and activate.

**Steps:**
1. Go to AWS Console → IoT Core → Manage → Things → Create thing → Create single thing
2. Name: `stm32-f439-mvp`
3. Device certificate → Auto-generate (recommended)
4. Download all 4 files: certificate PEM, private key PEM, Amazon Root CA 1, RSA 2048-bit key
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
5. Verify LwIP already enabled (it is) with `LWIP_DNS=1`
6. Set FreeRTOS task stack sizes generously (MQTT task will need 8-16KB)
7. Save and regenerate code

**Files to modify:**
- `test439/test439.ioc`
- `test439/Makefile` (regenerated)

**Validation:**
- [ ] `make -C test439` compiles successfully
- [ ] FreeRTOS source present in `test439/Middlewares/Third_Party/FreeRTOS/`
- [ ] mbedTLS source present in `test439/Middlewares/Third_Party/mbedtls/`
- [ ] RNG initialized in generated code

**Estimated complexity:** Low

**Dependencies:** None

---

## Task 3: Add FreeRTOS Library Submodules

**Description:** Add CoreMQTT, coreJSON, and backoffAlgorithm as git submodules and wire into Makefile.

**Steps:**
1. `git submodule add https://github.com/FreeRTOS/coreMQTT.git libs/coreMQTT`
2. `git submodule add https://github.com/FreeRTOS/coreJSON.git libs/coreJSON`
3. `git submodule add https://github.com/FreeRTOS/backoffAlgorithm.git libs/backoffAlgorithm`
4. Add source files and include paths to `test439/Makefile`
   - coreMQTT: `source/core_mqtt.c`, `source/core_mqtt_state.c`, `source/core_mqtt_serializer.c`
   - coreJSON: `source/core_json.c`
   - backoffAlgorithm: `source/include/backoff_algorithm.h`, `source/backoff_algorithm.c`

**Files to modify:**
- `.gitmodules` (auto-created)
- `test439/Makefile` (add C_SOURCES and C_INCLUDES)

**New files to create:**
- `libs/coreMQTT/` (submodule)
- `libs/coreJSON/` (submodule)
- `libs/backoffAlgorithm/` (submodule)

**Validation:**
- [ ] `git submodule status` shows all three checked out
- [ ] `make -C test439` includes the new sources
- [ ] Build succeeds

**Estimated complexity:** Medium

**Dependencies:** Task 2

---

## Task 4: SNTP Time Sync Task

**Description:** SNTP is required — mbedTLS will reject AWS certificates without valid system time.

**Steps:**
1. Enable `LWIP_SNTP` in LwIP configuration (CubeMX or `lwipopts.h`)
2. Create `test439/Core/Src/sntp_task.c` — FreeRTOS task that:
   - Calls `sntp_setoperatingmode(SNTP_OPMODE_POLL)`
   - Calls `sntp_setservername(0, "pool.ntp.org")`
   - Calls `sntp_init()`
   - Waits until `sntp_get_sync_status()` returns synced
   - Sets a global `time_synced` flag
3. Create `test439/Core/Inc/sntp_task.h`
4. Provide `sntp_update_system_time()` callback that sets the UNIX epoch into a global variable (mbedTLS needs this)

**Files to create:**
- `test439/Core/Src/sntp_task.c`
- `test439/Core/Inc/sntp_task.h`

**Files to modify:**
- `test439/Makefile` (add sources)
- `test439/LWIP/Target/lwipopts.h` (enable SNTP)

**Validation:**
- [ ] SNTP task starts after `MX_LWIP_Init()`
- [ ] System time is synced (serial output or LED blink confirms)

**Estimated complexity:** Medium

**Dependencies:** Task 2

---

## Task 5: mbedTLS Transport Interface for CoreMQTT

**Description:** Implement the network transport layer that CoreMQTT requires — mbedTLS over LwIP sockets with non-blocking I/O and timeouts.

**Steps:**
1. Create `test439/Core/Src/mbedtls_transport.c`
2. Implement CoreMQTT transport interface:
   - `Transport_Connect()` — TCP socket → TLS handshake
   - `Transport_Send()` — non-blocking send with `SO_RCVTIMEO`/`SO_SNDTIMEO`
   - `Transport_Recv()` — non-blocking recv with timeout
   - `Transport_Disconnect()` — close socket, free TLS context
3. Use hardware RNG for mbedTLS entropy: `mbedtls_hardware_poll()` via STM32 RNG peripheral
4. Create `test439/Core/Inc/mbedtls_transport.h`

**Files to create:**
- `test439/Core/Src/mbedtls_transport.c`
- `test439/Core/Inc/mbedtls_transport.h`

**Files to modify:**
- `test439/Makefile` (add transport files)

**Validation:**
- [ ] Compiles without errors
- [ ] Transport functions match CoreMQTT `TransportInterface_t` spec
- [ ] Socket timeouts set (no infinite blocking)

**Estimated complexity:** High

**Dependencies:** Task 2, Task 3, Task 4

---

## Task 6: TCP + TLS Smoke Test

**Description:** Before MQTT, verify TCP connection and TLS handshake to AWS IoT endpoint independently.

**Steps:**
1. Create `test439/Core/Src/tls_smoke_test.c`
2. Opens TCP socket to AWS IoT endpoint port 8883
3. Performs TLS handshake using mbedTLS
4. Prints success/failure via UART
5. This isolates networking/TLS issues from MQTT logic
6. Can be called once at startup before MQTT task starts

**Files to create:**
- `test439/Core/Src/tls_smoke_test.c`
- `test439/Core/Inc/tls_smoke_test.h`

**Validation:**
- [ ] Prints "TLS handshake OK" on serial when endpoint/certs are correct
- [ ] Prints clear error on failure (wrong cert, wrong endpoint, no DNS, etc.)

**Estimated complexity:** Medium

**Dependencies:** Task 5, Task 1 (need valid certs + endpoint)

---

## Task 7: AWS IoT Connection and MQTT Task

**Description:** Implement the FreeRTOS task that connects to AWS IoT Core and subscribes to the command topic.

**Steps:**
1. Create `test439/Core/Src/aws_iot_task.c`
2. Create `test439/Core/Inc/aws_iot_task.h`
3. Task flow:
   - Wait for SNTP time sync
   - Initialize mbedTLS transport with device cert, key, Root CA
   - `MQTT_Init()` → `MQTT_Connect()` (keepalive=60s)
   - `MQTT_Subscribe()` to `device/stm32-f439-mvp/command` (QoS 0)
   - `MQTT_ProcessLoop()` in loop
   - On disconnect: reconnect using `backoffAlgorithm` (exponential backoff)
4. Create `test439/Core/Inc/aws_iot_config.h` for endpoint and client identifier
5. Credentials loaded from `secrets/` at compile time (via build script)
6. UART debug output at each step: TLS status, MQTT connect result, subscribe result
7. Call `aws_iot_task_start()` from `main.c` after `MX_LWIP_Init()` and SNTP synced

**Files to create:**
- `test439/Core/Src/aws_iot_task.c`
- `test439/Core/Inc/aws_iot_task.h`
- `test439/Core/Inc/aws_iot_config.h`
- `scripts/generate_secrets_header.sh` (converts PEM files to C string header)

**Files to modify:**
- `test439/Core/Src/main.c` (add task startup call after SNTP)
- `test439/Makefile` (add new sources, run secrets script)

**Validation:**
- [ ] Compiles without errors
- [ ] Device connects to AWS IoT (verified via AWS Console → Test → Subscribe to `$aws/events/#`)
- [ ] Serial output shows connection status at each step

**Estimated complexity:** High

**Dependencies:** Task 1, Task 4, Task 5, Task 6

---

## Task 8: LED Command Handler

**Description:** Parse incoming MQTT messages and toggle PB0 LED accordingly.

**Steps:**
1. In `aws_iot_task.c`, register `MQTT_Subscribe()` callback for `device/stm32-f439-mvp/command`
2. Use coreJSON to parse: `{"led": "on"}` / `{"led": "off"}`
3. Call `HAL_GPIO_WritePin(GPIOB, GPIO_PIN_0, GPIO_PIN_SET/RESET)`
4. Publish acknowledgment: `device/stm32-f439-mvp/response` with `{"status": "ok"}` (QoS 0)

**Files to modify:**
- `test439/Core/Src/aws_iot_task.c` (add message handler)

**Validation:**
- [ ] Publish `{"led": "on"}` to `device/stm32-f439-mvp/command` → LED turns on
- [ ] Publish `{"led": "off"}` to `device/stm32-f439-mvp/command` → LED turns off
- [ ] Response message received on `device/stm32-f439-mvp/response`

**Estimated complexity:** Medium

**Dependencies:** Task 7

---

## Task 9: Secrets Build Integration & .gitignore

**Description:** Automate converting PEM files to C header at build time, ensure secrets stay out of git.

**Steps:**
1. Add `secrets/` to `.gitignore`
2. Create `scripts/generate_secrets_header.sh` that:
   - Reads `secrets/device.pem.crt`, `secrets/private.pem.key`, `secrets/AmazonRootCA1.pem`
   - Outputs `test439/Core/Inc/aws_credentials.h` with PEM content as C strings
   - Ensures proper escaping, null-termination, newlines preserved
3. Add to Makefile: run script as pre-build step
4. Add `aws_credentials.h` to `.gitignore`
5. If `secrets/` files missing, print clear error: "Missing AWS certificates. See docs/connecting-to-AWS.md"

**Files to create:**
- `scripts/generate_secrets_header.sh`

**Files to modify:**
- `.gitignore`
- `test439/Makefile` (pre-build hook)

**Validation:**
- [ ] `secrets/` not tracked by git
- [ ] `aws_credentials.h` generated before build
- [ ] Build fails with clear message if secrets missing

**Estimated complexity:** Low

**Dependencies:** None (can be done anytime before Task 7)

---

## Task 10: Documentation - connecting-to-AWS.md

**Description:** Create minimal step-by-step guide for setting up AWS IoT connection.

**Files to create:**
- `docs/connecting-to-AWS.md`

**Content:**
- AWS Console: create thing, generate certs, create policy, activate
- Place certs in `secrets/`
- Build: `make` (auto-generates credentials header)
- Test: AWS IoT Test → publish `{"led":"on"}` to `device/stm32-f439-mvp/command`

**Validation:**
- [ ] Someone following the doc can replicate the setup

**Estimated complexity:** Low

**Dependencies:** Tasks 1-9 completed
