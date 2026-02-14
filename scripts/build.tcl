# Vivado TCL Build Script for Gesture-Based Robotic Arm
# Automates the build process for Artix-7 FPGA

# Set project parameters
set project_name "gesture_robotic_arm"
set part_name "xc7a100tcsg324-1"  # Artix-7 100T (Nexys A7)
set top_module "gesture_robotic_arm_top"

# Create project directory
set proj_dir "./vivado_project"
file mkdir $proj_dir

# Create project
create_project $project_name $proj_dir -part $part_name -force

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add source files
puts "Adding HDL source files..."

# Camera interface
add_files -norecurse ./hdl/camera/camera_interface.v

# Display modules
add_files -norecurse ./hdl/display/vga_controller.v
add_files -norecurse ./hdl/display/frame_buffer.v

# Servo control
add_files -norecurse ./hdl/servo/servo_controller.v

# Gesture recognition
add_files -norecurse ./hdl/gesture/gesture_recognizer.v
add_files -norecurse ./hdl/gesture/gesture_to_servo.v

# Top level
add_files -norecurse ./hdl/top/gesture_robotic_arm_top.v

# Add constraints
puts "Adding constraints file..."
add_files -fileset constrs_1 -norecurse ./constraints/artix7_constraints.xdc

# Add simulation files
puts "Adding simulation files..."
add_files -fileset sim_1 -norecurse ./testbench/tb_gesture_recognizer.v
add_files -fileset sim_1 -norecurse ./testbench/tb_servo_controller.v

# Set top module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "Project setup complete!"

# Run synthesis
puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis results
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}
puts "Synthesis completed successfully!"

# Open synthesized design
open_run synth_1

# Generate synthesis reports
puts "Generating synthesis reports..."
report_timing_summary -file $proj_dir/timing_summary_synth.rpt
report_utilization -file $proj_dir/utilization_synth.rpt
report_power -file $proj_dir/power_synth.rpt

# Run implementation
puts "Running implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check implementation results
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}
puts "Implementation completed successfully!"

# Open implemented design
open_run impl_1

# Generate implementation reports
puts "Generating implementation reports..."
report_timing_summary -file $proj_dir/timing_summary_impl.rpt
report_utilization -file $proj_dir/utilization_impl.rpt
report_power -file $proj_dir/power_impl.rpt
report_drc -file $proj_dir/drc_impl.rpt

# Bitstream is already generated
puts "Bitstream generation complete!"
puts "Bitstream location: $proj_dir/${project_name}.runs/impl_1/${top_module}.bit"

puts "\nBuild completed successfully!"
puts "===================================="
puts "Project: $project_name"
puts "Part: $part_name"
puts "Top Module: $top_module"
puts "===================================="
