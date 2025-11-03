First schematics file is in: PCB_Project -> PCB_Start -> Sheet1.SchDoc or PCB_Start.PcbDoc
Second schematics file is in: PCB_Project -> Power_and_ST-link_zone.SchDoc,Peripherals.SchDoc, Signal_Switching.SchDoc, MCU_H7.SchDoc, MCU_L4.SchDoc, MCU_WL.SchDoc or PCB_Project.PcbDoc.


Sheet1 description:
1. ? Power supply zone
This zone takes 5V from the USB-C connector and converts it into a stable 3.3V supply that powers the entire board.

J1 (USB4515...): USB-C Connector. This is the main power input for the board (receives +5V).

R1, R2 (5.1k): CC Resistors. These are required by the USB-C specification. They signal to the power source (like a charger) that the board requests 5V.

U1 (AP2112K...): LDO Regulator. This is the most important component in the zone. It "steps down" the 5V input to a stable +3.3V output, which will power all the MCUs and modules.

C1 (10uF): Input Filter Capacitor. It stabilizes the 5V input before it enters the U1 regulator, removing noise.

C2 (10uF): Output Filter Capacitor. It stabilizes the 3.3V output after the regulator, ensuring a clean power supply for the rest of the board.

R3 (1k), D1 (LED): Power Indicator. A simple LED circuit that lights up when the +3.3V power rail is active.

2. ?? Programing zone
This zone allows a single ST-Link programmer to select and program one of the five connected microcontrollers.

P1 (TSM-105...): ST-Link Connector. This is the 10-pin header where you'll plug in your ST-Link V2 programmer. It's the "input" for the SWD signals (SWDIO, SWCLK, NRST).

U2, U3, U4 (CD74HC4051): Analog Multiplexers (MUXs). These are the "brains" of the zone. They act as signal switches:

U2 switches the SWDIO signal.
U3 switches the SWCLK signal.
U4 switches the NRST (Reset) signal.

SW1 (A6SN-3101): DIP Switch. This is your manual control. You use it to set a 3-bit address (e.g., 001), and the MUXs route the ST-Link signals to the corresponding MCU (e.g., MCU 2).

R4, R5, R6 (10k): Pull-down Resistors. They ensure the control lines (S0, S1, S2) have a stable 0 (GND) state when the SW1 switch is in the OFF (open) position, preventing a "floating" state.

3. ?? Connection zone
This is simply the set of physical connectors where your external MCU modules (like Nucleo boards) will be attached.

MCU1 ... MCU5: MCU Headers. Five 5-pin headers. Each header receives:

Its unique SWDIO, SWCLK, and NRST signals from the "Programing zone" MUXs.

+3.3V and GND power from the "Power supply zone".

4. ?? Wifi zone (Communication Zone)
This zone prepares two separate modules (WiFi and USB-UART) that you can then connect to any MCU using jumper wires.

J2 (1981568-1): Micro USB Connector. This is used only to power the U6 (CP2102N) chip and provide it with a USB signal from your computer.

U6 (CP2102N): USB-UART Bridge. This chip converts the USB signals from J2 into simple TXD/RXD (UART) signals that an MCU can understand.

R7 (10k), C3 (100nF): Basic components for U6 (a pull-up resistor for its RST pin and a power filtering capacitor).

U5 (ESP-12F): WiFi Module. This provides the WiFi functionality.

R8 - R12 (10k): Bootstrapping Resistors. These are critically important for the ESP-12F. They set the logic levels of the EN, RST, GPIO0, GPIO2, and GPIO15 pins during startup, telling the module to boot into its normal operating mode.

C4 (1uF): Power filtering capacitor for the ESP-12F.
P2, P4: Communication Output Headers.
P2 provides the TX/RX signals from the ESP-12F (WiFi).
P4 provides the TX/RX signals from the CP2102N (USB-UART).

PCB_Project description:

1. Zone: Power Supply and ST-Link

This sheet contains two main blocks: the power supply for the whole board and the on-board programmer.

What has been done: The main 3.3V power supply and the ST-Link programmer (which is the fifth MCU) have been created.

Components and their purpose:

E1, D1 (Protection): E1 is the 12V power input. D1 (Schottky diode) protects the circuit if the power supply is connected in reverse (positive and negative swapped).

U1 (AP63203), L1, C1–C3 (Power): This is a DCDC step-down converter. U1 is the main IC, L1 (inductor) stores energy, and C1–C3 filter the voltage. This block converts 12V to a powerful 3.3V supply for the rest of the board.

R1, R2 (Feedback): These two resistors (316k and 100k) form a voltage divider. They “tell” the U1 converter what output voltage (3.3V in this case) to maintain.

D2, R3 (Indicator): A simple LED showing that the +3.3V power supply is active.

U2A/U2B (STM32F103): The heart of the ST-Link programmer. This is a separate microcontroller whose only task is to act as a programmer for the other four MCUs.

J1 (USB): Connector to the computer, used only for the ST-Link (U2).

R5, R6, R4 (USB): R5/R6 (33 ?) are for signal impedance matching. R4 (1.5 k?) is a pull-up resistor that signals the computer that a USB device is connected.

Y1, C4, C5 (Crystal): Required 8 MHz crystal. Without it, the STM32F103 wouldn’t be able to maintain stable USB communication with the PC.

Boot added header 3pin so you can program the ST-link.
Placing the jumper cap on pins 1–2: Normal ST-Link operation mode.
Placing the jumper cap on pins 2–3: Firmware programming mode.

R7, C6, R9 (Reset): R9 (pull-down) ensure that the F103 starts from its main memory. R7 and C6 provide a stable reset signal at startup.

D3, D4, R10, R11 (ST-Link LEDs): Indicator LEDs showing the ST-Link status (e.g., “active”, “communicating”).

SWDIO, SWCLK, NRST (Outputs): These are the programmer’s outputs that go to another schematic sheet (to the MUXes).

2. Zone: Signal Switching

What has been done: A circuit has been created that works like a “selector” – it routes ST-Link and WiFi signals to one of the four selected MCUs.

Components and their purpose:

U3, U4, U5 (74HC4052): Analog switches (MUXes) for ST-Link signals. U3 switches SWDIO, U4 switches SWCLK, and U5 switches NRST.

U6 (74HC4052): Dual MUX that synchronously switches the WIFI_TX and WIFI_RX signals.

SW1 (DIP Switch): Manual control. It sets the 2-bit address (MCU_A0, MCU_A1).

R11, R12 (Pull-down): Ensure that control lines (MCU_A0, MCU_A1) are in a defined 0 state when SW1 is off.

Operating principle: When you switch SW1 (e.g., to 01), all four MUXes (U3–U6) simultaneously switch and connect all signals to the second channel (e.g., SWDIO_2, SWCLK_2, NRST_2, WIFI_TX_2, WIFI_RX_2).

3. Zone: Peripherals

What has been done: WiFi and Ethernet modules have been prepared to provide communication for the MCU islands.

Components and their purpose:

U7 (ESP-12F): WiFi module.

R13–R17 (Bootstrapping): Critically important resistors that set the ESP-12F boot mode, ensuring it always starts in normal operation mode (not programming mode). C7 filters its power supply.

WIFI_RX, WIFI_TX (Signals): Module TX and RX lines that go to the MUX (U6).

U8 (LAN8720A): Ethernet PHY. It converts digital RMII signals from the STM32H7 into analog signals suitable for the RJ45 connector.

Y2, C8, C9 (Crystal): Required 25 MHz crystal for LAN8720A. Without it, Ethernet communication will not work.

C10–C13 (Filtering): Power filtering capacitors for LAN8720A.

R18–R22 (PHY Configuration): These resistors set the LAN8720A mode (RMII) and address. R22 (12 k?) is the RBIAS resistor.

J2 (RJ45): Physical Ethernet connector with integrated magnetics.

ETH_… (Signals): RMII interface signals (ETH_REF_CLK, ETH_TXD0, ETH_MDC, etc.) that go only to the STM32H7 island.

4. Zone: MCU H7 Island

What has been done: The STM32H7 microcontroller (assumed MCU_1) has been prepared.

Components and their purpose:

U9A/U9B (STM32H750): The main, most powerful MCU.

C18–C23 (Power): H7 power supply filtering capacitors.

C24, C25 (VCAP): Critically important capacitors for the H7 internal regulator that powers the CPU core. Without them, the MCU won’t operate.

Y4 (LSE), C14, C15 (Crystal): 32.768 kHz crystal for the real-time clock (RTC).

Y3 (HSE), C16, C17 (Crystal): 25 MHz crystal. It must be 25 MHz to synchronize with LAN8720A (which also uses 25 MHz).

R23 (Boot): BOOT0 configuration (boot from Flash).

Net labels (SWDIO_1, WIFI_RX_1, ETH_…): All signals from other sheets (ST-Link, WiFi, Ethernet) connect to this MCU.

5. Zone: MCU L4 Island

What has been done: The STM32L4 (low-power) microcontroller (assumed MCU_2) has been prepared.

Components and their purpose:

U10A/U10B (STM32L476): Second MCU.

C31–C34, C30 (Power): L4 power filtering. C30 (2.2 µF) is the VCAP capacitor required for the internal regulator.

Y6 (LSE), C28, C29 (Crystal): 32.768 kHz crystal (RTC).

Y5 (HSE), C26, C27 (Crystal): 8 MHz (or 25 MHz) crystal for the main clock.

R2 (Boot): BOOT0 configuration.

Net labels (SWDIO_2, SWCLK_2, WIFI_…): Signals come from the MUXes, intended for the second channel.

6. Zone: MCU WL Island

What has been done: The STM32WL (LoRa) microcontroller (assumed MCU_3) has been prepared.

Components and their purpose:

U11 (STM32WLE5): Third MCU with an integrated radio transmitter.

L4, C44 (SMPS): WL has an internal DCDC converter (SMPS). L4 (2.2 µH) and C44 (10 µF) are required for its operation.

Y7 (TCXO): 32 MHz TCXO. A very precise oscillator (not a regular crystal) required for the LoRa radio transmitter. Without this precision, the radio wouldn’t function properly.

Y8 (LSE), C35, C36 (Crystal): 32.768 kHz crystal (RTC).

L3, C37, C38 (Pi-Network): Antenna matching network (Pi filter). L3 (2.7 nH) and the capacitors match the RFO (RF Out) pin to the antenna impedance.

J3 (SMA Connector): Physical connector for the LoRa antenna.

R25 (Boot): BOOT0 configuration.

Net labels (NRST_3, SWDIO_3…): Signals come from the MUXes, intended for the third channel.

