// vga_controller.v
// Standard 640x480 @60Hz VGA timing generator
// Generates sync signals and pixel coordinates

module vga_controller #(
    parameter H_ACTIVE = 640,
    parameter H_FP     = 16,
    parameter H_SYNC   = 96,
    parameter H_BP     = 48,
    parameter V_ACTIVE = 480,
    parameter V_FP     = 10,
    parameter V_SYNC   = 2,
    parameter V_BP     = 33
)(
    input  wire        clk_25mhz,      // 25 MHz pixel clock
    input  wire        rst_n,
    output reg         hsync,
    output reg         vsync,
    output wire        active,
    output wire [9:0]  x_pos,
    output wire [9:0]  y_pos,
    output wire [18:0] read_addr       // Frame buffer read address
);

    localparam H_TOTAL = H_ACTIVE + H_FP + H_SYNC + H_BP;  // 800
    localparam V_TOTAL = V_ACTIVE + V_FP + V_SYNC + V_BP;  // 525

    reg [9:0] h_counter;
    reg [9:0] v_counter;

    // Horizontal and vertical counters
    always @(posedge clk_25mhz) begin
        if (!rst_n) begin
            h_counter <= 0;
            v_counter <= 0;
        end else begin
            if (h_counter == H_TOTAL - 1) begin
                h_counter <= 0;
                if (v_counter == V_TOTAL - 1) begin
                    v_counter <= 0;
                end else begin
                    v_counter <= v_counter + 1;
                end
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end

    // Sync signal generation (active-low)
    always @(posedge clk_25mhz) begin
        if (!rst_n) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else begin
            hsync <= ~((h_counter >= (H_ACTIVE + H_FP)) && 
                      (h_counter < (H_ACTIVE + H_FP + H_SYNC)));
            vsync <= ~((v_counter >= (V_ACTIVE + V_FP)) && 
                      (v_counter < (V_ACTIVE + V_FP + V_SYNC)));
        end
    end

    // Active display region
    assign active = (h_counter < H_ACTIVE) && (v_counter < V_ACTIVE);

    // Current pixel position (valid when active=1)
    assign x_pos = h_counter;
    assign y_pos = v_counter;

    // Frame buffer read address (row * width + col)
    assign read_addr = (v_counter * H_ACTIVE) + h_counter;

endmodule
