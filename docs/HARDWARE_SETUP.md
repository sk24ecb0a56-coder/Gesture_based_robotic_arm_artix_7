# Hardware Setup Guide

## Required Hardware Components

### 1. FPGA Development Board
- **Recommended**: Nexys A7-100T or Basys 3
- **FPGA**: Xilinx Artix-7 (XC7A100T or XC7A35T)
- **Clock**: 100 MHz on-board oscillator
- **Features needed**:
  - VGA port for display
  - Pmod connectors for camera
  - GPIO pins for servo control
  - USB programming interface

### 2. Camera Module
- **Model**: OV7670 Camera Module (without FIFO)
- **Resolution**: 640x480 (VGA)
- **Interface**: 8-bit parallel
- **Frame Rate**: 30 FPS
- **Connection**: Pmod or GPIO pins

**Pin Configuration**:
```
Camera Pin  | FPGA Pin  | Signal
------------|-----------|--------
PCLK        | Pmod JA1  | Pixel Clock
HREF        | Pmod JA2  | Horizontal Reference
VSYNC       | Pmod JA3  | Vertical Sync
D0-D7       | Pmod JB   | 8-bit Data Bus
XCLK        | Pmod JA4  | Master Clock Output
RESET       | Pmod JC1  | Camera Reset
PWDN        | Pmod JC2  | Power Down
```

### 3. VGA Monitor
- **Resolution**: 640x480 @ 60Hz minimum
- **Connection**: VGA cable from FPGA board

### 4. 4-Axis Robotic Arm
- **Servo Motors**: 4x standard hobby servos (e.g., SG90, MG995)
- **Power Supply**: 5V/2A for servos (separate from FPGA)
- **Configuration**:
  - Servo 0: Base rotation (180° range)
  - Servo 1: Shoulder joint (180° range)
  - Servo 2: Elbow joint (180° range)
  - Servo 3: Gripper (0° open, 180° closed)

**Servo Connections**:
```
Servo | FPGA Pin | Signal    | Color Coding
------|----------|-----------|-------------
0     | GPIO 1   | PWM       | Orange (Signal)
1     | GPIO 2   | PWM       | Orange (Signal)
2     | GPIO 3   | PWM       | Orange (Signal)
3     | GPIO 4   | PWM       | Orange (Signal)
      | VCC      | 5V        | Red (Power)
      | GND      | Ground    | Brown (Ground)
```

### 5. Power Supply
- **FPGA**: USB power (5V) from programming cable
- **Servos**: External 5-6V power supply (2-3A minimum)
- **Important**: Keep servo power separate from FPGA power to avoid noise

### 6. Additional Components
- Breadboard for connections
- Jumper wires (male-to-male, male-to-female)
- USB cable (Type-A to Micro-B or Type-C)
- VGA cable

## Hardware Assembly

### Step 1: FPGA Board Setup

1. **Unbox and Inspect**:
   - Verify FPGA board is undamaged
   - Check all ports and connectors

2. **Power Connection**:
   - Connect USB cable to computer
   - Verify power LED lights up

3. **Programming Cable**:
   - Install Vivado and board drivers
   - Test connection with Vivado Hardware Manager

### Step 2: Camera Module Installation

1. **Physical Connection**:
   ```
   OV7670 Module → Pmod Connectors
   
   Top Row (JA):    Bottom Row (JB):
   [PCLK] → JA1     [D0] → JB1
   [HREF] → JA2     [D1] → JB2
   [VSYNC]→ JA3     [D2] → JB3
   [XCLK] → JA4     [D3] → JB4
                    [D4] → JB5
   Control (JC):    [D5] → JB6
   [RESET]→ JC1     [D6] → JB7
   [PWDN] → JC2     [D7] → JB8
   ```

2. **Power Connections**:
   - VCC (3.3V) → Pmod VCC
   - GND → Pmod GND

3. **Verification**:
   - Check continuity with multimeter
   - Verify 3.3V on camera VCC pin

### Step 3: VGA Display Connection

1. **Cable Connection**:
   - Connect VGA cable from FPGA VGA port to monitor
   - Ensure secure connection

2. **Monitor Setup**:
   - Power on monitor
   - Set input to VGA
   - Auto-adjust if needed

### Step 4: Servo Motor Installation

1. **Robotic Arm Assembly**:
   - Assemble 4-axis arm according to manufacturer instructions
   - Mount servos securely
   - Ensure full range of motion

2. **Electrical Connections**:
   ```
   Servo Power Bus:
   +5V ─┬─ Servo0 VCC
        ├─ Servo1 VCC
        ├─ Servo2 VCC
        └─ Servo3 VCC
   
   GND ─┬─ Servo0 GND (also connect to FPGA GND)
        ├─ Servo1 GND
        ├─ Servo2 GND
        └─ Servo3 GND
   
   Signal Lines (from FPGA):
   GPIO1 → Servo0 Signal
   GPIO2 → Servo1 Signal
   GPIO3 → Servo2 Signal
   GPIO4 → Servo3 Signal
   ```

3. **Common Ground**:
   - **CRITICAL**: Connect servo GND to FPGA GND
   - Use short, thick wire for ground connection

4. **Power Supply**:
   - Use separate 5V/2A+ power supply for servos
   - Add 1000µF capacitor across supply rails
   - Never power servos from FPGA

### Step 5: Safety Precautions

⚠️ **Important Safety Notes**:

1. **Power Isolation**:
   - Keep servo power separate from FPGA power
   - Common ground is essential

2. **Current Protection**:
   - Use appropriate fuses
   - Monitor servo current draw

3. **Physical Safety**:
   - Secure robotic arm to stable surface
   - Keep clear of moving parts during operation
   - Emergency stop should be accessible

4. **ESD Protection**:
   - Use anti-static wrist strap
   - Ground yourself before handling FPGA

## Connection Diagram

```
┌─────────────────┐
│   Computer      │
│   (Vivado)      │
└────────┬────────┘
         │ USB
         ▼
┌─────────────────────────────────────────┐
│         Artix-7 FPGA Board              │
│  ┌────────────┐        ┌─────────────┐ │
│  │  Pmod JA   │        │  Pmod JB    │ │
│  │  (Camera)  │        │  (Camera)   │ │
│  └─────┬──────┘        └──────┬──────┘ │
│        │                      │        │
│        └──────────┬───────────┘        │
│                   │                    │
│              ┌────▼─────┐              │
│              │  Camera  │              │
│              │  Module  │              │
│              └──────────┘              │
│                                        │
│  ┌──────────┐              ┌────────┐ │
│  │   VGA    │─────────────▶│ Monitor│ │
│  │   Port   │   VGA Cable  └────────┘ │
│  └──────────┘                          │
│                                        │
│  ┌──────────┐                          │
│  │  GPIO    │──┬──┬──┬──┐             │
│  │  Pins    │  │  │  │  │             │
│  └──────────┘  │  │  │  │             │
└────────────────┼──┼──┼──┼─────────────┘
                 │  │  │  │
                 ▼  ▼  ▼  ▼
              ┌──────────────┐    ┌─────────┐
              │  4-Axis      │    │  5V/2A  │
              │  Robotic Arm │◀───│  Power  │
              │  (4 Servos)  │    │  Supply │
              └──────────────┘    └─────────┘
```

## Testing Individual Components

### Test 1: FPGA Connection
```bash
# In Vivado TCL Console
open_hw_manager
connect_hw_server
get_hw_targets
```

### Test 2: Camera Module
- Program FPGA with camera test bitstream
- Verify camera LED (if present) turns on
- Check VGA display for camera output

### Test 3: VGA Display
- Program FPGA with test pattern generator
- Verify colors and resolution on monitor

### Test 4: Servo Motors
- Program FPGA with servo test bitstream
- Test each servo individually
- Verify smooth motion and proper angles

## Troubleshooting

### Camera Not Working
1. Check power (3.3V on VCC)
2. Verify all data pins connected
3. Check PCLK signal with oscilloscope
4. Ensure camera is not in power-down mode

### VGA Display Issues
1. Check cable connections
2. Verify 25 MHz clock generation
3. Test with simple test pattern
4. Try different monitor

### Servo Problems
1. Check 5V power supply
2. Verify PWM signals with oscilloscope
3. Test servos with external controller
4. Check common ground connection

### General Debug
1. Use ILA (Integrated Logic Analyzer) in Vivado
2. Check LED indicators
3. Verify clock signals
4. Review synthesis/implementation reports

## Next Steps

After hardware setup:
1. Proceed to [Usage Guide](USAGE.md) for software programming
2. Calibrate gesture recognition thresholds
3. Tune servo positions for your robotic arm
4. Collect dataset samples

## Bill of Materials (BOM)

| Item | Quantity | Est. Cost (USD) |
|------|----------|-----------------|
| Nexys A7-100T Board | 1 | $200-300 |
| OV7670 Camera Module | 1 | $5-10 |
| VGA Monitor | 1 | $50-100 (or existing) |
| 4-Axis Robotic Arm Kit | 1 | $30-50 |
| SG90/MG995 Servos | 4 | $2-5 each |
| 5V/2A Power Supply | 1 | $10-15 |
| Cables and Wires | Set | $10-20 |
| **Total** | | **~$350-500** |

*Note: Prices are approximate and may vary by region and supplier.*
