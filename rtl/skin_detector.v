// skin_detector.v
// YCbCr range thresholding for skin detection
// Parameterized thresholds for tuning

module skin_detector #(
    parameter Y_MIN   = 80,
    parameter Y_MAX   = 235,
    parameter CB_MIN  = 85,
    parameter CB_MAX  = 135,
    parameter CR_MIN  = 135,
    parameter CR_MAX  = 180
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] y_in,
    input  wire [7:0] cb_in,
    input  wire [7:0] cr_in,
    input  wire       valid_in,
    output reg        skin_mask,
    output reg        valid_out
);

    // 1-clock pipeline for registered output
    always @(posedge clk) begin
        if (!rst_n) begin
            skin_mask  <= 1'b0;
            valid_out  <= 1'b0;
        end else begin
            valid_out <= valid_in;
            
            // Threshold all three channels simultaneously
            if (valid_in &&
                (y_in >= Y_MIN) && (y_in <= Y_MAX) &&
                (cb_in >= CB_MIN) && (cb_in <= CB_MAX) &&
                (cr_in >= CR_MIN) && (cr_in <= CR_MAX)) begin
                skin_mask <= 1'b1;
            end else begin
                skin_mask <= 1'b0;
            end
        end
    end

endmodule
