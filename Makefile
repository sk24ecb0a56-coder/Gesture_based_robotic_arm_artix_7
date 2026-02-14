# Makefile for Gesture-Based Robotic Arm Project
# Simplifies common Vivado operations

.PHONY: help build simulate clean program

# Default target
help:
	@echo "Gesture-Based Robotic Arm - Makefile"
	@echo "===================================="
	@echo "Available targets:"
	@echo "  make build      - Build the project (synthesis + implementation + bitstream)"
	@echo "  make simulate   - Run simulations"
	@echo "  make clean      - Clean build artifacts"
	@echo "  make program    - Program FPGA (requires hardware connection)"
	@echo "  make help       - Show this help message"

# Build project using Vivado
build:
	@echo "Building project..."
	vivado -mode batch -source scripts/build.tcl

# Run simulations
simulate:
	@echo "Running simulations..."
	vivado -mode batch -source scripts/simulate.tcl

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf vivado_project
	rm -rf .Xil
	rm -rf *.jou
	rm -rf *.log
	rm -rf *.str
	find . -name "*.vcd" -delete
	find . -name "*.wdb" -delete
	@echo "Clean complete!"

# Program FPGA
program:
	@echo "Programming FPGA..."
	@if [ ! -f vivado_project/gesture_robotic_arm.runs/impl_1/gesture_robotic_arm_top.bit ]; then \
		echo "Error: Bitstream not found. Run 'make build' first."; \
		exit 1; \
	fi
	vivado -mode batch -source scripts/program.tcl

# Quick syntax check using iverilog
syntax-check:
	@echo "Checking Verilog syntax..."
	@command -v iverilog >/dev/null 2>&1 || { echo "iverilog not installed. Skipping syntax check."; exit 0; }
	@for file in hdl/*/*.v; do \
		echo "Checking $$file..."; \
		iverilog -t null -Wall $$file || true; \
	done
	@echo "Syntax check complete!"

# Create project directory structure
init:
	@echo "Initializing project directories..."
	mkdir -p hdl/{camera,display,servo,gesture,top}
	mkdir -p testbench
	mkdir -p constraints
	mkdir -p scripts
	mkdir -p datasets/{finger_count,test_images}
	mkdir -p docs
	@echo "Project structure created!"
