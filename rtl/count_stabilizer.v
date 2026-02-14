// count_stabilizer.v
// Temporal hysteresis filter - prevents jitter in finger count output
// Requires N consecutive frames with identical count before updating

module count_stabilizer #(
    parameter STABLE_FRAMES = 5
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] raw_count,       // Input finger count
    input  wire       count_valid,     // Pulse when new count available
    output reg  [2:0] stable_count     // Stabilized output count
);

    reg [2:0] prev_count;
    reg [$clog2(STABLE_FRAMES+1)-1:0] consistency_counter;

    always @(posedge clk) begin
        if (!rst_n) begin
            stable_count        <= 3'd0;
            prev_count          <= 3'd0;
            consistency_counter <= 0;
        end else begin
            if (count_valid) begin
                if (raw_count == prev_count) begin
                    // Same count as before - increment consistency
                    if (consistency_counter < STABLE_FRAMES) begin
                        consistency_counter <= consistency_counter + 1;
                    end
                    
                    // Update stable output when threshold reached
                    if (consistency_counter == STABLE_FRAMES - 1) begin
                        stable_count <= raw_count;
                    end
                end else begin
                    // Count changed - reset consistency counter
                    prev_count          <= raw_count;
                    consistency_counter <= 0;
                end
            end
        end
    end

endmodule
