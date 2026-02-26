// finger_counter.v
// Vertical projection histogram analysis with peak counting
// Detects finger protrusions in binary skin mask

module finger_counter #(
    parameter H_ACTIVE      = 640,
    parameter V_ACTIVE      = 480,
    parameter COL_THRESH    = 30,      // Min pixels per column to count
    parameter HAND_THRESH   = 2000     // Min total pixels for hand detection
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       skin_pixel,      // Binary skin mask input
    input  wire       pixel_valid,
    input  wire       frame_done,
    output reg  [2:0] finger_count,
    output reg        count_valid,     // Pulse when count ready
    output reg        hand_detected
);

    // Vertical projection histogram (count skin pixels per column)
    reg [9:0] col_histogram [0:H_ACTIVE-1];
    reg [9:0] col_index;
    reg [18:0] total_skin_pixels;

    // State machine states
    localparam HIST_CLEAR = 2'd0;  // Sequential histogram clear
    localparam HIST_ACCUM = 2'd1;  // Accumulate histogram
    localparam HIST_SCAN  = 2'd2;  // Scan histogram for peaks
    localparam HIST_DONE  = 2'd3;  // Output results

    reg [1:0]  hist_state;
    reg [9:0]  clear_counter;

    // Scan/peak detection registers
    reg [9:0]  scan_col;
    reg [2:0]  peak_count;
    reg        prev_above_thresh;

    always @(posedge clk) begin
        if (!rst_n) begin
            hist_state        <= HIST_CLEAR;
            clear_counter     <= 0;
            col_index         <= 0;
            total_skin_pixels <= 0;
            scan_col          <= 0;
            peak_count        <= 0;
            prev_above_thresh <= 1'b0;
            finger_count      <= 3'd0;
            count_valid       <= 1'b0;
            hand_detected     <= 1'b0;
        end else begin
            count_valid <= 1'b0;

            case (hist_state)
                HIST_CLEAR: begin
                    // Clear one histogram entry per clock cycle
                    col_histogram[clear_counter] <= 10'd0;
                    if (clear_counter == H_ACTIVE - 1) begin
                        clear_counter     <= 0;
                        col_index         <= 0;
                        total_skin_pixels <= 0;
                        hist_state        <= HIST_ACCUM;
                    end else begin
                        clear_counter <= clear_counter + 1;
                    end
                end

                HIST_ACCUM: begin
                    if (frame_done) begin
                        scan_col          <= 0;
                        peak_count        <= 0;
                        prev_above_thresh <= 1'b0;
                        hist_state        <= HIST_SCAN;
                    end else if (pixel_valid) begin
                        if (skin_pixel) begin
                            col_histogram[col_index] <= col_histogram[col_index] + 1;
                            total_skin_pixels        <= total_skin_pixels + 1;
                        end

                        if (col_index == H_ACTIVE - 1)
                            col_index <= 0;
                        else
                            col_index <= col_index + 1;
                    end
                end

                HIST_SCAN: begin
                    if (scan_col < H_ACTIVE) begin
                        if (col_histogram[scan_col] >= COL_THRESH) begin
                            if (!prev_above_thresh && peak_count < 5)
                                peak_count <= peak_count + 1;
                            prev_above_thresh <= 1'b1;
                        end else begin
                            prev_above_thresh <= 1'b0;
                        end
                        scan_col <= scan_col + 1;
                    end else begin
                        hist_state <= HIST_DONE;
                    end
                end

                HIST_DONE: begin
                    hand_detected <= (total_skin_pixels >= HAND_THRESH);
                    finger_count  <= peak_count;
                    count_valid   <= 1'b1;
                    clear_counter <= 0;
                    hist_state    <= HIST_CLEAR;
                end

                default: hist_state <= HIST_CLEAR;
            endcase
        end
    end

endmodule
