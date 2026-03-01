# Quick Reference Card

## 🚀 Quick Start Commands

```bash
# Build the project
make build

# Run simulations
make simulate

# Program FPGA
make program

# Clean build artifacts
make clean

# Collect dataset
python3 scripts/collect_dataset.py
```

## 📊 Gesture Reference

| Gesture | Fingers | Base | Shoulder | Elbow | Gripper |
|---------|---------|------|----------|-------|---------|
| 🤛 Fist | 0 | 90° | 45° | 45° | 180° (closed) |
| ☝️ Point | 1 | 45° (left) | 90° | 90° | 90° |
| ✌️ Peace | 2 | 90° | 120° (up) | 60° | 90° |
| 🤟 Three | 3 | 135° (right) | 90° | 90° | 90° |
| 🖖 Four | 4 | 90° | 135° (high) | 45° | 45° |
| ✋ Open | 5 | 90° | 135° (high) | 135° | 0° (open) |

## 🎛️ Pin Assignments (Nexys A7)

### Camera (OV7670)
- PCLK: Pmod JA1
- HREF: Pmod JA2
- VSYNC: Pmod JA3
- XCLK: Pmod JA4
- DATA[7:0]: Pmod JB

### VGA Output
- HSYNC: B11
- VSYNC: B12
- RGB[11:0]: A3-D8

### Servo Control
- Servo 0 (Base): B13
- Servo 1 (Shoulder): F14
- Servo 2 (Elbow): F13
- Servo 3 (Gripper): D17

### Status LEDs
- Finger Count[3:0]: H17, K15, J13, N14
- Frame Ready: R18

## 📁 Key File Locations

```
HDL Sources:           hdl/
├─ Camera:            hdl/camera/camera_interface.v
├─ Display:           hdl/display/vga_controller.v
├─ Gesture:           hdl/gesture/gesture_recognizer.v
├─ Servo:             hdl/servo/servo_controller.v
└─ Top:               hdl/top/gesture_robotic_arm_top.v

Testbenches:          testbench/
Constraints:          constraints/artix7_constraints.xdc
Build Scripts:        scripts/
Documentation:        docs/
```

## 🔧 Common Calibration Values

### Gesture Recognition
```verilog
THRESHOLD = 8'd128        // Image threshold (default)
// Increase for darker environment
// Decrease for brighter environment
```

### Servo Timing
```verilog
MIN_PULSE = 1ms           // 0° position
MAX_PULSE = 2ms           // 180° position
PERIOD = 20ms             // 50Hz PWM
```

### Clock Frequencies
- System Clock: 100 MHz
- VGA Clock: 25 MHz
- Camera Clock: ~24 MHz

## 🐛 Quick Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| No camera image | Check power (3.3V), verify PCLK |
| VGA not working | Verify 25MHz clock, test with pattern |
| Servo jitter | Check 5V supply, add capacitor |
| Wrong gestures | Adjust THRESHOLD value |
| Timing errors | Check clock constraints |

## 📊 Resource Usage (Artix-7 XC7A100T)

| Resource | Usage | Available | % |
|----------|-------|-----------|---|
| LUTs | ~5,000 | 63,400 | 8% |
| FFs | ~3,000 | 126,800 | 2% |
| BRAM | ~10 | 135 | 7% |
| DSP | 0 | 240 | 0% |

## 🔗 Quick Links

- [Full Documentation](docs/)
- [Hardware Setup](docs/HARDWARE_SETUP.md)
- [Usage Guide](docs/USAGE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Contributing](CONTRIBUTING.md)

## 💡 Pro Tips

1. **Testing Display**: Use test_pattern_generator.v to verify VGA without camera
2. **Calibration**: Start with fist gesture (0 fingers) as baseline
3. **Lighting**: Use bright, even lighting for best recognition
4. **Power**: Always use separate 5V supply for servos
5. **Common Ground**: Connect servo GND to FPGA GND

## 📞 Getting Help

1. Check [USAGE.md](docs/USAGE.md) troubleshooting section
2. Review [ARCHITECTURE.md](docs/ARCHITECTURE.md) for design details
3. Open GitHub issue with:
   - Clear description
   - Steps to reproduce
   - Vivado version and board type
   - Error messages or waveforms

---

**Version**: 1.0.0 | **Updated**: 2026-02-14
