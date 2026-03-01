// Frame Buffer Module
// Dual-port RAM to store one frame of image data
// Port A: Write from camera, Port B: Read for display/processing

module frame_buffer #(
    parameter IMG_WIDTH = 640,
    parameter IMG_HEIGHT = 480,
    parameter ADDR_WIDTH = 19,  // log2(640*480) = 18.23, use 19
    parameter DATA_WIDTH = 8
)(
    // Port A: Write interface (from camera)
    input wire clk_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] data_in_a,
    
    // Port B: Read interface (for display/processing)
    input wire clk_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    output reg [DATA_WIDTH-1:0] data_out_b
);

    // Frame buffer memory
    // For 640x480 = 307,200 pixels x 8 bits = 2.4 Mbit
    reg [DATA_WIDTH-1:0] mem [0:IMG_WIDTH*IMG_HEIGHT-1];
    
    // Port A: Write
    always @(posedge clk_a) begin
        if (we_a) begin
            mem[addr_a] <= data_in_a;
        end
    end
    
    // Port B: Read
    always @(posedge clk_b) begin
        data_out_b <= mem[addr_b];
    end

endmodule
