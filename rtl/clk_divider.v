// clk_divider.v
// Clock divider with parameterized division factor
// Generates clean 50% duty cycle output clock

module clk_divider #(
    parameter DIV_FACTOR = 4  // Default: 100MHz -> 25MHz
)(
    input  wire clk_in,       // Input clock
    input  wire rst_n,        // Active-low synchronous reset
    output reg  clk_out       // Divided output clock
);

    // Counter for clock division
    reg [$clog2(DIV_FACTOR)-1:0] counter;

    always @(posedge clk_in) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 1'b0;
        end else begin
            if (counter == (DIV_FACTOR/2 - 1)) begin
                counter <= 0;
                clk_out <= ~clk_out;
            end else begin
                counter <= counter + 1;
            end
        end
    end

endmodule
