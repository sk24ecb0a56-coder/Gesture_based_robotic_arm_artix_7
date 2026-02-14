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

    // Phase 1: Accumulate histogram during frame
    integer i;
    always @(posedge clk) begin
        if (!rst_n || frame_done) begin
            for (i = 0; i < H_ACTIVE; i = i + 1) begin
                col_histogram[i] <= 10'd0;
            end
            col_index         <= 0;
            total_skin_pixels <= 0;
        end else if (pixel_valid) begin
            if (skin_pixel) begin
                col_histogram[col_index] <= col_histogram[col_index] + 1;
                total_skin_pixels        <= total_skin_pixels + 1;
            end
            
            // Advance column (wraps at H_ACTIVE)
            if (col_index == H_ACTIVE - 1)
                col_index <= 0;
            else
                col_index <= col_index + 1;
        end
    end

    // Phase 2: Scan histogram and count peaks
    localparam A_IDLE = 2'd0;
    localparam A_SCAN = 2'd1;
    localparam A_DONE = 2'd2;

    reg [1:0]  analyze_state;
    reg [9:0]  scan_col;
    reg [2:0]  peak_count;
    reg        prev_above_thresh;

    always @(posedge clk) begin
        if (!rst_n) begin
            analyze_state     <= A_IDLE;
            scan_col          <= 0;
            peak_count        <= 0;
            prev_above_thresh <= 1'b0;
            finger_count      <= 3'd0;
            count_valid       <= 1'b0;
            hand_detected     <= 1'b0;
        end else begin
            count_valid <= 1'b0;

            case (analyze_state)
                A_IDLE: begin
                    if (frame_done) begin
                        analyze_state     <= A_SCAN;
                        scan_col          <= 0;
                        peak_count        <= 0;
                        prev_above_thresh <= 1'b0;
                    end
                end

                A_SCAN: begin
                    if (scan_col < H_ACTIVE) begin
                        // Check if current column is above threshold
                        if (col_histogram[scan_col] >= COL_THRESH) begin
                            // Rising transition = new finger detected
                            if (!prev_above_thresh && peak_count < 5) begin
                                peak_count <= peak_count + 1;
                            end
                            prev_above_thresh <= 1'b1;
                        end else begin
                            prev_above_thresh <= 1'b0;
                        end
                        
                        scan_col <= scan_col + 1;
                    end else begin
                        analyze_state <= A_DONE;
                    end
                end

                A_DONE: begin
                    // Check hand detection threshold
                    hand_detected <= (total_skin_pixels >= HAND_THRESH);
                    
                    // Output final count
                    finger_count <= peak_count;
                    count_valid  <= 1'b1;
                    
                    analyze_state <= A_IDLE;
                end

                default: analyze_state <= A_IDLE;
            endcase
        end
    end

endmodule
