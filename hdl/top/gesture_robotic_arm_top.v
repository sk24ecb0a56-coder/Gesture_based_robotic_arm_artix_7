// Top-level module for Gesture-Based Robotic Arm Control System
// Integrates camera, display, gesture recognition, and servo control

module gesture_robotic_arm_top #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
)(
    // System clock and reset
    input wire clk_100mhz,       // 100 MHz system clock
    input wire rst_n,            // Active low reset
    
    // Camera interface (OV7670 or similar)
    input wire cam_pclk,
    input wire cam_href,
    input wire cam_vsync,
    input wire [7:0] cam_data,
    output wire cam_xclk,
    output wire cam_pwdn,
    output wire cam_reset,
    
    // VGA display interface
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    
    // Servo control outputs (4-axis robotic arm)
    output wire servo0_pwm,      // Base rotation
    output wire servo1_pwm,      // Shoulder
    output wire servo2_pwm,      // Elbow
    output wire servo3_pwm,      // Gripper
    
    // Status LEDs
    output wire [3:0] led_finger_count,
    output wire led_frame_ready
);

    // Clock generation signals
    wire clk_25mhz;  // For VGA
    wire locked;
    
    // Camera to frame buffer signals
    wire [7:0] cam_pixel_data;
    wire cam_pixel_valid;
    wire cam_frame_start;
    wire cam_frame_end;
    wire [15:0] cam_pixel_x;
    wire [15:0] cam_pixel_y;
    
    // Frame buffer signals
    wire [18:0] fb_wr_addr;
    wire fb_we;
    wire [7:0] fb_wr_data;
    wire [18:0] fb_rd_addr;
    wire [7:0] fb_rd_data;
    
    // Gesture recognition signals
    wire [3:0] finger_count;
    wire gesture_valid;
    wire [7:0] gesture_id;
    
    // Servo angle signals
    wire [7:0] servo0_angle;
    wire [7:0] servo1_angle;
    wire [7:0] servo2_angle;
    wire [7:0] servo3_angle;
    
    // VGA controller signals
    wire vga_display_enable;
    wire [15:0] vga_pixel_x;
    wire [15:0] vga_pixel_y;
    
    // Frame buffer write address calculation
    assign fb_wr_addr = (cam_pixel_y * IMG_WIDTH) + cam_pixel_x;
    assign fb_we = cam_pixel_valid;
    assign fb_wr_data = cam_pixel_data;
    
    // Frame buffer read address calculation
    assign fb_rd_addr = (vga_pixel_y * IMG_WIDTH) + vga_pixel_x;
    
    // Status LEDs
    assign led_finger_count = finger_count;
    assign led_frame_ready = cam_frame_end;
    
    // Clock wizard - Generate 25 MHz for VGA from 100 MHz system clock
    // Note: In actual implementation, use Xilinx Clock Wizard IP
    // For simulation, we use a simple clock divider
    reg [1:0] clk_div;
    always @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n)
            clk_div <= 2'd0;
        else
            clk_div <= clk_div + 1;
    end
    assign clk_25mhz = clk_div[1];  // Divide by 4: 100MHz -> 25MHz
    assign locked = rst_n;
    
    // Camera interface module
    camera_interface #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT)
    ) cam_if (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .cam_pclk(cam_pclk),
        .cam_href(cam_href),
        .cam_vsync(cam_vsync),
        .cam_data(cam_data),
        .cam_xclk(cam_xclk),
        .cam_pwdn(cam_pwdn),
        .cam_reset(cam_reset),
        .pixel_data(cam_pixel_data),
        .pixel_valid(cam_pixel_valid),
        .frame_start(cam_frame_start),
        .frame_end(cam_frame_end),
        .pixel_x(cam_pixel_x),
        .pixel_y(cam_pixel_y)
    );
    
    // Frame buffer
    frame_buffer #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .ADDR_WIDTH(19),
        .DATA_WIDTH(8)
    ) fb (
        .clk_a(cam_pclk),
        .we_a(fb_we),
        .addr_a(fb_wr_addr),
        .data_in_a(fb_wr_data),
        .clk_b(clk_25mhz),
        .addr_b(fb_rd_addr),
        .data_out_b(fb_rd_data)
    );
    
    // VGA controller
    vga_controller #(
        .H_DISPLAY(640),
        .H_FRONT(16),
        .H_SYNC(96),
        .H_BACK(48),
        .V_DISPLAY(480),
        .V_FRONT(10),
        .V_SYNC(2),
        .V_BACK(33)
    ) vga (
        .clk_25mhz(clk_25mhz),
        .rst_n(rst_n),
        .pixel_data(fb_rd_data),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .display_enable(vga_display_enable),
        .pixel_x(vga_pixel_x),
        .pixel_y(vga_pixel_y)
    );
    
    // Gesture recognition module
    gesture_recognizer #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .THRESHOLD(8'd128)
    ) gesture_rec (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .pixel_data(cam_pixel_data),
        .pixel_valid(cam_pixel_valid),
        .frame_start(cam_frame_start),
        .frame_end(cam_frame_end),
        .pixel_x(cam_pixel_x),
        .pixel_y(cam_pixel_y),
        .finger_count(finger_count),
        .gesture_valid(gesture_valid),
        .gesture_id(gesture_id)
    );
    
    // Gesture to servo mapper
    gesture_to_servo #(
        .NUM_GESTURES(6)
    ) g2s (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .finger_count(finger_count),
        .gesture_valid(gesture_valid),
        .gesture_id(gesture_id),
        .servo0_angle(servo0_angle),
        .servo1_angle(servo1_angle),
        .servo2_angle(servo2_angle),
        .servo3_angle(servo3_angle)
    );
    
    // Servo controller
    servo_controller #(
        .CLK_FREQ(100_000_000),
        .NUM_SERVOS(4)
    ) servo_ctrl (
        .clk(clk_100mhz),
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

endmodule
