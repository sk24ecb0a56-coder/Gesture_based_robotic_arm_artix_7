# Build and Synthesis Guide

This file contains instructions for building the gesture-based robotic arm controller design.

## Prerequisites

- Xilinx Vivado (2018.2 or later)
- Artix-7 FPGA board (Basys 3 or Nexys 4 DDR)
- OV7670 camera module
- VGA monitor
- 4-axis robotic arm with servos

## Quick Start with Vivado

### Method 1: GUI Workflow

1. Launch Vivado
2. Create New Project
3. Select RTL Project (Do not specify sources at this time)
4. Choose Part: xc7a35tcpg236-1 (for Basys 3) or xc7a100tcsg324-1 (for Nexys 4 DDR)
5. Add Design Sources:
   - Click "Add Files"
   - Add all files from `rtl/` directory
   - Set `top_gesture_arm.v` as top module
6. Add Constraints:
   - Click "Add Constraints"
   - Add `constraints/artix7_pinout.xdc`
7. Run Synthesis (click "Run Synthesis")
8. Run Implementation (click "Run Implementation")
9. Generate Bitstream (click "Generate Bitstream")
10. Program Device

### Method 2: TCL Script

Create a file `build.tcl`:

```tcl
# Set project name and directory
set project_name "gesture_arm"
set project_dir "./vivado_project"

# Create project
create_project ${project_name} ${project_dir} -part xc7a35tcpg236-1 -force

# Add RTL sources
add_files -norecurse [glob rtl/*.v]
set_property top top_gesture_arm [current_fileset]

# Add constraints
add_files -fileset constrs_1 -norecurse constraints/artix7_pinout.xdc

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

puts "Build complete!"
```

Run with: `vivado -mode batch -source build.tcl`

## Simulation

### Using Icarus Verilog

```bash
cd sim
iverilog -o sim.vvp -I../rtl tb_top_gesture_arm.v ../rtl/*.v
vvp sim.vvp
gtkwave tb_top_gesture_arm.vcd &
```

### Using Vivado Simulator

1. In Vivado, click "Add Simulation Sources"
2. Add `sim/tb_top_gesture_arm.v`
3. Click "Run Simulation" > "Run Behavioral Simulation"
4. In TCL console: `run 1ms`

## Parameter Tuning

Edit parameters in `rtl/top_gesture_arm.v`:

```verilog
module top_gesture_arm #(
    parameter H_ACTIVE      = 640,    // Frame width
    parameter V_ACTIVE      = 480,    // Frame height
    parameter ADDR_WIDTH    = 19,     // Address bits
    parameter STABLE_FRAMES = 5       // Frames for stable count
)
```

Edit thresholds in module instantiations within `top_gesture_arm.v`:
- Skin detection thresholds in `skin_detector`
- Finger counting thresholds in `finger_counter`
- Servo ramp speed in `servo_mapper`

## Programming the FPGA

### Using Vivado Hardware Manager

1. Connect FPGA board via USB
2. Power on the board
3. In Vivado: Flow Navigator > Program and Debug > Open Hardware Manager
4. Click "Open Target" > "Auto Connect"
5. Click "Program Device"
6. Select generated bitstream file
7. Click "Program"

### Using Command Line

```bash
vivado -mode batch -source program_fpga.tcl
```

Where `program_fpga.tcl` contains:

```tcl
open_hw
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {./vivado_project/gesture_arm.runs/impl_1/top_gesture_arm.bit} [current_hw_device]
program_hw_devices [current_hw_device]
close_hw_target
disconnect_hw_server
```

## Hardware Connections

Before programming, ensure:

1. Camera module connected to Pmod JA and JB
2. VGA cable connected to VGA port
3. Servo motors connected to Pmod JC (with external power!)
4. Ground connections properly shared

⚠️ **Important**: Servo motors require external 5-6V power supply. Do NOT power servos from FPGA board!

## Debug LEDs

Monitor the onboard LEDs:
- LED[2:0]: Binary representation of finger count (0-5)
- LED[3]: Hand detected (1 = hand present, 0 = no hand)

## Troubleshooting

### No camera image on VGA
- Check camera connections
- Verify camera is receiving XCLK (should be 25 MHz)
- Ensure camera is pre-configured for RGB565 output

### Servos not responding
- Check external servo power supply
- Verify PWM signals with oscilloscope (50 Hz, 1-2ms pulses)
- Ensure ground is common between FPGA and servo power

### Incorrect finger counting
- Adjust lighting conditions
- Tune skin detection thresholds in `skin_detector`
- Verify camera is focused properly
- Check VGA display to see skin mask output

### Timing violations in synthesis
- Reduce clock frequency (modify clock constraint)
- Review timing report: `open_run impl_1; report_timing_summary`
- Check critical paths in Vivado Timing Report

## Resource Usage

After synthesis, check resource utilization:
1. Open Implemented Design
2. Reports > Report Utilization
3. Verify BRAM and LUT usage is within limits

Expected usage for Artix-7 35T:
- LUTs: ~8,000 / 20,800 (38%)
- FFs: ~6,000 / 41,600 (14%)
- BRAM: 20-30 / 50 (50%)

## Performance Testing

1. Power on system
2. Present hand to camera (palm facing camera)
3. Show different finger counts (0-5)
4. Observe:
   - VGA display updates in real-time
   - Left side shows camera image
   - Right side shows white skin mask
   - Green bars at top show finger count
   - Servo motors move smoothly
   - Debug LEDs indicate finger count

## Notes

- First-time synthesis may take 10-30 minutes depending on computer
- Incremental builds are much faster
- Always verify timing closure before programming FPGA
- Keep camera ~30-50 cm from hand for best results
- Skin detection works best with good, even lighting
