// frame_buffer_controller.v
// Double-buffered BRAM frame storage
// Separate write ports for RGB and skin mask
// Single read port for VGA display

module frame_buffer_controller #(
    parameter H_ACTIVE   = 640,
    parameter V_ACTIVE   = 480,
    parameter ADDR_WIDTH = 19          // 640*480 = 307200
)(
    input  wire        clk,
    input  wire        rst_n,
    // Write port (camera side)
    input  wire [ADDR_WIDTH-1:0] write_addr,
    input  wire [15:0] write_rgb,      // RGB565 data
    input  wire        write_mask,     // Skin mask bit
    input  wire        write_enable,
    input  wire        frame_done,     // Toggle buffers on frame completion
    // Read port (VGA side)
    input  wire [ADDR_WIDTH-1:0] read_addr,
    output reg  [15:0] read_rgb,
    output reg         read_mask
);

    // BRAM inference attribute
    (* ram_style = "block" *)
    reg [15:0] rgb_buffer_0  [0:(1<<ADDR_WIDTH)-1];
    (* ram_style = "block" *)
    reg [15:0] rgb_buffer_1  [0:(1<<ADDR_WIDTH)-1];
    (* ram_style = "block" *)
    reg        mask_buffer_0 [0:(1<<ADDR_WIDTH)-1];
    (* ram_style = "block" *)
    reg        mask_buffer_1 [0:(1<<ADDR_WIDTH)-1];

    // Buffer selection: 0 or 1
    reg buf_sel;

    // Toggle buffer on frame completion
    always @(posedge clk) begin
        if (!rst_n) begin
            buf_sel <= 1'b0;
        end else if (frame_done) begin
            buf_sel <= ~buf_sel;
        end
    end

    // Write to inactive buffer (opposite of buf_sel)
    always @(posedge clk) begin
        if (write_enable) begin
            // Bounds checking
            if (write_addr < (H_ACTIVE * V_ACTIVE)) begin
                if (!buf_sel) begin
                    rgb_buffer_1[write_addr]  <= write_rgb;
                    mask_buffer_1[write_addr] <= write_mask;
                end else begin
                    rgb_buffer_0[write_addr]  <= write_rgb;
                    mask_buffer_0[write_addr] <= write_mask;
                end
            end
        end
    end

    // Read from active buffer (1-cycle latency for BRAM)
    always @(posedge clk) begin
        if (!rst_n) begin
            read_rgb  <= 16'd0;
            read_mask <= 1'b0;
        end else begin
            // Bounds checking
            if (read_addr < (H_ACTIVE * V_ACTIVE)) begin
                if (buf_sel) begin
                    read_rgb  <= rgb_buffer_1[read_addr];
                    read_mask <= mask_buffer_1[read_addr];
                end else begin
                    read_rgb  <= rgb_buffer_0[read_addr];
                    read_mask <= mask_buffer_0[read_addr];
                end
            end else begin
                read_rgb  <= 16'd0;
                read_mask <= 1'b0;
            end
        end
    end

endmodule
