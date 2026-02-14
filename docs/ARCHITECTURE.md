# System Architecture - Gesture-Based Robotic Arm Control

## Overview

This document describes the architecture of the gesture-based robotic arm control system implemented on Artix-7 FPGA.

## System Block Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     Gesture-Based Robotic Arm System            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────┐      ┌─────────────┐      ┌──────────────┐    │
│  │  Camera    │─────▶│   Frame     │─────▶│     VGA      │    │
│  │ Interface  │      │   Buffer    │      │  Controller  │────▶ Monitor
│  │ (OV7670)   │      │  (BRAM)     │      │              │    │
│  └────────────┘      └─────────────┘      └──────────────┘    │
│        │                                                        │
│        │ pixel_data                                            │
│        ▼                                                        │
│  ┌────────────┐      ┌─────────────┐      ┌──────────────┐    │
│  │  Gesture   │─────▶│  Gesture to │─────▶│    Servo     │    │
│  │ Recognizer │      │Servo Mapper │      │  Controller  │────▶ Robotic Arm
│  │            │      │             │      │              │    │
│  └────────────┘      └─────────────┘      └──────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Module Descriptions

### 1. Camera Interface Module

**File**: `hdl/camera/camera_interface.v`

**Purpose**: Interfaces with OV7670 camera module to capture image frames.

**Features**:
- RGB565 to grayscale conversion
- Configurable resolution (default: 640x480)
- Frame synchronization signals
- Pixel streaming output

**Interfaces**:
- Input: Camera signals (PCLK, HREF, VSYNC, DATA[7:0])
- Output: Pixel data stream with position information

### 2. Frame Buffer Module

**File**: `hdl/display/frame_buffer.v`

**Purpose**: Stores one complete frame in dual-port block RAM.

**Features**:
- 640x480 pixels × 8 bits = 2.4 Mbit storage
- Dual-port access for simultaneous write/read
- Port A: Write from camera
- Port B: Read for display and processing

**Implementation Note**: 
Uses FPGA block RAM (BRAM) resources efficiently.

### 3. VGA Display Controller

**File**: `hdl/display/vga_controller.v`

**Purpose**: Generates VGA timing signals and displays captured images.

**Features**:
- Standard VGA 640x480@60Hz timing
- 25 MHz pixel clock
- 12-bit color output (4 bits per RGB channel)
- Grayscale to RGB conversion

**Timing Parameters**:
- H_DISPLAY: 640, H_FRONT: 16, H_SYNC: 96, H_BACK: 48
- V_DISPLAY: 480, V_FRONT: 10, V_SYNC: 2, V_BACK: 33

### 4. Gesture Recognition Module

**File**: `hdl/gesture/gesture_recognizer.v`

**Purpose**: Analyzes image frames to detect finger count gestures.

**Current Algorithm** (Simple Prototype):
1. Threshold image to binary (threshold = 128)
2. Count white pixels in frame
3. Map pixel count to finger count (0-5)

**Future Enhancement** (ML Accelerator):
1. Feature extraction (edge detection, contour finding)
2. Convex hull analysis
3. Finger tip detection
4. CNN-based classification

**Outputs**:
- finger_count: Detected number of fingers (0-5)
- gesture_valid: Signal indicating valid gesture detected
- gesture_id: Unique identifier for each gesture type

### 5. Gesture to Servo Mapper

**File**: `hdl/gesture/gesture_to_servo.v`

**Purpose**: Maps detected gestures to robotic arm servo positions.

**Gesture Mapping Table**:

| Fingers | Gesture | Base | Shoulder | Elbow | Gripper | Description |
|---------|---------|------|----------|-------|---------|-------------|
| 0       | Fist    | 90°  | 45°      | 45°   | 180°    | Rest position, gripper closed |
| 1       | Point   | 45°  | 90°      | 90°   | 90°     | Left position, gripper half-open |
| 2       | Peace   | 90°  | 120°     | 60°   | 90°     | Extended upward |
| 3       | Three   | 135° | 90°      | 90°   | 90°     | Right position |
| 4       | Four    | 90°  | 135°     | 45°   | 45°     | High position, gripper open |
| 5       | Open    | 90°  | 135°     | 135°  | 0°      | Fully extended, gripper open |

**Customization**: Angles can be calibrated based on specific robotic arm configuration.

### 6. Servo Controller Module

**File**: `hdl/servo/servo_controller.v`

**Purpose**: Generates PWM signals to control 4 servo motors.

**Features**:
- 4 independent servo channels
- Standard servo timing (1-2ms pulse, 20ms period)
- Angular control 0-180 degrees
- 100 MHz system clock

**PWM Parameters**:
- Period: 20ms (50 Hz)
- Min pulse: 1ms (0°)
- Max pulse: 2ms (180°)
- Linear mapping between angle and pulse width

### 7. Top-Level Integration

**File**: `hdl/top/gesture_robotic_arm_top.v`

**Purpose**: Integrates all modules into complete system.

**Clock Domains**:
- 100 MHz: System clock, servo control, gesture processing
- 25 MHz: VGA display (divided from 100 MHz)
- Camera PCLK: Asynchronous from camera (~24 MHz)

**Clock Domain Crossings**: Handled with dual-port RAM and synchronization.

## Resource Utilization

Estimated resource usage on Artix-7 XC7A100T:

| Resource | Usage | Available | Percentage |
|----------|-------|-----------|------------|
| LUTs     | ~5,000 | 63,400   | ~8%        |
| FFs      | ~3,000 | 126,800  | ~2%        |
| BRAM     | ~10    | 135      | ~7%        |
| DSP      | 0      | 240      | 0%         |

## Timing Constraints

Key timing paths:
1. Camera PCLK domain: 24 MHz (41.67 ns period)
2. System clock domain: 100 MHz (10 ns period)
3. VGA clock domain: 25 MHz (40 ns period)

All clock domains are asynchronous and properly constrained.

## Future Enhancements

### Phase 1 (Current): Basic Gesture Control
- ✅ Simple threshold-based gesture detection
- ✅ Pre-defined servo mappings
- ✅ 10-15 sample dataset

### Phase 2 (Planned): ML Hardware Accelerator
- [ ] CNN-based gesture classification
- [ ] Hardware accelerated convolution engine
- [ ] On-chip training capability
- [ ] Expanded gesture vocabulary (10+ gestures)
- [ ] Real-time hand tracking
- [ ] Motion gesture recognition

### Hardware Accelerator Architecture (Future)
```
┌─────────────────────────────────────┐
│   ML Hardware Accelerator (Future)  │
├─────────────────────────────────────┤
│  ┌──────────┐    ┌──────────────┐  │
│  │  Conv2D  │───▶│   ReLU +     │  │
│  │  Engine  │    │   Pooling    │  │
│  └──────────┘    └──────────────┘  │
│        │                 │          │
│        ▼                 ▼          │
│  ┌──────────┐    ┌──────────────┐  │
│  │  Weight  │    │ Activation   │  │
│  │  Buffer  │    │   Buffer     │  │
│  └──────────┘    └──────────────┘  │
│        │                 │          │
│        ▼                 ▼          │
│  ┌─────────────────────────────┐  │
│  │  Fully Connected + Softmax  │  │
│  └─────────────────────────────┘  │
└─────────────────────────────────────┘
```

## References

1. OV7670 Camera Module Datasheet
2. VGA Timing Specifications
3. Servo Motor Control Guide
4. Xilinx Artix-7 FPGA Documentation
