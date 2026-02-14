# Gesture-Based Robotic Arm Controller - RTL Design Documentation

## Overview

Complete Verilog RTL implementation of a gesture-based robotic arm controller for Xilinx Artix-7 FPGA. The system captures camera input (OV7670), performs real-time gesture recognition through skin segmentation and finger counting, displays the results on VGA, and controls a 4-axis robotic arm via PWM servos.

## System Architecture

```
Camera (OV7670) → Capture → RGB→YCbCr → Skin Detection → Morphological Filter
                                                              ↓
                                                         Finger Counter
                                                              ↓
                                                      Count Stabilizer
                                                              ↓
                                                        Servo Mapper
                                                              ↓
                                                         PWM Driver
                                                              ↓
                                                      Servo Motors

Frame Buffer (Double-buffered) → VGA Controller → VGA Overlay → Monitor
```

## Design Philosophy

### Stability Requirements (Production-Quality)

- **Fully synchronous design**: Single 100 MHz clock domain with proper clock enables
- **Pipeline architecture**: Each stage has registered outputs, no long combinational paths
- **Double-buffered frame storage**: Eliminates tearing and visual artifacts
- **Hysteresis on finger count**: N-frame consistency required before output changes
- **Parameterized modules**: Easy tuning without logic changes
- **Smooth servo ramping**: Gradual transitions prevent mechanical damage

## File Structure

### RTL Modules (`rtl/`)

1. **`top_gesture_arm.v`** - Top-level integration
   - Parameters: H_ACTIVE=640, V_ACTIVE=480, STABLE_FRAMES=5
   - Instantiates and connects all pipeline stages
   - Single clock domain (100 MHz system clock)

2. **`clk_divider.v`** - Clock management
   - Generates 25 MHz pixel clock from 100 MHz system clock
   - Clean 50% duty cycle output
   - Synchronous reset

3. **`cam_ov7670_interface.v`** - Camera capture
   - 2-FF synchronizers for clock domain crossing
   - RGB565 output format
   - Rising edge detection on PCLK
   - Frame boundaries via VSYNC falling/rising edges

4. **`rgb565_to_ycbcr.v`** - Color space conversion
   - ITU-R BT.601 standard coefficients
   - 2-stage pipeline (multiply-add, then shift-saturate)
   - Fixed-point arithmetic scaled by 256
   - Output ranges: Y[16,235], Cb/Cr[16,240]

5. **`skin_detector.v`** - Skin segmentation
   - YCbCr thresholding: Y[80,235], Cb[85,135], Cr[135,180]
   - 1-clock latency, fully registered
   - Binary mask output

6. **`morphological_filter.v`** - Noise removal
   - 3×3 erosion using line buffers
   - Removes small noise regions
   - Valid output when row≥2, col≥2

7. **`finger_counter.v`** - Gesture recognition
   - Phase 1: Vertical projection histogram (count skin pixels per column)
   - Phase 2: Peak detection via threshold crossings
   - COL_THRESH=30, HAND_THRESH=2000 (parameterized)
   - Outputs: finger_count[2:0], hand_detected

8. **`count_stabilizer.v`** - Temporal filtering
   - Requires STABLE_FRAMES (default 5) consecutive identical counts
   - Prevents output jitter and servo oscillation

9. **`frame_buffer_controller.v`** - Double-buffered storage
   - BRAM inference with `(* ram_style = "block" *)`
   - Separate buffers for RGB and skin mask
   - Buffer swap on frame_done
   - 1-cycle read latency

10. **`vga_controller.v`** - Display timing
    - 640×480 @60Hz standard timing
    - H: 640+16+96+48 = 800 (31.5 kHz)
    - V: 480+10+2+33 = 525 (60 Hz)
    - Active-low sync pulses

11. **`vga_overlay.v`** - Visual output
    - Left half (0-319): Raw RGB camera image
    - Right half (320-639): Binary skin mask (white/black)
    - Top-left: Green bars showing finger count (5 slots, 30px each)

12. **`servo_mapper.v`** - Motion control
    - Maps finger count to target servo angles:
      - 0 fingers: HOME (all centered)
      - 1 finger: Base rotate
      - 2 fingers: + Shoulder lift
      - 3 fingers: + Elbow extend
      - 4 fingers: + Gripper open
      - 5 fingers: + Gripper close
    - Smooth ramping: ±1 degree per 65536 clock cycles (~0.65ms)

13. **`pwm_servo_driver.v`** - PWM generation
    - 4 independent channels
    - 50 Hz period (20ms = 2,000,000 cycles @100MHz)
    - Pulse width: 1-2 ms (100,000-200,000 cycles)
    - Linear mapping: duty = PWM_MIN + angle×392

### Simulation (`sim/`)

- **`tb_top_gesture_arm.v`** - Comprehensive testbench
  - 100 MHz system clock generation
  - Simulated camera signals with test pattern
  - Monitors finger count, hand detection, servo PWM
  - VCD waveform dump for debugging

### Constraints (`constraints/`)

- **`artix7_pinout.xdc`** - Xilinx constraints
  - Pin assignments for Basys 3 / Nexys 4 DDR boards
  - 100 MHz clock constraint
  - VGA output pins (4-bit RGB)
  - Camera interface (Pmod JA/JB)
  - Servo outputs (Pmod JC)
  - Debug LEDs

## Key Parameters

| Module | Parameter | Default | Description |
|--------|-----------|---------|-------------|
| top_gesture_arm | H_ACTIVE | 640 | Horizontal resolution |
| top_gesture_arm | V_ACTIVE | 480 | Vertical resolution |
| top_gesture_arm | STABLE_FRAMES | 5 | Frames required for stable count |
| clk_divider | DIV_FACTOR | 4 | Clock division ratio (100→25 MHz) |
| skin_detector | Y_MIN/MAX | 80/235 | Y channel thresholds |
| skin_detector | CB_MIN/MAX | 85/135 | Cb channel thresholds |
| skin_detector | CR_MIN/MAX | 135/180 | Cr channel thresholds |
| finger_counter | COL_THRESH | 30 | Min pixels per column |
| finger_counter | HAND_THRESH | 2000 | Min total pixels for hand |
| servo_mapper | RAMP_PERIOD | 65536 | Cycles between angle steps |

## Building and Simulation

### Using Xilinx Vivado

```bash
# Create new Vivado project
vivado -mode batch -source build_project.tcl

# Or manually in Vivado GUI:
# 1. Create new RTL project for Artix-7 (xc7a35tcpg236-1 for Basys 3)
# 2. Add all files from rtl/ directory
# 3. Add constraints/artix7_pinout.xdc
# 4. Set top_gesture_arm as top module
# 5. Run Synthesis → Implementation → Generate Bitstream
```

### Simulation with Icarus Verilog

```bash
cd sim
iverilog -o tb_top_gesture_arm.vvp \
    -I../rtl \
    tb_top_gesture_arm.v \
    ../rtl/*.v

vvp tb_top_gesture_arm.vvp
gtkwave tb_top_gesture_arm.vcd
```

### Simulation with ModelSim/Questa

```bash
vlog -work work rtl/*.v sim/tb_top_gesture_arm.v
vsim -do "run -all" work.tb_top_gesture_arm
```

## Hardware Setup

### Required Components

1. **FPGA Board**: Xilinx Artix-7 (Basys 3 or Nexys 4 DDR)
2. **Camera**: OV7670 module (without FIFO)
3. **Display**: VGA monitor
4. **Robotic Arm**: 4-axis arm with standard servos
5. **Servo Power**: External 5-6V power supply for servos

### Connections

**Camera (Pmod JA/JB)**:
- JA1: XCLK (output to camera)
- JA2: PCLK (input from camera)
- JA3: VSYNC
- JA4: HREF
- JA7: SIOC (I²C clock, tied high)
- JA8: SIOD (I²C data, high-Z)
- JA9: RESET
- JA10: PWDN
- JB1-8: DATA[7:0]

**VGA Output**: Standard VGA connector (4-bit RGB)

**Servo Motors (Pmod JC)**:
- JC1: Base servo PWM
- JC2: Shoulder servo PWM
- JC3: Elbow servo PWM
- JC4: Gripper servo PWM

**Debug LEDs**:
- LED0-2: Finger count (binary)
- LED3: Hand detected

## Timing Analysis

### Critical Paths

1. **Camera Interface**: PCLK rising edge detection → 2 FF synchronizers
2. **Color Conversion**: 2-stage pipeline ensures timing closure
3. **Morphological Filter**: Line buffer read → 3×3 window → erosion logic
4. **VGA Output**: Frame buffer BRAM read latency (1 cycle)

### Clock Constraints

- System clock: 100 MHz (10 ns period)
- Pixel clock: 25 MHz (40 ns period)
- No false paths between clock domains (proper synchronizers)

## Resource Utilization (Estimated)

For Artix-7 xc7a35t:

| Resource | Usage | Total | Percentage |
|----------|-------|-------|------------|
| LUTs | ~8,000 | 20,800 | ~38% |
| FFs | ~6,000 | 41,600 | ~14% |
| BRAM | 20-30 | 50 | ~50% |
| DSPs | 0 | 90 | 0% |

*Note: BRAM usage dominated by frame buffers (640×480×17 bits × 2)*

## Performance Characteristics

- **Frame Rate**: Up to 30 FPS (camera-limited)
- **Latency**: ~5-8 frames from gesture to servo response
- **Servo Update Rate**: Smooth ramping at ~1530 steps/second
- **VGA Refresh**: 60 Hz

## Known Limitations

1. **Camera Configuration**: Requires external SCCB/I²C configuration (not included)
2. **Lighting Sensitivity**: Skin detection thresholds may need tuning per environment
3. **Hand Orientation**: Works best with palm facing camera
4. **Frame Buffer Size**: 640×480 requires significant BRAM
5. **No Auto-Calibration**: Thresholds are fixed parameters

## Future Enhancements

- [ ] Adaptive skin threshold calibration
- [ ] Support for multiple hand sizes
- [ ] Hand tracking with position-based control
- [ ] Configuration register interface for runtime tuning
- [ ] Support for higher resolutions (requires larger FPGA)
- [ ] SCCB master controller for camera auto-configuration

## Testing Checklist

- [x] Clock generation and distribution
- [x] Camera interface synchronization
- [x] Color space conversion accuracy
- [x] Skin detection thresholding
- [x] Morphological filtering
- [x] Finger counting algorithm
- [x] Count stabilization
- [x] Frame buffer read/write
- [x] VGA timing generation
- [x] VGA overlay rendering
- [x] Servo PWM generation
- [x] Servo angle mapping
- [x] Top-level integration

## License

This design is provided for educational and research purposes.

## References

- ITU-R BT.601 Color Space Conversion
- OV7670 Camera Module Datasheet
- VGA Signal Standard (640×480 @60Hz)
- Xilinx Artix-7 FPGA Datasheet
- Standard Servo PWM Protocol (50 Hz, 1-2ms)

## Author

Created for the Gesture-Based Robotic Arm Project using Xilinx Artix-7 FPGA.
