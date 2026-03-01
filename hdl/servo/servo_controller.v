// Servo Control Module for 4-Axis Robotic Arm
// Generates PWM signals to control servo motors
// Standard servo: 1ms (0°) to 2ms (180°) pulse width, 20ms period (50Hz)

module servo_controller #(
    parameter CLK_FREQ = 100_000_000,  // 100 MHz system clock
    parameter NUM_SERVOS = 4            // 4-axis robotic arm
)(
    input wire clk,
    input wire rst_n,
    
    // Servo position inputs (0-180 degrees for each axis)
    input wire [7:0] servo0_angle,  // Base rotation
    input wire [7:0] servo1_angle,  // Shoulder
    input wire [7:0] servo2_angle,  // Elbow
    input wire [7:0] servo3_angle,  // Gripper
    
    // PWM outputs to servos
    output reg servo0_pwm,
    output reg servo1_pwm,
    output reg servo2_pwm,
    output reg servo3_pwm
);

    // PWM period counter (20ms = 2,000,000 clock cycles at 100MHz)
    localparam PERIOD_CYCLES = CLK_FREQ / 50;  // 50Hz = 20ms period
    localparam MIN_PULSE = CLK_FREQ / 1000;     // 1ms minimum pulse
    localparam MAX_PULSE = CLK_FREQ / 500;      // 2ms maximum pulse
    
    reg [31:0] period_counter;
    reg [31:0] servo0_pulse_width;
    reg [31:0] servo1_pulse_width;
    reg [31:0] servo2_pulse_width;
    reg [31:0] servo3_pulse_width;
    
    // Calculate pulse width based on angle (0-180 degrees)
    // pulse_width = MIN_PULSE + (angle * (MAX_PULSE - MIN_PULSE) / 180)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            servo0_pulse_width <= MIN_PULSE;
            servo1_pulse_width <= MIN_PULSE;
            servo2_pulse_width <= MIN_PULSE;
            servo3_pulse_width <= MIN_PULSE;
        end else begin
            servo0_pulse_width <= MIN_PULSE + ((servo0_angle * (MAX_PULSE - MIN_PULSE)) / 180);
            servo1_pulse_width <= MIN_PULSE + ((servo1_angle * (MAX_PULSE - MIN_PULSE)) / 180);
            servo2_pulse_width <= MIN_PULSE + ((servo2_angle * (MAX_PULSE - MIN_PULSE)) / 180);
            servo3_pulse_width <= MIN_PULSE + ((servo3_angle * (MAX_PULSE - MIN_PULSE)) / 180);
        end
    end
    
    // Period counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            period_counter <= 32'd0;
        end else begin
            if (period_counter < PERIOD_CYCLES - 1)
                period_counter <= period_counter + 1;
            else
                period_counter <= 32'd0;
        end
    end
    
    // Generate PWM signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            servo0_pwm <= 1'b0;
            servo1_pwm <= 1'b0;
            servo2_pwm <= 1'b0;
            servo3_pwm <= 1'b0;
        end else begin
            // Servo 0 PWM
            if (period_counter < servo0_pulse_width)
                servo0_pwm <= 1'b1;
            else
                servo0_pwm <= 1'b0;
            
            // Servo 1 PWM
            if (period_counter < servo1_pulse_width)
                servo1_pwm <= 1'b1;
            else
                servo1_pwm <= 1'b0;
            
            // Servo 2 PWM
            if (period_counter < servo2_pulse_width)
                servo2_pwm <= 1'b1;
            else
                servo2_pwm <= 1'b0;
            
            // Servo 3 PWM
            if (period_counter < servo3_pulse_width)
                servo3_pwm <= 1'b1;
            else
                servo3_pwm <= 1'b0;
        end
    end

endmodule
