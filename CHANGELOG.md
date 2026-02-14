# Changelog

All notable changes to the Gesture-Based Robotic Arm project will be documented in this file.

## [1.0.0] - 2026-02-14

### Added
- Initial implementation of gesture-based robotic arm control system
- Core HDL modules:
  - Camera interface module (OV7670 support)
  - VGA display controller (640x480@60Hz)
  - Frame buffer with dual-port RAM
  - Gesture recognition module (finger counting algorithm)
  - Gesture-to-servo mapper with 6 pre-defined positions
  - Servo controller for 4-axis robotic arm
  - Top-level integration module
- Simulation testbenches:
  - Gesture recognizer testbench
  - Servo controller testbench
- Build automation:
  - TCL build script for Vivado
  - TCL simulation script
  - TCL programming script
  - Makefile for common operations
- Dataset support:
  - Dataset structure for finger count gestures (0-5)
  - Python script for dataset collection
  - Sample data format documentation
- Comprehensive documentation:
  - System architecture guide
  - Hardware setup guide with connection diagrams
  - Usage guide with calibration instructions
  - Main README with quick start guide
- Constraints file for Artix-7 FPGA (Nexys A7 compatible)
- Git configuration with appropriate .gitignore

### Features
- Real-time camera capture at 30 FPS
- VGA output for visual feedback
- 6 gesture classes (0-5 fingers)
- 4-axis servo control with PWM generation
- Threshold-based gesture recognition
- Pre-defined gesture-to-motion mappings
- Status LED indicators

### Technical Specifications
- Resolution: 640x480 pixels
- Processing: 100 MHz system clock
- Latency: < 100ms gesture-to-action
- Resource usage: ~8% LUTs, ~7% BRAM on Artix-7
- Gesture recognition: Threshold-based pixel counting

## [Unreleased]

### Planned Enhancements
- ML hardware accelerator integration
- CNN-based gesture classification
- Expanded gesture vocabulary (10+ gestures)
- Real-time hand tracking
- Motion gesture recognition
- On-chip training capability
- Improved gesture recognition algorithms:
  - Contour detection
  - Convex hull analysis
  - Finger tip detection
- Enhanced camera interface with auto-calibration
- HDMI output support
- Ethernet interface for remote control
- Web-based monitoring dashboard

---

## Version History

### Version 1.0.0 (Initial Release)
- First functional release
- Basic gesture control operational
- 10-15 sample dataset support
- Suitable for educational and research use

### Future Versions

#### Version 1.1.0 (Planned)
- Enhanced gesture recognition
- Improved calibration tools
- Additional test patterns
- Performance optimizations

#### Version 2.0.0 (Planned)
- ML hardware accelerator
- CNN-based classification
- Expanded dataset (1000+ samples)
- Real-time training support
