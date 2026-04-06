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
