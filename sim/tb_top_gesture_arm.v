// tb_top_gesture_arm.v
// Testbench for gesture-based robotic arm controller
// Simulates camera signals and monitors outputs

`timescale 1ns / 1ps

module tb_top_gesture_arm;

    // Clock and reset
    reg clk_100mhz;
    reg rst_n;
    
    // Camera signals
    reg       cam_pclk;
    reg       cam_vsync;
    reg       cam_href;
    reg [7:0] cam_data;
    wire      cam_xclk;
    wire      cam_sioc;
    wire      cam_siod;
    wire      cam_reset;
    wire      cam_pwdn;
    
    // VGA outputs
    wire [3:0] vga_r, vga_g, vga_b;
    wire       vga_hsync, vga_vsync;
    
    // Servo outputs
    wire servo_pwm_base, servo_pwm_shoulder;
    wire servo_pwm_elbow, servo_pwm_gripper;
    
    // Debug outputs
    wire [2:0] led_finger_count;
    wire       led_hand_detect;

    // Instantiate DUT
    top_gesture_arm #(
        .H_ACTIVE(640),
        .V_ACTIVE(480),
        .ADDR_WIDTH(19),
        .STABLE_FRAMES(5)
    ) dut (
        .clk_100mhz(clk_100mhz),
        .rst_n(rst_n),
        .cam_pclk(cam_pclk),
        .cam_vsync(cam_vsync),
        .cam_href(cam_href),
        .cam_data(cam_data),
        .cam_xclk(cam_xclk),
        .cam_sioc(cam_sioc),
        .cam_siod(cam_siod),
        .cam_reset(cam_reset),
        .cam_pwdn(cam_pwdn),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .servo_pwm_base(servo_pwm_base),
        .servo_pwm_shoulder(servo_pwm_shoulder),
        .servo_pwm_elbow(servo_pwm_elbow),
        .servo_pwm_gripper(servo_pwm_gripper),
        .led_finger_count(led_finger_count),
        .led_hand_detect(led_hand_detect)
    );

    // Clock generation: 100 MHz
    initial begin
        clk_100mhz = 0;
        forever #5 clk_100mhz = ~clk_100mhz;
    end
    
    // Camera pixel clock: ~25 MHz
    initial begin
        cam_pclk = 0;
        forever #20 cam_pclk = ~cam_pclk;
    end

    // Test sequence
    initial begin
        // Initialize signals
        rst_n      = 0;
        cam_vsync  = 0;
        cam_href   = 0;
        cam_data   = 8'h00;
        
        // Generate VCD waveform dump
        $dumpfile("tb_top_gesture_arm.vcd");
        $dumpvars(0, tb_top_gesture_arm);
        
        // Reset sequence
        #100;
        rst_n = 1;
        #100;
        
        $display("Starting testbench simulation...");
        
        // Simulate camera frame capture
        repeat (3) begin
            send_camera_frame();
        end
        
        // Monitor outputs
        #10000;
        $display("Finger count: %d", led_finger_count);
        $display("Hand detected: %b", led_hand_detect);
        
        // Run for additional time to observe servo PWM
        #1000000;
        
        $display("Testbench completed successfully");
        $finish;
    end

    // Task to simulate camera frame transmission
    task send_camera_frame;
        integer row, col;
        reg [15:0] test_pixel;
        begin
            $display("Sending camera frame at time %t", $time);
            
            // VSYNC falling edge - start of frame
            cam_vsync = 1;
            #400;
            cam_vsync = 0;
            #1000;
            
            // Transmit frame data
            for (row = 0; row < 480; row = row + 1) begin
                // HREF high for active line
                cam_href = 1;
                
                for (col = 0; col < 640; col = col + 1) begin
                    // Generate test pattern (gradient with some "skin-like" regions)
                    if (col >= 200 && col < 400 && row >= 150 && row < 350) begin
                        // Center region: skin tone (RGB ~= 220, 180, 150)
                        test_pixel = 16'hDB6E;  // Approximate skin color in RGB565
                    end else begin
                        // Background: gradient
                        test_pixel = {col[9:5], row[8:3], col[4:0]};
                    end
                    
                    // Send MSB
                    @(posedge cam_pclk);
                    cam_data = test_pixel[15:8];
                    
                    // Send LSB
                    @(posedge cam_pclk);
                    cam_data = test_pixel[7:0];
                end
                
                // HREF low for blanking
                cam_href = 0;
                repeat (20) @(posedge cam_pclk);
            end
            
            // VSYNC rising edge - end of frame
            #1000;
            cam_vsync = 1;
            #400;
            cam_vsync = 0;
            #2000;
        end
    endtask

    // Monitor servo PWM outputs
    initial begin
        forever begin
            @(posedge servo_pwm_base);
            // Could measure pulse width here
        end
    end

endmodule
