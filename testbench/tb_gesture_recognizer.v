// Testbench for Gesture Recognizer Module
`timescale 1ns / 1ps

module tb_gesture_recognizer;

    // Parameters
    parameter IMG_WIDTH = 640;
    parameter IMG_HEIGHT = 480;
    parameter CLK_PERIOD = 10;  // 100 MHz
    
    // Testbench signals
    reg clk;
    reg rst_n;
    reg [7:0] pixel_data;
    reg pixel_valid;
    reg frame_start;
    reg frame_end;
    reg [15:0] pixel_x;
    reg [15:0] pixel_y;
    
    wire [3:0] finger_count;
    wire gesture_valid;
    wire [7:0] gesture_id;
    
    // Instantiate the gesture recognizer
    gesture_recognizer #(
        .IMG_WIDTH(IMG_WIDTH),
        .IMG_HEIGHT(IMG_HEIGHT),
        .THRESHOLD(8'd128)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .pixel_data(pixel_data),
        .pixel_valid(pixel_valid),
        .frame_start(frame_start),
        .frame_end(frame_end),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .finger_count(finger_count),
        .gesture_valid(gesture_valid),
        .gesture_id(gesture_id)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize signals
        rst_n = 0;
        pixel_data = 0;
        pixel_valid = 0;
        frame_start = 0;
        frame_end = 0;
        pixel_x = 0;
        pixel_y = 0;
        
        // Reset
        #(CLK_PERIOD*10);
        rst_n = 1;
        #(CLK_PERIOD*10);
        
        // Test Case 1: Simulate 1 finger (low white pixel count)
        $display("Test Case 1: 1 Finger Gesture");
        simulate_frame(10000);  // 10k white pixels
        #(CLK_PERIOD*100);
        
        // Test Case 2: Simulate 3 fingers (medium white pixel count)
        $display("Test Case 2: 3 Finger Gesture");
        simulate_frame(30000);  // 30k white pixels
        #(CLK_PERIOD*100);
        
        // Test Case 3: Simulate 5 fingers (high white pixel count)
        $display("Test Case 3: 5 Finger Gesture (Open Hand)");
        simulate_frame(50000);  // 50k white pixels
        #(CLK_PERIOD*100);
        
        // Test Case 4: No hand detected
        $display("Test Case 4: No Hand Detected");
        simulate_frame(2000);   // Very low white pixels
        #(CLK_PERIOD*100);
        
        $display("All test cases completed");
        $finish;
    end
    
    // Task to simulate a frame with specific white pixel count
    task simulate_frame;
        input integer white_count;
        integer i, total_pixels;
        begin
            total_pixels = IMG_WIDTH * IMG_HEIGHT;
            
            // Start frame
            frame_start = 1;
            #(CLK_PERIOD);
            frame_start = 0;
            
            // Send pixels
            for (i = 0; i < total_pixels; i = i + 1) begin
                pixel_x = i % IMG_WIDTH;
                pixel_y = i / IMG_WIDTH;
                
                // Make some pixels white based on white_count
                if (i < white_count)
                    pixel_data = 8'd255;  // White pixel
                else
                    pixel_data = 8'd0;    // Black pixel
                
                pixel_valid = 1;
                #(CLK_PERIOD);
                pixel_valid = 0;
                
                // Add occasional gaps to simulate realistic timing
                if (i % 100 == 0)
                    #(CLK_PERIOD*2);
            end
            
            // End frame
            frame_end = 1;
            #(CLK_PERIOD);
            frame_end = 0;
            
            // Wait for gesture recognition
            wait(gesture_valid);
            #(CLK_PERIOD);
            $display("Detected: %d fingers, Gesture ID: %d", finger_count, gesture_id);
        end
    endtask
    
    // Monitor changes
    initial begin
        $monitor("Time=%0t | finger_count=%d | gesture_valid=%b | gesture_id=%d", 
                 $time, finger_count, gesture_valid, gesture_id);
    end
    
    // Dump waveforms
    initial begin
        $dumpfile("gesture_recognizer.vcd");
        $dumpvars(0, tb_gesture_recognizer);
    end

endmodule
