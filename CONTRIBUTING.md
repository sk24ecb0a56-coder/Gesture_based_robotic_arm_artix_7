# Contributing to Gesture-Based Robotic Arm Project

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check if the issue already exists in the GitHub issue tracker
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Your environment (FPGA board, Vivado version, etc.)
   - Screenshots or waveforms if applicable

### Contributing Code

1. **Fork the repository**
   ```bash
   git clone https://github.com/sk24ecb0a56-coder/Gesture_based_robotic_arm_artix_7.git
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding style guidelines below
   - Add tests for new functionality
   - Update documentation as needed

4. **Test your changes**
   ```bash
   make simulate  # Run simulations
   make build     # Build and verify
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Add feature: brief description"
   ```

6. **Push and create Pull Request**
   ```bash
   git push origin feature/your-feature-name
   ```

## Coding Style Guidelines

### Verilog/SystemVerilog

- Use 4 spaces for indentation (no tabs)
- Module names: lowercase with underscores (`camera_interface`)
- Signal names: lowercase with underscores (`pixel_valid`)
- Parameters: UPPERCASE with underscores (`IMG_WIDTH`)
- Comments: Use `//` for single-line, `/* */` for multi-line
- Always include module header comments
- Use meaningful signal names

**Example**:
```verilog
// Camera Interface Module
// Captures image data from OV7670 camera

module camera_interface #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
)(
    input wire clk,
    input wire rst_n,
    // ... other ports
);
    // Module implementation
endmodule
```

### Python

- Follow PEP 8 style guide
- Use 4 spaces for indentation
- Maximum line length: 100 characters
- Use docstrings for functions and classes
- Type hints encouraged

### Documentation

- Use Markdown for documentation files
- Keep lines under 100 characters
- Use proper heading hierarchy
- Include code examples where appropriate
- Update relevant docs when changing functionality

## Testing Guidelines

### Before Submitting

1. **Syntax Check**: Ensure Verilog code compiles
   ```bash
   make syntax-check
   ```

2. **Simulation**: Run all testbenches
   ```bash
   make simulate
   ```

3. **Build**: Verify synthesis and implementation
   ```bash
   make build
   ```

4. **Hardware Test**: If possible, test on actual hardware

### Writing Tests

- Create testbenches for new modules
- Use meaningful test names
- Include both normal and edge cases
- Document expected behavior
- Use `$display` for progress messages

## Project Structure

When adding new files:

```
Gesture_based_robotic_arm_artix_7/
├── hdl/                    # HDL source files
│   ├── camera/            # Camera-related modules
│   ├── display/           # Display-related modules
│   ├── servo/             # Servo control modules
│   ├── gesture/           # Gesture recognition modules
│   └── top/               # Top-level modules
├── testbench/             # Simulation testbenches
├── constraints/           # XDC constraint files
├── scripts/               # Build and utility scripts
├── datasets/              # Training datasets
└── docs/                  # Documentation
```

## Areas for Contribution

We welcome contributions in these areas:

### High Priority
- [ ] ML hardware accelerator design
- [ ] Improved gesture recognition algorithms
- [ ] Additional camera module support
- [ ] HDMI output implementation
- [ ] Performance optimization

### Medium Priority
- [ ] Web-based monitoring interface
- [ ] Additional gesture types
- [ ] Dataset expansion
- [ ] Calibration tools
- [ ] Power consumption optimization

### Documentation
- [ ] Video tutorials
- [ ] Additional examples
- [ ] Translation to other languages
- [ ] Application notes

### Testing
- [ ] More comprehensive testbenches
- [ ] Automated testing framework
- [ ] Coverage analysis
- [ ] Formal verification

## Code Review Process

1. All contributions require code review
2. At least one maintainer must approve
3. All tests must pass
4. Documentation must be updated
5. No merge conflicts

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

## Questions?

- Open an issue for technical questions
- Check existing documentation first
- Be respectful and constructive

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to this project! 🚀
