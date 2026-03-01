// VGA Display Controller
// Generates VGA timing signals and displays image data

module vga_controller #(
    parameter H_DISPLAY = 640,
    parameter H_FRONT = 16,
    parameter H_SYNC = 96,
    parameter H_BACK = 48,
    parameter V_DISPLAY = 480,
    parameter V_FRONT = 10,
    parameter V_SYNC = 2,
    parameter V_BACK = 33
)(
    input wire clk_25mhz,        // 25 MHz pixel clock for 640x480@60Hz
    input wire rst_n,
    
    // Pixel data input from frame buffer
    input wire [7:0] pixel_data,
    
    // VGA output signals
    output reg vga_hsync,
    output reg vga_vsync,
    output reg [3:0] vga_r,
    output reg [3:0] vga_g,
    output reg [3:0] vga_b,
    
    // Control signals
    output reg display_enable,
    output reg [15:0] pixel_x,
    output reg [15:0] pixel_y
);

    // Timing parameters
    localparam H_TOTAL = H_DISPLAY + H_FRONT + H_SYNC + H_BACK;
    localparam V_TOTAL = V_DISPLAY + V_FRONT + V_SYNC + V_BACK;
    
    // Counters
    reg [15:0] h_count;
    reg [15:0] v_count;
    
    // Horizontal counter
    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 16'd0;
        end else begin
            if (h_count < H_TOTAL - 1)
                h_count <= h_count + 1;
            else
                h_count <= 16'd0;
        end
    end
    
    // Vertical counter
    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            v_count <= 16'd0;
        end else begin
            if (h_count == H_TOTAL - 1) begin
                if (v_count < V_TOTAL - 1)
                    v_count <= v_count + 1;
                else
                    v_count <= 16'd0;
            end
        end
    end
    
    // Generate sync signals
    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            vga_hsync <= 1'b1;
            vga_vsync <= 1'b1;
        end else begin
            // Horizontal sync (active low)
            if (h_count >= (H_DISPLAY + H_FRONT) && 
                h_count < (H_DISPLAY + H_FRONT + H_SYNC))
                vga_hsync <= 1'b0;
            else
                vga_hsync <= 1'b1;
            
            // Vertical sync (active low)
            if (v_count >= (V_DISPLAY + V_FRONT) && 
                v_count < (V_DISPLAY + V_FRONT + V_SYNC))
                vga_vsync <= 1'b0;
            else
                vga_vsync <= 1'b1;
        end
    end
    
    // Display enable and pixel position
    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            display_enable <= 1'b0;
            pixel_x <= 16'd0;
            pixel_y <= 16'd0;
        end else begin
            if (h_count < H_DISPLAY && v_count < V_DISPLAY) begin
                display_enable <= 1'b1;
                pixel_x <= h_count;
                pixel_y <= v_count;
            end else begin
                display_enable <= 1'b0;
            end
        end
    end
    
    // Output pixel data (convert grayscale to RGB)
    always @(posedge clk_25mhz or negedge rst_n) begin
        if (!rst_n) begin
            vga_r <= 4'd0;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end else begin
            if (display_enable) begin
                // Convert 8-bit grayscale to 4-bit RGB
                vga_r <= pixel_data[7:4];
                vga_g <= pixel_data[7:4];
                vga_b <= pixel_data[7:4];
            end else begin
                vga_r <= 4'd0;
                vga_g <= 4'd0;
                vga_b <= 4'd0;
            end
        end
    end

endmodule
