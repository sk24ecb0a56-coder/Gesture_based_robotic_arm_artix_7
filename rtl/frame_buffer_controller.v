`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2026 11:21:44
// Design Name: 
// Module Name: frame_buffer_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// frame_buffer_controller.v
// Double-buffered BRAM frame storage
// Separate write ports for RGB and skin mask
// Single read port for VGA display

// frame_buffer_controller.v
// Double-buffered BRAM frame storage
// Downscaled to 160x120 to fit within xc7a100t BRAM capacity
// VGA output upscales by repeating pixels 4x horizontally and 4x vertically

// frame_buffer_controller.v
// Optimized version - NO division/modulo
// 640x480 downscaled to 160x120 (4x4 reduction)
// Double-buffered BRAM implementation

module frame_buffer_controller #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480,
    parameter H_SMALL  = 160,   // 640 / 4
    parameter V_SMALL  = 120,   // 480 / 4
    parameter ADDR_WIDTH = 15   // ceil(log2(160*120)) = 15
)(
    input  wire        clk,
    input  wire        rst_n,

    // Write side (camera domain, already synced)
    input  wire [9:0]  write_col,   // 0..639
    input  wire [9:0]  write_row,   // 0..479
    input  wire [15:0] write_rgb,
    input  wire        write_mask,
    input  wire        write_enable,
    input  wire        frame_done,

    // Read side (VGA domain)
    input  wire [9:0]  read_col,    // 0..639
    input  wire [9:0]  read_row,    // 0..479
    output reg  [15:0] read_rgb,
    output reg         read_mask
);

    // ================================================================
    // Downscaled Memory (160x120 = 19200 pixels)
    // ================================================================
    localparam FRAME_SMALL = H_SMALL * V_SMALL;

    (* ram_style = "block" *)
    reg [15:0] rgb_buffer_0  [0:FRAME_SMALL-1];
    (* ram_style = "block" *)
    reg [15:0] rgb_buffer_1  [0:FRAME_SMALL-1];
    (* ram_style = "block" *)
    reg        mask_buffer_0 [0:FRAME_SMALL-1];
    (* ram_style = "block" *)
    reg        mask_buffer_1 [0:FRAME_SMALL-1];

    // ================================================================
    // Double Buffer Selection
    // ================================================================
    reg buf_sel;

    always @(posedge clk) begin
        if (!rst_n)
            buf_sel <= 1'b0;
        else if (frame_done)
            buf_sel <= ~buf_sel;
    end

    // ================================================================
    // WRITE SIDE (Downsampling)
    // Store only when row%4==0 and col%4==0
    // Using bit slicing instead of division
    // ================================================================

    wire write_sample = (write_col[1:0] == 2'b00) &&
                        (write_row[1:0] == 2'b00);

    wire [7:0] small_row = write_row[9:2];  // divide by 4
    wire [7:0] small_col = write_col[9:2];  // divide by 4

    wire [ADDR_WIDTH-1:0] write_addr_small =
        small_row * H_SMALL + small_col;

    always @(posedge clk) begin
        if (write_enable && write_sample) begin
            if (!buf_sel) begin
                rgb_buffer_1[write_addr_small]  <= write_rgb;
                mask_buffer_1[write_addr_small] <= write_mask;
            end else begin
                rgb_buffer_0[write_addr_small]  <= write_rgb;
                mask_buffer_0[write_addr_small] <= write_mask;
            end
        end
    end

    // ================================================================
    // READ SIDE (Upscaling 4x4 replication)
    // ================================================================

    wire [7:0] read_small_row = read_row[9:2];
    wire [7:0] read_small_col = read_col[9:2];

    wire [ADDR_WIDTH-1:0] read_addr_small =
        read_small_row * H_SMALL + read_small_col;

    always @(posedge clk) begin
        if (!rst_n) begin
            read_rgb  <= 16'd0;
            read_mask <= 1'b0;
        end else begin
            if (buf_sel) begin
                read_rgb  <= rgb_buffer_1[read_addr_small];
                read_mask <= mask_buffer_1[read_addr_small];
            end else begin
                read_rgb  <= rgb_buffer_0[read_addr_small];
                read_mask <= mask_buffer_0[read_addr_small];
            end
        end
    end

endmodule
