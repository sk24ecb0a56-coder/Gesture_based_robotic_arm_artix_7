`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.02.2026 11:32:51
// Design Name: 
// Module Name: vga_controller
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

// vga_controller.v
// Standard 640x480 @60Hz VGA timing generator
// Generates sync signals and pixel coordinates

// vga_controller.v
// Clean version without read_addr

module vga_controller #(
    parameter H_ACTIVE = 640,
    parameter H_FP     = 16,
    parameter H_SYNC   = 96,
    parameter H_BP     = 48,
    parameter V_ACTIVE = 480,
    parameter V_FP     = 10,
    parameter V_SYNC   = 2,
    parameter V_BP     = 33
)(
    input  wire        clk_25mhz,
    input  wire        rst_n,
    output reg         hsync,
    output reg         vsync,
    output wire        active,
    output wire [9:0]  x_pos,
    output wire [9:0]  y_pos
);

    localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;
    localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;

    reg [9:0] h_counter;
    reg [9:0] v_counter;

    always @(posedge clk_25mhz) begin
        if (!rst_n) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                h_counter <= 0;
                if (v_counter == V_TOTAL - 1)
                    v_counter <= 0;
                else
                    v_counter <= v_counter + 1;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    always @(posedge clk_25mhz) begin
        if (!rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_counter >= (H_ACTIVE + H_FP)) &&
                      (h_counter < (H_ACTIVE + H_FP + H_SYNC)));
            vsync <= ~((v_counter >= (V_ACTIVE + V_FP)) &&
                      (v_counter < (V_ACTIVE + V_FP + V_SYNC)));
        end
    end

    assign active = (h_counter < H_ACTIVE) &&
                    (v_counter < V_ACTIVE);

    assign x_pos = h_counter;
    assign y_pos = v_counter;

endmodule
