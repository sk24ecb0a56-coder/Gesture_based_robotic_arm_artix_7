// vga_overlay.v
// VGA display with split-screen visualization
// Left: Raw camera RGB image
// Right: Binary skin mask
// Top-left: Green bars indicating finger count

module vga_overlay #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire [9:0]  x_pos,
    input  wire [9:0]  y_pos,
    input  wire        active,
    input  wire [15:0] rgb565,         // Camera RGB data
    input  wire        skin_mask,      // Binary skin mask
    input  wire [2:0]  finger_count,   // Current finger count
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    // Split screen at x=320
    localparam SPLIT_X = 320;
    
    // Finger count bars: 30px wide each, 5 max, at top-left
    localparam BAR_WIDTH  = 30;
    localparam BAR_HEIGHT = 20;
    localparam BAR_Y_POS  = 10;

    always @(posedge clk) begin
        if (!rst_n) begin
            vga_r <= 4'd0;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end else if (active) begin
            // Check if in finger count bar region
            if (y_pos >= BAR_Y_POS && y_pos < (BAR_Y_POS + BAR_HEIGHT) &&
                x_pos < (BAR_WIDTH * 5)) begin
                // Determine which bar slot we're in (0-4)
                if (x_pos < (finger_count * BAR_WIDTH)) begin
                    // Active bar - green
                    vga_r <= 4'd0;
                    vga_g <= 4'd15;
                    vga_b <= 4'd0;
                end else begin
                    // Inactive bar - dark gray
                    vga_r <= 4'd3;
                    vga_g <= 4'd3;
                    vga_b <= 4'd3;
                end
            end
            // Left half: Raw camera image
            else if (x_pos < SPLIT_X) begin
                // Convert RGB565 to 4-bit per channel
                vga_r <= {rgb565[15:12]};              // R: bits 15-11 -> use top 4
                vga_g <= {rgb565[10:7]};               // G: bits 10-5  -> use top 4
                vga_b <= {rgb565[4:1]};                // B: bits 4-0   -> use top 4
            end
            // Right half: Binary skin mask
            else begin
                if (skin_mask) begin
                    // Skin detected - white
                    vga_r <= 4'd15;
                    vga_g <= 4'd15;
                    vga_b <= 4'd15;
                end else begin
                    // No skin - black
                    vga_r <= 4'd0;
                    vga_g <= 4'd0;
                    vga_b <= 4'd0;
                end
            end
        end else begin
            // Blanking period - output black
            vga_r <= 4'd0;
            vga_g <= 4'd0;
            vga_b <= 4'd0;
        end
    end

endmodule
