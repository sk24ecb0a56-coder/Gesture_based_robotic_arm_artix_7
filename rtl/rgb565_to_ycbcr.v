// rgb565_to_ycbcr.v
// RGB565 to YCbCr color space conversion
// ITU-R BT.601 standard with fixed-point arithmetic
// 2-stage pipeline for timing closure

module rgb565_to_ycbcr (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] rgb565,         // RGB565 input
    input  wire        valid_in,
    output reg  [7:0]  y_out,
    output reg  [7:0]  cb_out,
    output reg  [7:0]  cr_out,
    output reg         valid_out
);

    // Extract RGB components from RGB565
    wire [4:0] r5 = rgb565[15:11];
    wire [5:0] g6 = rgb565[10:5];
    wire [4:0] b5 = rgb565[4:0];

    // Expand to 8-bit with MSB replication
    wire [7:0] r8 = {r5, r5[4:2]};
    wire [7:0] g8 = {g6, g6[5:4]};
    wire [7:0] b8 = {b5, b5[4:2]};

    // Stage 1: Multiply and accumulate
    reg [15:0] y_temp, cb_temp, cr_temp;
    reg        valid_s1;

    // ITU-R BT.601 coefficients scaled by 256:
    // Y  =  66*R + 129*G +  25*B + 4096
    // Cb = -38*R -  74*G + 112*B + 32768
    // Cr = 112*R -  94*G -  18*B + 32768

    always @(posedge clk) begin
        if (!rst_n) begin
            y_temp   <= 0;
            cb_temp  <= 0;
            cr_temp  <= 0;
            valid_s1 <= 0;
        end else begin
            valid_s1 <= valid_in;
            
            if (valid_in) begin
                // Y calculation
                y_temp <= (66 * r8) + (129 * g8) + (25 * b8) + 4096;
                
                // Cb calculation (use signed arithmetic internally)
                cb_temp <= 32768 + (112 * b8) - (38 * r8) - (74 * g8);
                
                // Cr calculation
                cr_temp <= 32768 + (112 * r8) - (94 * g8) - (18 * b8);
            end
        end
    end

    // Stage 2: Shift and saturate
    always @(posedge clk) begin
        if (!rst_n) begin
            y_out     <= 0;
            cb_out    <= 0;
            cr_out    <= 0;
            valid_out <= 0;
        end else begin
            valid_out <= valid_s1;
            
            if (valid_s1) begin
                // Shift by 8 bits and clamp to valid ranges
                // Y: [16, 235]
                if (y_temp[15:8] < 16)
                    y_out <= 8'd16;
                else if (y_temp[15:8] > 235)
                    y_out <= 8'd235;
                else
                    y_out <= y_temp[15:8];
                
                // Cb: [16, 240]
                if (cb_temp[15:8] < 16)
                    cb_out <= 8'd16;
                else if (cb_temp[15:8] > 240)
                    cb_out <= 8'd240;
                else
                    cb_out <= cb_temp[15:8];
                
                // Cr: [16, 240]
                if (cr_temp[15:8] < 16)
                    cr_out <= 8'd16;
                else if (cr_temp[15:8] > 240)
                    cr_out <= 8'd240;
                else
                    cr_out <= cr_temp[15:8];
            end
        end
    end

endmodule
