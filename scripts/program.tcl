# Vivado TCL Script to Program FPGA
# Programs the FPGA with generated bitstream

set project_name "gesture_robotic_arm"
set top_module "gesture_robotic_arm_top"
set bitstream_file "./vivado_project/${project_name}.runs/impl_1/${top_module}.bit"

# Check if bitstream exists
if {![file exists $bitstream_file]} {
    puts "ERROR: Bitstream file not found: $bitstream_file"
    puts "Please run build.tcl first to generate the bitstream."
    exit 1
}

puts "Opening Hardware Manager..."
open_hw_manager

puts "Connecting to hardware server..."
connect_hw_server -allow_non_jtag

puts "Opening hardware target..."
open_hw_target

# Get the FPGA device
set fpga_device [lindex [get_hw_devices] 0]
puts "Found device: $fpga_device"

# Set bitstream file
puts "Setting bitstream: $bitstream_file"
set_property PROGRAM.FILE $bitstream_file [get_hw_devices $fpga_device]

# Program the device
puts "Programming FPGA..."
program_hw_devices [get_hw_devices $fpga_device]

# Refresh the device
refresh_hw_device [get_hw_devices $fpga_device]

puts "Programming completed successfully!"
puts "FPGA is now running the gesture-based robotic arm system."

# Close hardware manager
close_hw_target
disconnect_hw_server
close_hw_manager

puts "Done!"
