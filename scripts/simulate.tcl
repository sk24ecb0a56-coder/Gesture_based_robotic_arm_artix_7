# Vivado TCL Simulation Script
# Runs testbenches for the gesture-based robotic arm modules

set project_name "gesture_robotic_arm"
set proj_dir "./vivado_project"

# Open project if it exists
if {[file exists "$proj_dir/${project_name}.xpr"]} {
    open_project "$proj_dir/${project_name}.xpr"
} else {
    puts "ERROR: Project not found. Please run build.tcl first."
    exit 1
}

puts "Running simulations..."

# Simulate Gesture Recognizer
puts "\n========================================="
puts "Simulating Gesture Recognizer Module"
puts "========================================="
set_property top tb_gesture_recognizer [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run 500us
close_sim

# Simulate Servo Controller
puts "\n========================================="
puts "Simulating Servo Controller Module"
puts "========================================="
set_property top tb_servo_controller [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run 200ms
close_sim

puts "\nAll simulations completed!"
