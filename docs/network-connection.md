This guide will teach you how to connect your MCU to the network
and succesfully ping it. Complete the steps inside
`docs/getting-started.md` first. 

### 1. Add LWIP stack to the project

**Steps in CubeMX:**
1. Open `test439/test439.ioc`
2. **Middleware and Software Packs > LWIP** -> Check "Enabled"
3. Expand LWIP -> **General Settings**:
   - Check **"Enable ICMP"**
   - Set **DHCP** = Disabled
   - Set **Static IP Configuration**:
     - IP Address: `192.168.1.40`
     - Netmask: `255.255.255.0`
     - Gateway: `192.168.1.1`
4. Add driver. LWIP -> **Platform Settings**
   - set Driver_PHY (IPs or Components) -> LAN8742   
   - set Driver_PHY (Found Solutions) -> LAN8742


### 2. Configure the MCU clocks

**Steps in CubeMX**
1. Open `test439/test439.ioc
2. Click **Clock configuration** tab
3. Apply these PLL settings:
```
PLL_M = 8
PLL_N = 336
PLL_P = 2
PLL_Q = 7
```
After applying PLL settings your clock speeds should be:
```
SYSCLK = 168 MHz
HCLK   = 168 MHz
APB1   = 42 MHz
APB2   = 84 MHz
```
After above steps comeplted,  click "Generate code".

### 3. Call MX_LWIP_Process() in main loop

After generating code in CubeMX, open `Core/Src/main.c` and add the following
inside the while loop (in the `/* USER CODE BEGIN 3 */` section):

```c
while (1)
{
  /* USER CODE BEGIN 3 */
  MX_LWIP_Process();
  /* USER CODE END 3 */
}
```

This is required for lwIP to process received packets and handle timeouts.

### 4. Rebuild and flash

```bash
./compile-flash.sh
```

### 5. Test connectivity

```bash
ping 192.168.1.40
```




