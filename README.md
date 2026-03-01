# Gesture-Based Robotic Arm Control with Artix-7 FPGA

A real-time gesture recognition system that controls a 4-axis robotic arm using hand gestures captured by a camera and processed on Xilinx Artix-7 FPGA.

## 🎯 Project Overview

This project implements a gesture-based robotic arm control system using:
- **Input**: OV7670 camera module for capturing hand gestures
- **Processing**: Real-time image processing on Artix-7 FPGA
- **Output**: VGA display for visual feedback + 4-axis robotic arm control
- **Recognition**: Finger counting algorithm (0-5 fingers) mapped to arm positions

The system first displays the camera feed on a monitor for algorithm verification, then controls the robotic arm based on detected gestures.

## ✨ Features

- ✅ Real-time camera image capture (640x480 @ 30 FPS)
- ✅ VGA display output for visual monitoring
- ✅ Gesture recognition (0-5 finger counting)
- ✅ 4-axis servo control for robotic arm
- ✅ Pre-defined gesture-to-motion mapping
- ✅ 10-15 sample dataset support
- ✅ Modular HDL design for easy customization
- 🔮 Future: ML hardware accelerator integration

## 📋 System Architecture

```
Camera → Image Processing → Gesture Recognition → Servo Control → Robotic Arm
   ↓                                                    
VGA Display (Visual Feedback)
```

**Key Components**:
1. **Camera Interface**: Captures and converts RGB565 to grayscale
2. **Frame Buffer**: Stores image data in dual-port BRAM
3. **VGA Controller**: Displays processed images on monitor
4. **Gesture Recognizer**: Detects finger count using threshold-based algorithm
5. **Servo Controller**: Generates PWM signals for 4 servos
6. **Gesture-to-Servo Mapper**: Maps gestures to arm positions

## 🎮 Supported Gestures

| Gesture | Fingers | Arm Action |
|---------|---------|------------|
| 🤛 Fist | 0 | Rest position, gripper closed |
| ☝️ Point | 1 | Base left, gripper half-open |
| ✌️ Peace | 2 | Extended upward |
| 🤟 Three | 3 | Base right |
| 🖖 Four | 4 | High position, gripper open |
| ✋ Open Hand | 5 | Fully extended, gripper fully open |

## 🛠️ Hardware Requirements

- **FPGA Board**: Nexys A7-100T or similar Artix-7 board
- **Camera**: OV7670 camera module (640x480)
- **Display**: VGA monitor
- **Robotic Arm**: 4-axis arm with standard servos (SG90/MG995)
- **Power Supply**: 5V/2A for servos (separate from FPGA)

## 📁 Project Structure

```
Gesture_based_robotic_arm_artix_7/
├── hdl/                          # HDL source files
│   ├── camera/                   # Camera interface module
│   ├── display/                  # VGA controller & frame buffer
│   ├── servo/                    # Servo control module
│   ├── gesture/                  # Gesture recognition logic
│   └── top/                      # Top-level integration
├── testbench/                    # Simulation testbenches
├── constraints/                  # XDC constraint files
├── scripts/                      # Build and simulation scripts
├── datasets/                     # Gesture datasets
│   └── finger_count/             # Finger count samples
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md           # System architecture details
│   ├── HARDWARE_SETUP.md         # Hardware assembly guide
│   └── USAGE.md                  # Usage instructions
└── README.md                     # This file
```

## 🚀 Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/sk24ecb0a56-coder/Gesture_based_robotic_arm_artix_7.git
cd Gesture_based_robotic_arm_artix_7
```

### 2. Hardware Setup
Follow the detailed [Hardware Setup Guide](docs/HARDWARE_SETUP.md) to:
- Connect camera module to FPGA
- Connect VGA monitor
- Wire up 4-axis robotic arm with servos
- Configure power supplies

### 3. Build Project
```bash
# Using Vivado in batch mode
vivado -mode batch -source scripts/build.tcl
```

Or open in Vivado GUI and follow [Usage Guide](docs/USAGE.md).

### 4. Program FPGA
```bash
# In Vivado TCL console
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices
```

### 5. Test System
- Hold hand in front of camera
- Show different finger counts
- Observe arm movements
- Monitor VGA display

## 📊 Performance

- **Processing**: 100 MHz system clock
- **Frame Rate**: 30 FPS
- **Latency**: < 100ms gesture-to-action
- **Resource Usage**: ~8% LUTs, ~7% BRAM
- **Recognition**: 6 gesture classes (0-5 fingers)

## 📖 Documentation

- **[Architecture](docs/ARCHITECTURE.md)**: Detailed system design and module descriptions
- **[Hardware Setup](docs/HARDWARE_SETUP.md)**: Complete assembly instructions
- **[Usage Guide](docs/USAGE.md)**: Operating instructions and troubleshooting

## 🔬 Simulation

Run testbenches to verify modules:

```bash
# Run all simulations
vivado -mode batch -source scripts/simulate.tcl
```

Or simulate individual modules in Vivado.

## 🎓 Dataset

The project includes a dataset structure for 10-15 samples per gesture:
- Location: `datasets/finger_count/`
- Format: 640x480 grayscale (8-bit RAW)
- Classes: 0-5 fingers

See [Dataset README](datasets/finger_count/README.md) for details.

## 🔮 Future Enhancements

### Phase 1 (Current)
- ✅ Basic threshold-based gesture detection
- ✅ Pre-defined servo mappings
- ✅ 10-15 sample dataset

### Phase 2 (Planned)
- [ ] ML hardware accelerator integration
- [ ] CNN-based gesture classification
- [ ] Expanded gesture vocabulary (10+ gestures)
- [ ] Real-time hand tracking
- [ ] Motion gesture recognition
- [ ] On-chip training capability

### Hardware Accelerator Design
The future ML accelerator will include:
- Convolution engine (Conv2D)
- Activation functions (ReLU, Softmax)
- Weight and activation buffers
- Fully connected layers
- Integrated with gesture recognition pipeline

## 🔧 Customization

### Adding New Gestures
1. Modify `hdl/gesture/gesture_recognizer.v`
2. Update `hdl/gesture/gesture_to_servo.v`
3. Collect training samples
4. Test and calibrate

### Adjusting Servo Positions
Edit angle mappings in `hdl/gesture/gesture_to_servo.v`:
```verilog
4'd1: begin  // 1 finger
    servo0_angle <= 8'd45;   // Adjust angles here
    servo1_angle <= 8'd90;
    ...
end
```

## 🐛 Troubleshooting

Common issues and solutions:

- **Gestures not recognized**: Adjust threshold in gesture_recognizer.v
- **Servo jitter**: Check power supply, add filtering
- **No display**: Verify VGA timing and clock generation
- **Camera not working**: Check connections and power

See [Usage Guide](docs/USAGE.md) for detailed troubleshooting.

## 📄 License

This project is open-source and available for educational and research purposes.

## 👥 Contributors

- Project developed for Artix-7 FPGA gesture control research

## 🔗 References

1. Xilinx Artix-7 FPGAs Documentation
2. OV7670 Camera Module Datasheet
3. VGA Signal Timing Specifications
4. Servo Motor Control Standards

## 📧 Contact

For questions, issues, or contributions, please open an issue on GitHub.

---

**Note**: This is an educational project demonstrating real-time gesture recognition and robotic control using FPGA technology. The current implementation uses a simple threshold-based algorithm suitable for initial testing with 10-15 samples. Future enhancements will incorporate machine learning hardware acceleration for improved accuracy and expanded gesture vocabulary.
