// Test Pattern Generator
// Generates various test patterns for VGA display testing
// Use this module instead of camera for display verification

module test_pattern_generator #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480
)(
    input wire clk,
    input wire rst_n,
    input wire [1:0] pattern_select,  // 0-3: different patterns
    
    // Output to display (compatible with camera interface)
    output reg [7:0] pixel_data,
    output reg pixel_valid,
    output reg frame_start,
    output reg frame_end,
    output reg [15:0] pixel_x,
    output reg [15:0] pixel_y
);

    // State machine
    localparam IDLE = 2'd0;
    localparam SEND_FRAME_START = 2'd1;
    localparam SEND_PIXELS = 2'd2;
    localparam SEND_FRAME_END = 2'd3;
    
    reg [1:0] state;
    reg [31:0] frame_counter;
    
    // Pattern generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pixel_data <= 8'd0;
            pixel_valid <= 1'b0;
            frame_start <= 1'b0;
            frame_end <= 1'b0;
            pixel_x <= 16'd0;
            pixel_y <= 16'd0;
            frame_counter <= 32'd0;
        end else begin
            case (state)
                IDLE: begin
                    frame_start <= 1'b0;
                    frame_end <= 1'b0;
                    pixel_valid <= 1'b0;
                    
                    // Generate new frame periodically
                    if (frame_counter >= 32'd1000000) begin  // ~10ms at 100MHz
                        state <= SEND_FRAME_START;
                        frame_counter <= 32'd0;
                    end else begin
                        frame_counter <= frame_counter + 1;
                    end
                end
                
                SEND_FRAME_START: begin
                    frame_start <= 1'b1;
                    pixel_x <= 16'd0;
                    pixel_y <= 16'd0;
                    state <= SEND_PIXELS;
                end
                
                SEND_PIXELS: begin
                    frame_start <= 1'b0;
                    pixel_valid <= 1'b1;
                    
                    // Generate pattern based on selection
                    case (pattern_select)
                        2'd0: begin  // Vertical bars
                            if (pixel_x < 160)
                                pixel_data <= 8'd0;     // Black
                            else if (pixel_x < 320)
                                pixel_data <= 8'd85;    // Dark gray
                            else if (pixel_x < 480)
                                pixel_data <= 8'd170;   // Light gray
                            else
                                pixel_data <= 8'd255;   // White
                        end
                        
                        2'd1: begin  // Horizontal bars
                            if (pixel_y < 120)
                                pixel_data <= 8'd0;     // Black
                            else if (pixel_y < 240)
                                pixel_data <= 8'd85;    // Dark gray
                            else if (pixel_y < 360)
                                pixel_data <= 8'd170;   // Light gray
                            else
                                pixel_data <= 8'd255;   // White
                        end
                        
                        2'd2: begin  // Checkerboard
                            if (((pixel_x[5] ^ pixel_y[5]) == 1'b1))
                                pixel_data <= 8'd255;   // White
                            else
                                pixel_data <= 8'd0;     // Black
                        end
                        
                        2'd3: begin  // Gradient
                            // Horizontal gradient
                            pixel_data <= pixel_x[8:1];
                        end
                    endcase
                    
                    // Move to next pixel
                    if (pixel_x < IMG_WIDTH - 1) begin
                        pixel_x <= pixel_x + 1;
                    end else begin
                        pixel_x <= 16'd0;
                        if (pixel_y < IMG_HEIGHT - 1) begin
                            pixel_y <= pixel_y + 1;
                        end else begin
                            state <= SEND_FRAME_END;
                        end
                    end
                end
                
                SEND_FRAME_END: begin
                    pixel_valid <= 1'b0;
                    frame_end <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule
