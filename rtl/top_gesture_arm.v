// top_gesture_arm.v
// Top-level integration for gesture-based robotic arm controller
// Connects all processing stages in the pipeline

module top_gesture_arm #(
    parameter H_ACTIVE      = 640,
    parameter V_ACTIVE      = 480,
    parameter ADDR_WIDTH    = 19,
    parameter STABLE_FRAMES = 5
)(
    // System clock and reset
    input  wire       clk_100mhz,
    input  wire       rst_n,
    
    // OV7670 camera interface
    input  wire       cam_pclk,
    input  wire       cam_vsync,
    input  wire       cam_href,
    input  wire [7:0] cam_data,
    output wire       cam_xclk,
    output wire       cam_sioc,
    inout  wire       cam_siod,
    output wire       cam_reset,
    output wire       cam_pwdn,
    
    // VGA output
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       vga_hsync,
    output wire       vga_vsync,
    
    // Servo PWM outputs
    output wire       servo_pwm_base,
    output wire       servo_pwm_shoulder,
    output wire       servo_pwm_elbow,
    output wire       servo_pwm_gripper,
    
    // Debug LEDs
    output wire [2:0] led_finger_count,
    output wire       led_hand_detect
);

    // ========================================================================
    // Clock Generation
    // ========================================================================
    
    wire clk_25mhz;
    clk_divider #(
        .DIV_FACTOR(4)
    ) u_clk_divider (
        .clk_in(clk_100mhz),
        .rst_n(rst_n),
        .clk_out(clk_25mhz)
    );
    
    // Camera clock output (25MHz)
    assign cam_xclk  = clk_25mhz;
    assign cam_reset = rst_n;
    assign cam_pwdn  = 1'b0;
    
    // SCCB/I2C lines (camera pre-configured externally)
    assign cam_sioc = 1'b1;
    assign cam_siod = 1'bz;

    // ========================================================================
    // Camera Interface
    // ========================================================================
    
    wire [15:0] cam_pixel_data;
    wire [ADDR_WIDTH-1:0] cam_write_addr;
    wire        cam_write_enable;
    wire        cam_frame_done;
    
    cam_ov7670_interface #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_cam_interface (
        .sys_clk(clk_100mhz),
        .rst_n(rst_n),
        .cam_pclk(cam_pclk),
        .cam_vsync(cam_vsync),
        .cam_href(cam_href),
        .cam_data(cam_data),
        .pixel_data(cam_pixel_data),
        .write_addr(cam_write_addr),
        .write_enable(cam_write_enable),
        .frame_done(cam_frame_done)
    );

    // ========================================================================
    // Color Space Conversion: RGB565 -> YCbCr
    // ========================================================================
    
    wire [7:0] ycbcr_y, ycbcr_cb, ycbcr_cr;
    wire       ycbcr_valid;
    
    rgb565_to_ycbcr u_color_convert (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .rgb565(cam_pixel_data),
        .valid_in(cam_write_enable),
        .y_out(ycbcr_y),
        .cb_out(ycbcr_cb),
        .cr_out(ycbcr_cr),
        .valid_out(ycbcr_valid)
    );

    // ========================================================================
    // Skin Detection
    // ========================================================================
    
    wire skin_mask_raw;
    wire skin_valid;
    
    skin_detector u_skin_detector (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .y_in(ycbcr_y),
        .cb_in(ycbcr_cb),
        .cr_in(ycbcr_cr),
        .valid_in(ycbcr_valid),
        .skin_mask(skin_mask_raw),
        .valid_out(skin_valid)
    );

    // ========================================================================
    // Morphological Filter (Erosion)
    // ========================================================================
    
    wire skin_mask_filtered;
    wire morph_valid;
    
    morphological_filter #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE)
    ) u_morph_filter (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .pixel_in(skin_mask_raw),
        .valid_in(skin_valid),
        .frame_done(cam_frame_done),
        .pixel_out(skin_mask_filtered),
        .valid_out(morph_valid)
    );

    // ========================================================================
    // Finger Counting
    // ========================================================================
    
    wire [2:0] raw_finger_count;
    wire       count_valid;
    wire       hand_detected;
    
    finger_counter #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE),
        .COL_THRESH(30),
        .HAND_THRESH(2000)
    ) u_finger_counter (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .skin_pixel(skin_mask_filtered),
        .pixel_valid(morph_valid),
        .frame_done(cam_frame_done),
        .finger_count(raw_finger_count),
        .count_valid(count_valid),
        .hand_detected(hand_detected)
    );

    // ========================================================================
    // Count Stabilization
    // ========================================================================
    
    wire [2:0] stable_finger_count;
    
    count_stabilizer #(
        .STABLE_FRAMES(STABLE_FRAMES)
    ) u_count_stabilizer (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .raw_count(raw_finger_count),
        .count_valid(count_valid),
        .stable_count(stable_finger_count)
    );

    // ========================================================================
    // Frame Buffer (Double-buffered)
    // ========================================================================
    
    wire [ADDR_WIDTH-1:0] fb_read_addr;
    wire [15:0] fb_rgb;
    wire        fb_mask;
    
    frame_buffer_controller #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_frame_buffer (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .write_addr(cam_write_addr),
        .write_rgb(cam_pixel_data),
        .write_mask(skin_mask_filtered),
        .write_enable(cam_write_enable),
        .frame_done(cam_frame_done),
        .read_addr(fb_read_addr),
        .read_rgb(fb_rgb),
        .read_mask(fb_mask)
    );

    // ========================================================================
    // VGA Controller
    // ========================================================================
    
    wire [9:0] vga_x, vga_y;
    wire       vga_active;
    
    vga_controller #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE)
    ) u_vga_controller (
        .clk_25mhz(clk_25mhz),
        .rst_n(rst_n),
        .hsync(vga_hsync),
        .vsync(vga_vsync),
        .active(vga_active),
        .x_pos(vga_x),
        .y_pos(vga_y),
        .read_addr(fb_read_addr)
    );

    // ========================================================================
    // VGA Overlay Display
    // ========================================================================
    
    vga_overlay #(
        .H_ACTIVE(H_ACTIVE),
        .V_ACTIVE(V_ACTIVE)
    ) u_vga_overlay (
        .clk(clk_25mhz),
        .rst_n(rst_n),
        .x_pos(vga_x),
        .y_pos(vga_y),
        .active(vga_active),
        .rgb565(fb_rgb),
        .skin_mask(fb_mask),
        .finger_count(stable_finger_count),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b)
    );

    // ========================================================================
    // Servo Control
    // ========================================================================
    
    wire [7:0] servo_angle_base, servo_angle_shoulder;
    wire [7:0] servo_angle_elbow, servo_angle_gripper;
    
    servo_mapper #(
        .RAMP_PERIOD(65536)
    ) u_servo_mapper (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .finger_count(stable_finger_count),
        .hand_detected(hand_detected),
        .angle_base(servo_angle_base),
        .angle_shoulder(servo_angle_shoulder),
        .angle_elbow(servo_angle_elbow),
        .angle_gripper(servo_angle_gripper)
    );
    
    pwm_servo_driver u_pwm_driver (
        .clk(clk_100mhz),
        .rst_n(rst_n),
        .angle_0(servo_angle_base),
        .angle_1(servo_angle_shoulder),
        .angle_2(servo_angle_elbow),
        .angle_3(servo_angle_gripper),
        .pwm_0(servo_pwm_base),
        .pwm_1(servo_pwm_shoulder),
        .pwm_2(servo_pwm_elbow),
        .pwm_3(servo_pwm_gripper)
    );

    // ========================================================================
    // Debug LEDs
    // ========================================================================
    
    assign led_finger_count = stable_finger_count;
    assign led_hand_detect  = hand_detected;

endmodule
