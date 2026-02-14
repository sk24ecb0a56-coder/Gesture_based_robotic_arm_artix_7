// cam_ov7670_interface.v
// OV7670 camera interface with clock domain crossing
// 2-FF synchronizers for all camera signals
// RGB565 output format

module cam_ov7670_interface #(
    parameter ADDR_WIDTH = 19          // 640*480 = 307200 pixels
)(
    input  wire        sys_clk,        // System clock (100 MHz)
    input  wire        rst_n,
    // Camera inputs
    input  wire        cam_pclk,       // Camera pixel clock
    input  wire        cam_vsync,      // Vertical sync
    input  wire        cam_href,       // Horizontal reference
    input  wire [7:0]  cam_data,       // Camera data
    // Outputs
    output reg  [15:0] pixel_data,     // RGB565 pixel output
    output reg  [ADDR_WIDTH-1:0] write_addr,
    output reg         write_enable,
    output reg         frame_done
);

    // 2-FF synchronizers for clock domain crossing
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

    // Edge detection for pclk
    reg pclk_prev;
    wire pclk_rising = pclk && !pclk_prev;

    always @(posedge sys_clk) begin
        if (!rst_n)
            pclk_prev <= 1'b0;
        else
            pclk_prev <= pclk;
    end

    // State machine
    localparam S_IDLE    = 2'd0;
    localparam S_CAPTURE = 2'd1;

    reg [1:0] state;
    reg       byte_toggle;     // 0=MSB, 1=LSB
    reg [7:0] msb_byte;
    reg       vsync_prev;

    always @(posedge sys_clk) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            write_addr   <= 0;
            write_enable <= 1'b0;
            pixel_data   <= 16'd0;
            byte_toggle  <= 1'b0;
            msb_byte     <= 8'd0;
            frame_done   <= 1'b0;
            vsync_prev   <= 1'b0;
        end else begin
            vsync_prev   <= vsync;
            write_enable <= 1'b0;
            frame_done   <= 1'b0;

            case (state)
                S_IDLE: begin
                    // Frame starts on VSYNC falling edge
                    if (vsync_prev && !vsync) begin
                        state      <= S_CAPTURE;
                        write_addr <= 0;
                        byte_toggle <= 1'b0;
                    end
                end

                S_CAPTURE: begin
                    // Frame done on VSYNC rising edge
                    if (!vsync_prev && vsync) begin
                        state      <= S_IDLE;
                        frame_done <= 1'b1;
                    end
                    // Reset byte alignment when HREF is low
                    else if (!href) begin
                        byte_toggle <= 1'b0;
                    end
                    // Capture data on pclk rising edge during HREF
                    else if (href && pclk_rising) begin
                        if (!byte_toggle) begin
                            // First byte (MSB)
                            msb_byte    <= data;
                            byte_toggle <= 1'b1;
                        end else begin
                            // Second byte (LSB) - complete pixel
                            pixel_data   <= {msb_byte, data};
                            write_enable <= 1'b1;
                            write_addr   <= write_addr + 1;
                            byte_toggle  <= 1'b0;
                        end
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
