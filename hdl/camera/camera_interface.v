// Camera Interface Module for OV7670 or similar camera modules
// Captures image data from camera and outputs to processing pipeline

module camera_interface #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480,
    parameter DATA_WIDTH = 8
)(
    input wire clk,              // System clock
    input wire rst_n,            // Active low reset
    
    // Camera interface signals
    input wire cam_pclk,         // Camera pixel clock
    input wire cam_href,         // Horizontal reference
    input wire cam_vsync,        // Vertical sync
    input wire [7:0] cam_data,   // Camera data (8-bit)
    
    output reg cam_xclk,         // Camera master clock
    output reg cam_pwdn,         // Power down control
    output reg cam_reset,        // Camera reset
    
    // Output to image processing
    output reg [DATA_WIDTH-1:0] pixel_data,
    output reg pixel_valid,
    output reg frame_start,
    output reg frame_end,
    output reg [15:0] pixel_x,
    output reg [15:0] pixel_y
);

    // Internal registers
    reg [7:0] pixel_buffer;
    reg byte_select;
    reg href_d1, href_d2;
    reg vsync_d1, vsync_d2;
    
    // Generate camera clock (half of system clock)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cam_xclk <= 1'b0;
        end else begin
            cam_xclk <= ~cam_xclk;
        end
    end
    
    // Power management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cam_pwdn <= 1'b1;  // Power down initially
            cam_reset <= 1'b0; // Reset camera
        end else begin
            cam_pwdn <= 1'b0;  // Power on
            cam_reset <= 1'b1; // Release reset
        end
    end
    
    // Synchronize href and vsync
    always @(posedge cam_pclk or negedge rst_n) begin
        if (!rst_n) begin
            href_d1 <= 1'b0;
            href_d2 <= 1'b0;
            vsync_d1 <= 1'b0;
            vsync_d2 <= 1'b0;
        end else begin
            href_d1 <= cam_href;
            href_d2 <= href_d1;
            vsync_d1 <= cam_vsync;
            vsync_d2 <= vsync_d1;
        end
    end
    
    // Detect frame boundaries
    wire frame_start_pulse = vsync_d1 && !vsync_d2;
    wire frame_end_pulse = !vsync_d1 && vsync_d2;
    
    // Pixel capture logic
    always @(posedge cam_pclk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_data <= 8'd0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_end <= 1'b0;
            pixel_buffer <= 8'd0;
            byte_select <= 1'b0;
            pixel_x <= 16'd0;
            pixel_y <= 16'd0;
        end else begin
            frame_start <= frame_start_pulse;
            frame_end <= frame_end_pulse;
            
            if (frame_start_pulse) begin
                pixel_x <= 16'd0;
                pixel_y <= 16'd0;
                byte_select <= 1'b0;
            end
            
            if (href_d2) begin
                // Capture pixel data (RGB565 format - 2 bytes per pixel)
                if (byte_select == 1'b0) begin
                    pixel_buffer <= cam_data;
                    byte_select <= 1'b1;
                    pixel_valid <= 1'b0;
                end else begin
                    // Convert RGB565 to grayscale (simple average)
                    // R: cam_data[7:3], G: {cam_data[2:0], pixel_buffer[7:5]}, B: pixel_buffer[4:0]
                    pixel_data <= (cam_data[7:3] + {cam_data[2:0], pixel_buffer[7:5]} + pixel_buffer[4:0]) / 3;
                    pixel_valid <= 1'b1;
                    byte_select <= 1'b0;
                    
                    if (pixel_x < IMG_WIDTH - 1) begin
                        pixel_x <= pixel_x + 1;
                    end else begin
                        pixel_x <= 16'd0;
                        if (pixel_y < IMG_HEIGHT - 1) begin
                            pixel_y <= pixel_y + 1;
                        end
                    end
                end
            end else begin
                pixel_valid <= 1'b0;
            end
        end
    end

endmodule
