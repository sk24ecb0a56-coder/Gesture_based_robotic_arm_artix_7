# Usage Guide

## Prerequisites

Before using the gesture-based robotic arm system, ensure you have:

1. ✅ Completed [Hardware Setup](HARDWARE_SETUP.md)
2. ✅ Installed Vivado Design Suite (2020.1 or later)
3. ✅ Connected all hardware components
4. ✅ Tested power supplies and connections

## Quick Start

### 1. Clone and Setup Repository

```bash
git clone https://github.com/sk24ecb0a56-coder/Gesture_based_robotic_arm_artix_7.git
cd Gesture_based_robotic_arm_artix_7
```

### 2. Build the Project

#### Option A: Using TCL Script (Recommended)

```bash
# Launch Vivado in batch mode
vivado -mode batch -source scripts/build.tcl
```

This will:
- Create Vivado project
- Add all source files
- Run synthesis
- Run implementation
- Generate bitstream

#### Option B: Using Vivado GUI

1. Launch Vivado Design Suite
2. Create New Project
   - Project name: `gesture_robotic_arm`
   - Part: `xc7a100tcsg324-1` (or your board's part)
3. Add source files from `hdl/` directories
4. Add constraints from `constraints/artix7_constraints.xdc`
5. Run Synthesis → Implementation → Generate Bitstream

### 3. Program the FPGA

#### Using Vivado Hardware Manager

1. Open Hardware Manager: `Flow` → `Open Hardware Manager`
2. Connect to target: `Open target` → `Auto Connect`
3. Program device:
   - Right-click on FPGA device
   - Select `Program Device`
   - Browse to bitstream file
   - Click `Program`

#### Using TCL

```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {vivado_project/gesture_robotic_arm.runs/impl_1/gesture_robotic_arm_top.bit} [get_hw_devices xc7a100t_0]
program_hw_devices [get_hw_devices xc7a100t_0]
```

### 4. Verify System Operation

After programming:

1. **Check VGA Display**:
   - Monitor should show camera feed
   - Image should be grayscale
   - Verify proper sync (no rolling or tearing)

2. **Test Camera**:
   - Point camera at hand
   - Verify image appears on monitor
   - Check frame rate (should be smooth)

3. **Check Status LEDs**:
   - Finger count LEDs should indicate detected gestures
   - Frame ready LED should blink at frame rate

4. **Test Servos**:
   - Start with fist gesture (0 fingers)
   - Arm should move to rest position
   - Try different finger counts
   - Verify corresponding arm movements

## Gesture Control Guide

### Supported Gestures

| Gesture | Fingers | Description | Arm Action |
|---------|---------|-------------|------------|
| 🤛 Fist | 0 | Closed hand | Rest position, gripper closed |
| ☝️ Point | 1 | Index finger up | Move base left, half-open gripper |
| ✌️ Peace | 2 | Two fingers | Extend upward |
| 🤟 Three | 3 | Three fingers | Move base right |
| 🖖 Four | 4 | Four fingers | High position, open gripper |
| ✋ Open Hand | 5 | All fingers | Fully extended, gripper open |

### Hand Positioning Tips

For best recognition:
1. **Distance**: Keep hand 30-50 cm from camera
2. **Lighting**: Use even, bright lighting
3. **Background**: Plain, contrasting background works best
4. **Orientation**: Palm facing camera
5. **Stability**: Hold gesture steady for 1-2 seconds

### Gesture Sequence Example

```
Start: Fist → Arm goes to rest position
  ↓
Point (1) → Base rotates left
  ↓
Peace (2) → Shoulder raises, extends upward
  ↓
Open Hand (5) → Fully extended, gripper opens
  ↓
Fist → Returns to rest, gripper closes
```

## Calibration and Tuning

### 1. Gesture Recognition Threshold

Adjust threshold in `hdl/gesture/gesture_recognizer.v`:

```verilog
// Default threshold = 128
// Increase for darker environment
// Decrease for brighter environment
localparam THRESHOLD = 8'd128;  // Adjust this value
```

### 2. Servo Position Calibration

Modify servo angles in `hdl/gesture/gesture_to_servo.v`:

```verilog
4'd1: begin  // 1 finger gesture
    servo0_angle <= 8'd45;   // Base: adjust between 0-180
    servo1_angle <= 8'd90;   // Shoulder: adjust as needed
    servo2_angle <= 8'd90;   // Elbow: adjust as needed
    servo3_angle <= 8'd90;   // Gripper: adjust as needed
end
```

**Calibration Process**:
1. Start with default angles (90° for all)
2. Test each gesture individually
3. Adjust angles to avoid mechanical interference
4. Save optimal positions

### 3. Timing Adjustments

For different camera frame rates, adjust in `hdl/camera/camera_interface.v`:

```verilog
// Camera clock generation
// Default: Half of system clock
// Adjust divider for different camera speeds
```

## Dataset Collection

### Collecting Training Samples

1. **Setup Recording**:
   ```bash
   # Create directory for new samples
   mkdir -p datasets/finger_count/<N>_fingers/
   ```

2. **Capture Process**:
   - Position hand in front of camera
   - Maintain consistent lighting
   - Hold gesture steady
   - Capture multiple angles and positions

3. **Save Format**:
   - RAW binary: 640×480×8-bit = 307,200 bytes
   - Naming: `sample_XXX.raw`

### Sample Collection Guidelines

**Minimum Dataset**:
- 10 samples per gesture class
- Various lighting conditions
- Different hand sizes/orientations
- Multiple backgrounds

**Recommended Dataset**:
- 50+ samples per gesture
- Diverse lighting (bright, dim, mixed)
- Various distances (20-60 cm)
- Multiple users

## Testing and Simulation

### Running Testbenches

#### Simulate Gesture Recognizer

```bash
vivado -mode batch -source scripts/simulate.tcl
```

Or in Vivado:
```tcl
set_property top tb_gesture_recognizer [get_filesets sim_1]
launch_simulation
run 500us
```

#### Simulate Servo Controller

```tcl
set_property top tb_servo_controller [get_filesets sim_1]
launch_simulation
run 200ms
```

### Viewing Waveforms

After simulation:
1. Open waveform window
2. Add signals of interest
3. Zoom to relevant time periods
4. Verify timing and functionality

## Performance Optimization

### 1. Improve Gesture Recognition

**Current Method**: Simple pixel counting
**Enhancement Options**:
- Add morphological operations (erosion, dilation)
- Implement contour detection
- Add hand segmentation
- Use convex hull for finger counting

### 2. Reduce Latency

- Optimize frame buffer read/write
- Pipeline gesture recognition
- Pre-compute threshold values
- Use hardware acceleration

### 3. Increase Frame Rate

- Use camera FIFO buffer
- Optimize clock frequencies
- Reduce processing overhead

## Troubleshooting

### Issue: Gestures Not Recognized

**Solutions**:
1. Check camera focus and alignment
2. Adjust recognition threshold
3. Verify adequate lighting
4. Check pixel count in simulation

### Issue: Servo Jitter or Erratic Movement

**Solutions**:
1. Verify power supply stability
2. Add filtering to gesture output
3. Implement motion smoothing
4. Check PWM signal quality

### Issue: Display Problems

**Solutions**:
1. Verify VGA timing parameters
2. Check clock generation (25 MHz)
3. Test with simple pattern generator
4. Verify frame buffer read/write

### Issue: Slow Frame Rate

**Solutions**:
1. Check camera clock frequency
2. Optimize processing pipeline
3. Verify no timing violations
4. Review synthesis reports

## Advanced Features

### Adding New Gestures

1. **Modify Gesture Recognizer**:
   ```verilog
   // Add new gesture detection logic
   else if (/* new gesture condition */) begin
       finger_count <= 4'd6;  // New gesture ID
       gesture_id <= 8'd6;
   end
   ```

2. **Update Servo Mapper**:
   ```verilog
   4'd6: begin  // New gesture
       servo0_angle <= 8'd...;
       // Define servo positions
   end
   ```

3. **Test and Calibrate**:
   - Collect samples for new gesture
   - Test recognition accuracy
   - Calibrate servo positions

### Implementing ML Hardware Accelerator

**Future Enhancement** (Not in current version):

1. Design CNN architecture
2. Implement convolution engine
3. Add weight/activation buffers
4. Integrate with gesture recognition pipeline

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed ML accelerator design.

## System Monitoring

### FPGA Resource Usage

Check after synthesis:
```
Open Implemented Design → Report Utilization
```

Typical usage:
- LUTs: ~5,000 / 63,400 (~8%)
- FFs: ~3,000 / 126,800 (~2%)
- BRAM: ~10 / 135 (~7%)

### Timing Analysis

Check timing closure:
```
Open Implemented Design → Report Timing Summary
```

All paths should meet timing (WNS ≥ 0).

## Safety Guidelines

⚠️ **Important**:
1. Keep hands clear of moving robotic arm
2. Secure arm to stable surface
3. Emergency stop should be accessible
4. Don't exceed servo torque limits
5. Monitor servo temperatures

## Next Steps

1. **Collect Dataset**: Gather 10-15 samples per gesture
2. **Calibrate System**: Tune thresholds and servo positions
3. **Test Thoroughly**: Verify all gestures work reliably
4. **Document Results**: Record accuracy and performance
5. **Plan Enhancements**: Consider ML accelerator for future

## Support and Resources

- **Documentation**: See `docs/` directory
- **Issues**: Report on GitHub
- **Xilinx Resources**: [Xilinx Documentation](https://www.xilinx.com/support.html)
- **Community Forums**: Xilinx Community, FPGA forums

## References

1. Vivado Design Suite User Guide
2. Artix-7 FPGAs Data Sheet
3. OV7670 Camera Module Documentation
4. VGA Signal Timing Specifications
5. Servo Motor Control Standards
