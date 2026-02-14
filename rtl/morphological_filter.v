// morphological_filter.v
// 3x3 erosion using line buffers
// Removes small noise in binary skin mask

module morphological_filter #(
    parameter H_ACTIVE = 640,
    parameter V_ACTIVE = 480
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       pixel_in,        // Input binary mask
    input  wire       valid_in,
    input  wire       frame_done,
    output reg        pixel_out,       // Eroded output
    output reg        valid_out
);

    // Line buffers (2 lines of 640 pixels each)
    reg [H_ACTIVE-1:0] line_buf_0;
    reg [H_ACTIVE-1:0] line_buf_1;

    // 3-pixel shift registers for each row
    reg [2:0] row_0_sr, row_1_sr, row_2_sr;

    // Position counters
    reg [9:0] col_count;
    reg [9:0] row_count;

    // Column counter
    always @(posedge clk) begin
        if (!rst_n || frame_done) begin
            col_count <= 0;
        end else if (valid_in) begin
            if (col_count == H_ACTIVE - 1) begin
                col_count <= 0;
            end else begin
                col_count <= col_count + 1;
            end
        end
    end

    // Row counter
    always @(posedge clk) begin
        if (!rst_n || frame_done) begin
            row_count <= 0;
        end else if (valid_in && col_count == H_ACTIVE - 1) begin
            row_count <= row_count + 1;
        end
    end

    // Line buffer management and shift register loading
    always @(posedge clk) begin
        if (!rst_n) begin
            line_buf_0 <= 0;
            line_buf_1 <= 0;
            row_0_sr   <= 3'd0;
            row_1_sr   <= 3'd0;
            row_2_sr   <= 3'd0;
        end else if (frame_done) begin
            line_buf_0 <= 0;
            line_buf_1 <= 0;
            row_0_sr   <= 3'd0;
            row_1_sr   <= 3'd0;
            row_2_sr   <= 3'd0;
        end else if (valid_in) begin
            // Shift pixel into current row shift register
            row_2_sr <= {row_2_sr[1:0], pixel_in};
            
            // Shift from line buffers into previous rows
            row_1_sr <= {row_1_sr[1:0], line_buf_1[col_count]};
            row_0_sr <= {row_0_sr[1:0], line_buf_0[col_count]};
            
            // Update line buffers
            if (col_count == 0) begin
                // Reset shift registers at line boundary
                row_0_sr <= 3'd0;
                row_1_sr <= 3'd0;
                row_2_sr <= 3'd0;
            end
            
            // Store current pixel into line buffer
            line_buf_1[col_count] <= line_buf_0[col_count];
            line_buf_0[col_count] <= pixel_in;
        end
    end

    // 3x3 erosion operation
    wire [8:0] window = {row_0_sr, row_1_sr, row_2_sr};
    wire       eroded = &window;  // All 9 pixels must be 1

    // Output with valid flag
    // Only valid when we have sufficient context (row >= 2, col >= 2)
    always @(posedge clk) begin
        if (!rst_n) begin
            pixel_out <= 1'b0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in && (row_count >= 2) && (col_count >= 2);
            pixel_out <= eroded;
        end
    end

endmodule
