// Testbench for Servo Controller Module
`timescale 1ns / 1ps

module tb_servo_controller;

    // Parameters
    parameter CLK_PERIOD = 10;  // 100 MHz (10ns period)
    parameter CLK_FREQ = 100_000_000;
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg [7:0] servo0_angle;
    reg [7:0] servo1_angle;
    reg [7:0] servo2_angle;
    reg [7:0] servo3_angle;
    
    wire servo0_pwm;
    wire servo1_pwm;
    wire servo2_pwm;
    wire servo3_pwm;
    
    // Instantiate the servo controller
    servo_controller #(
        .CLK_FREQ(CLK_FREQ),
        .NUM_SERVOS(4)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .servo0_angle(servo0_angle),
        .servo1_angle(servo1_angle),
        .servo2_angle(servo2_angle),
        .servo3_angle(servo3_angle),
        .servo0_pwm(servo0_pwm),
        .servo1_pwm(servo1_pwm),
        .servo2_pwm(servo2_pwm),
        .servo3_pwm(servo3_pwm)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Pulse width measurement
    integer servo0_high_time, servo1_high_time, servo2_high_time, servo3_high_time;
    real servo0_pulse_ms, servo1_pulse_ms, servo2_pulse_ms, servo3_pulse_ms;
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        servo0_angle = 0;
        servo1_angle = 0;
        servo2_angle = 0;
        servo3_angle = 0;
        
        // Reset
        #(CLK_PERIOD*100);
        rst_n = 1;
        #(CLK_PERIOD*100);
        
        // Test Case 1: All servos at 0 degrees (should be ~1ms pulse)
        $display("\nTest Case 1: All servos at 0 degrees");
        servo0_angle = 8'd0;
        servo1_angle = 8'd0;
        servo2_angle = 8'd0;
        servo3_angle = 8'd0;
        measure_pulses();
        
        // Test Case 2: All servos at 90 degrees (should be ~1.5ms pulse)
        $display("\nTest Case 2: All servos at 90 degrees");
        servo0_angle = 8'd90;
        servo1_angle = 8'd90;
        servo2_angle = 8'd90;
        servo3_angle = 8'd90;
        measure_pulses();
        
        // Test Case 3: All servos at 180 degrees (should be ~2ms pulse)
        $display("\nTest Case 3: All servos at 180 degrees");
        servo0_angle = 8'd180;
        servo1_angle = 8'd180;
        servo2_angle = 8'd180;
        servo3_angle = 8'd180;
        measure_pulses();
        
        // Test Case 4: Different angles for each servo
        $display("\nTest Case 4: Different angles - 0, 60, 120, 180 degrees");
        servo0_angle = 8'd0;
        servo1_angle = 8'd60;
        servo2_angle = 8'd120;
        servo3_angle = 8'd180;
        measure_pulses();
        
        $display("\nAll test cases completed");
        $finish;
    end
    
    // Task to measure pulse widths
    task measure_pulses;
        begin
            // Wait for start of a new PWM period
            @(posedge servo0_pwm);
            
            // Measure servo0
            servo0_high_time = 0;
            while (servo0_pwm == 1'b1) begin
                #(CLK_PERIOD);
                servo0_high_time = servo0_high_time + CLK_PERIOD;
            end
            servo0_pulse_ms = servo0_high_time / 1000000.0;
            
            // Measure servo1
            @(posedge servo1_pwm);
            servo1_high_time = 0;
            while (servo1_pwm == 1'b1) begin
                #(CLK_PERIOD);
                servo1_high_time = servo1_high_time + CLK_PERIOD;
            end
            servo1_pulse_ms = servo1_high_time / 1000000.0;
            
            // Measure servo2
            @(posedge servo2_pwm);
            servo2_high_time = 0;
            while (servo2_pwm == 1'b1) begin
                #(CLK_PERIOD);
                servo2_high_time = servo2_high_time + CLK_PERIOD;
            end
            servo2_pulse_ms = servo2_high_time / 1000000.0;
            
            // Measure servo3
            @(posedge servo3_pwm);
            servo3_high_time = 0;
            while (servo3_pwm == 1'b1) begin
                #(CLK_PERIOD);
                servo3_high_time = servo3_high_time + CLK_PERIOD;
            end
            servo3_pulse_ms = servo3_high_time / 1000000.0;
            
            // Display results
            $display("Servo 0: Angle=%d, Pulse Width=%.3f ms", servo0_angle, servo0_pulse_ms);
            $display("Servo 1: Angle=%d, Pulse Width=%.3f ms", servo1_angle, servo1_pulse_ms);
            $display("Servo 2: Angle=%d, Pulse Width=%.3f ms", servo2_angle, servo2_pulse_ms);
            $display("Servo 3: Angle=%d, Pulse Width=%.3f ms", servo3_angle, servo3_pulse_ms);
        end
    endtask
    
    // Dump waveforms
    initial begin
        $dumpfile("servo_controller.vcd");
        $dumpvars(0, tb_servo_controller);
    end

endmodule
