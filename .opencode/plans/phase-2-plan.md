# Phase 2 Plan: Ethernet Driver & Static IP Ping

**Goal:** Get STM32F439 to respond to ICMP ping with static IP configuration

**Prerequisites:**
- Current test439 project with ETH peripheral configured (RMII mode)
- CubeMX 6.15.0 installed
- ARM GCC toolchain installed

---

#### Task 1: Configure LwIP in CubeMX

**Description:** Add LwIP middleware to test439.ioc with static IP and ICMP enabled.

**Steps in CubeMX:**
1. Open `test439/test439.ioc`
2. **Middleware and Software Packs > LWIP** > Check "Enabled"
3. Expand LWIP > **General Settings**:
   - Check **"Enable ICMP"**
   - Set **DHCP** = Disabled
   - Set **Static IP Configuration**:
     - IP Address: `192.168.1.40`
     - Netmask: `255.255.255.0`
     - Gateway: `192.168.1.1`
 4. **RMII Clock Configuration** - The LAN8742A PHY provides the 50MHz RMII reference clock to the STM32 via PA8. Configure PA8 as ETH_REF_CLK (input). No MCO1 source configuration needed - the PHY drives the clock.
   5. **Project Manager** > Generate Code

**Files to modify:**
- `test439/test439.ioc`

**New files created:**
- `test439/Middlewares/LWIP/` (LwIP source files)
- `test439/Core/Src/lwip.c` (CubeMX-generated)
- `test439/Core/Inc/lwipopts.h` (configuration)

**Validation:**
- [ ] CubeMX generates without errors
- [ ] `Middlewares/LWIP/` directory exists with sources
- [ ] `lwipopts.h` contains static IP configuration

**Estimated complexity:** Low

---

#### Task 2: Configure lwipopts.h for Ping

**Description:** Ensure ICMP is enabled and set appropriate buffer sizes.

**File to modify:**
- `test439/Core/Inc/lwipopts.h`

**Key settings to verify/add:**
```c
#define LWIP_ICMP                    1
#define LWIP_UDP                     1
#define LWIP_TCP                     1
#define DEFAULT_THREAD_STACKSIZE     1024
#define TCPIP_THREAD_STACKSIZE       2048
```

**Validation:**
- [ ] `LWIP_ICMP` is set to 1
- [ ] File compiles without errors

**Estimated complexity:** Low

---

#### Task 3: Add LwIP Polling to main.c

**Description:** Call MX_LWIP_Process() to handle network stack.

**File to modify:**
- `test439/Core/Src/main.c`

**Changes:**

After MX calls (around line 106):
```c
/* USER CODE BEGIN 2 */
MX_LWIP_Process();
/* USER CODE END 2 */
```

In main loop (around line 112):
```c
while (1)
{
  MX_LWIP_Process();
  HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_7);
  HAL_Delay(1000);
}
```

**Validation:**
- [ ] Code compiles successfully
- [ ] No linker errors about missing LwIP functions

**Estimated complexity:** Low

---

#### Task 4: Verify PHY Initialization

**Description:** Check that LAN8742A is properly initialized.

**File to modify:**
- `test439/Core/Src/main.c` or `lwip.c` (if PHY init needed)

**If needed, add PHY reset/initialization:**
```c
/* In MX_LWIP_Init or after MX_ETH_Init */
HAL_ETH_WritePHYRegister(&heth, 0, 0x00, 0x8000); /* Reset PHY */
HAL_Delay(100);
/* Wait for auto-negotiation to complete */
uint32_t status;
do {
    HAL_ETH_ReadPHYRegister(&heth, 0, 0x01, &status);
} while (!(status & 0x04)); /* Wait for link up */
```

**Validation:**
- [ ] Code compiles
- [ ] LEDs or debug output indicate link status

**Estimated complexity:** Medium

---

#### Task 5: Build Project

**Description:** Compile the project and verify successful build.

**Command:**
```bash
cd /home/pc/repos/STM32-AWS/test439
make clean
make -j$(nproc)
```

**Expected output:**
- `build/test439.elf`
- `build/test439.bin`
- No errors

**Validation:**
- [ ] `make` exits with code 0
- [ ] ELF file exists in build/
- [ ] No undefined reference errors

**Estimated complexity:** Low

---

#### Task 6: Flash to MCU

**Description:** Flash the compiled firmware to STM32F439.

**Command:**
```bash
cd /home/pc/repos/STM32-AWS/test439
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg \
  -c "program build/test439.elf verify reset exit"
```

**Alternative (using ST-Link CLI):**
```bash
ST-LINK_CLI -c SWD -p build/test439.bin -Rst
```

**Validation:**
- [ ] openocd reports successful programming
- [ ] MCU resets and runs

**Estimated complexity:** Low

---

#### Task 7: Network Setup

**Description:** Configure PC network to communicate with MCU.

**Steps:**
1. Connect STM32 ethernet to your router/switch
2. Connect PC to same network
3. Configure PC static IP on same subnet:

**Linux:**
```bash
sudo ip addr add 192.168.1.50/24 dev eth0
sudo ip route add default via 192.168.1.1
```

**Windows:** Network Settings > IPv4 > Static IP `192.168.1.50`, subnet `255.255.255.0`, gateway `192.168.1.1`

**Validation:**
- [ ] PC can ping gateway (router) at 192.168.1.1
- [ ] Physical cable connection verified

**Estimated complexity:** Low

---

#### Task 8: Test Ping

**Description:** Verify MCU responds to ICMP echo requests.

**Command:**
```bash
ping 192.168.1.40
```

**Expected output:**
```
PING 192.168.1.40 (192.168.1.40) 56(84) bytes of data.
64 bytes from 192.168.1.40: icmp_seq=1 ttl=64 time=X ms
```

**Validation:**
- [ ] MCU responds to ping
- [ ] Latency is reasonable (< 10ms on local network)

**Estimated complexity:** Low

---

## Troubleshooting Tasks (If Ping Fails)

### Task T1: Verify RMII Clock

**Check:** Oscilloscope on PA8 should show 50MHz square wave (clock coming FROM PHY, not from STM32).

**Note:** The LAN8742A PHY generates and outputs the 50MHz clock to PA8. This is the standard robust configuration - the STM32 receives the clock, it does not generate it.

### Task T2: Check Link Status

**Add debug output in main.c:**
```c
uint32_t link_status;
HAL_ETH_ReadPHYRegister(&heth, 0, 0x01, &link_status);
if (link_status & 0x04) {
    /* Link is up */
} else {
    /* Link is down - check cable, PHY, etc */
}
```

### Task T3: Verify MAC Address

**Ensure MAC is set correctly in MX_ETH_Init:**
```c
MACAddr[0] = 0x00;
MACAddr[1] = 0x80;
MACAddr[2] = 0xE1; /* STMicroelectronics OUI */
MACAddr[3] = 0x00;
MACAddr[4] = 0x00;
MACAddr[5] = 0x00;
```

---

## Summary

| Order | Task | Validation | Complexity |
|-------|------|------------|------------|
| 1 | Configure LwIP in CubeMX | No errors, files generated | Low |
| 2 | Verify lwipopts.h | ICMP enabled | Low |
| 3 | Add polling to main.c | Code compiles | Low |
| 4 | PHY init (if needed) | Link detected | Medium |
| 5 | Build | ELF created | Low |
| 6 | Flash | MCU programmed | Low |
| 7 | Network setup | PC on subnet | Low |
| 8 | Test ping | MCU responds | Low |

---

## Success Criteria

- [ ] `ping 192.168.1.40` returns responses from MCU
- [ ] Latency is stable (< 10ms typical for local network)
- [ ] MCU continues responding to ping after multiple requests
