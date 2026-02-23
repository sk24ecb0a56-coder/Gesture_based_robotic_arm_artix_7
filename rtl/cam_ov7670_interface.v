`timescale 1ns / 1ps

// cam_ov7670_interface.v
// OV7670 camera interface
// Outputs write_row and write_col instead of linear address

module cam_ov7670_interface(

    input  wire        sys_clk,
    input  wire        rst_n,

    // Camera inputs
    input  wire        cam_pclk,
    input  wire        cam_vsync,
    input  wire        cam_href,
    input  wire [7:0]  cam_data,

    // Outputs
    output reg  [15:0] pixel_data,
    output reg  [9:0]  write_col,   // 0..639
    output reg  [9:0]  write_row,   // 0..479
    output reg         write_enable,
    output reg         frame_done
);

    // ================================================================
    // Synchronizers (CDC)
    // ================================================================
    reg [1:0] vsync_sync, href_sync, pclk_sync;
    reg [15:0] data_sync;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            vsync_sync <= 2'b00;
            href_sync  <= 2'b00;
            pclk_sync  <= 2'b00;
            data_sync  <= 16'd0;
        end else begin
            vsync_sync <= {vsync_sync[0], cam_vsync};
            href_sync  <= {href_sync[0], cam_href};
            pclk_sync  <= {pclk_sync[0], cam_pclk};
            data_sync  <= {data_sync[7:0], cam_data};
        end
    end

    wire vsync = vsync_sync[1];
    wire href  = href_sync[1];
    wire pclk  = pclk_sync[1];
    wire [7:0] data = data_sync[7:0];

    // ================================================================
    // PCLK Rising Edge Detection
    // ================================================================
    reg pclk_prev;
    wire pclk_rising = pclk && !pclk_prev;

    always @(posedge sys_clk) begin
        if (!rst_n)
            pclk_prev <= 1'b0;
        else
            pclk_prev <= pclk;
    end

    // ================================================================
    // State Machine
    // ================================================================
    localparam S_IDLE    = 2'd0;
    localparam S_CAPTURE = 2'd1;

    reg [1:0] state;
    reg       byte_toggle;
    reg [7:0] msb_byte;
    reg       vsync_prev;

    // Row/Column counters
    reg [9:0] col_counter;
    reg [9:0] row_counter;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            write_enable <= 1'b0;
            pixel_data   <= 16'd0;
            byte_toggle  <= 1'b0;
            msb_byte     <= 8'd0;
            frame_done   <= 1'b0;
            vsync_prev   <= 1'b0;
            col_counter  <= 10'd0;
            row_counter  <= 10'd0;
            write_col    <= 10'd0;
            write_row    <= 10'd0;
        end else begin

            vsync_prev   <= vsync;
            write_enable <= 1'b0;
            frame_done   <= 1'b0;

            case (state)

                // ----------------------------------------------------
                // WAIT FOR FRAME START
                // ----------------------------------------------------
                S_IDLE: begin
                    if (vsync_prev && !vsync) begin
                        state       <= S_CAPTURE;
                        col_counter <= 10'd0;
                        row_counter <= 10'd0;
                        byte_toggle <= 1'b0;
                    end
                end

                // ----------------------------------------------------
                // CAPTURE FRAME
                // ----------------------------------------------------
                S_CAPTURE: begin

                    // Frame end
                    if (!vsync_prev && vsync) begin
                        state      <= S_IDLE;
                        frame_done <= 1'b1;
                    end

                    // Line end
                    else if (!href) begin
                        byte_toggle <= 1'b0;
                    end

                    // Valid pixel byte
                    else if (href && pclk_rising) begin

                        if (!byte_toggle) begin
                            msb_byte    <= data;
                            byte_toggle <= 1'b1;
                        end else begin
                            // Full RGB565 pixel
                            pixel_data   <= {msb_byte, data};
                            write_enable <= 1'b1;

                            // Output current position
                            write_col <= col_counter;
                            write_row <= row_counter;

                            // Update column counter
                            if (col_counter == 10'd639) begin
                                col_counter <= 10'd0;
                                row_counter <= row_counter + 1;
                            end else begin
                                col_counter <= col_counter + 1;
                            end

                            byte_toggle <= 1'b0;
                        end
                    end
                end

                default: state <= S_IDLE;

            endcase
        end
    end

endmodule
