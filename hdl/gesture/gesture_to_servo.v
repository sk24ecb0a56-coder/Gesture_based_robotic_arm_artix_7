// Gesture to Servo Mapper
// Maps detected gestures to servo positions for robotic arm control

module gesture_to_servo #(
    parameter NUM_GESTURES = 6  // 0-5 fingers
)(
    input wire clk,
    input wire rst_n,
    
    // Gesture input
    input wire [3:0] finger_count,
    input wire gesture_valid,
    input wire [7:0] gesture_id,
    
    // Servo angle outputs (0-180 degrees)
    output reg [7:0] servo0_angle,  // Base rotation
    output reg [7:0] servo1_angle,  // Shoulder
    output reg [7:0] servo2_angle,  // Elbow
    output reg [7:0] servo3_angle   // Gripper
);

    // Pre-defined servo positions for each gesture
    // These can be calibrated based on actual robotic arm
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            servo0_angle <= 8'd90;  // Default center position
            servo1_angle <= 8'd90;
            servo2_angle <= 8'd90;
            servo3_angle <= 8'd90;
        end else if (gesture_valid) begin
            case (finger_count)
                4'd0: begin  // No hand / Fist - Rest position
                    servo0_angle <= 8'd90;   // Base: center
                    servo1_angle <= 8'd45;   // Shoulder: down
                    servo2_angle <= 8'd45;   // Elbow: down
                    servo3_angle <= 8'd180;  // Gripper: closed
                end
                
                4'd1: begin  // 1 finger - Position 1
                    servo0_angle <= 8'd45;   // Base: left
                    servo1_angle <= 8'd90;   // Shoulder: middle
                    servo2_angle <= 8'd90;   // Elbow: middle
                    servo3_angle <= 8'd90;   // Gripper: half-open
                end
                
                4'd2: begin  // 2 fingers - Position 2
                    servo0_angle <= 8'd90;   // Base: center
                    servo1_angle <= 8'd120;  // Shoulder: up
                    servo2_angle <= 8'd60;   // Elbow: extended
                    servo3_angle <= 8'd90;   // Gripper: half-open
                end
                
                4'd3: begin  // 3 fingers - Position 3
                    servo0_angle <= 8'd135;  // Base: right
                    servo1_angle <= 8'd90;   // Shoulder: middle
                    servo2_angle <= 8'd90;   // Elbow: middle
                    servo3_angle <= 8'd90;   // Gripper: half-open
                end
                
                4'd4: begin  // 4 fingers - Position 4
                    servo0_angle <= 8'd90;   // Base: center
                    servo1_angle <= 8'd135;  // Shoulder: high
                    servo2_angle <= 8'd45;   // Elbow: bent
                    servo3_angle <= 8'd45;   // Gripper: open
                end
                
                4'd5: begin  // 5 fingers / Open hand - Fully extended
                    servo0_angle <= 8'd90;   // Base: center
                    servo1_angle <= 8'd135;  // Shoulder: high
                    servo2_angle <= 8'd135;  // Elbow: extended
                    servo3_angle <= 8'd0;    // Gripper: fully open
                end
                
                default: begin  // Default position
                    servo0_angle <= 8'd90;
                    servo1_angle <= 8'd90;
                    servo2_angle <= 8'd90;
                    servo3_angle <= 8'd90;
                end
            endcase
        end
    end

endmodule
