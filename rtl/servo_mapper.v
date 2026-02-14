// servo_mapper.v
// Maps finger count to servo angles with smooth ramping
// Prevents sudden servo movements that could damage the arm

module servo_mapper #(
    parameter RAMP_PERIOD = 65536      // Cycles between angle increments
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] finger_count,
    input  wire       hand_detected,
    output reg  [7:0] angle_base,
    output reg  [7:0] angle_shoulder,
    output reg  [7:0] angle_elbow,
    output reg  [7:0] angle_gripper
);

    // Home position
    localparam HOME_BASE     = 128;
    localparam HOME_SHOULDER = 64;
    localparam HOME_ELBOW    = 64;
    localparam HOME_GRIPPER  = 128;

    // Target angles based on finger count
    reg [7:0] target_base, target_shoulder, target_elbow, target_gripper;

    always @(*) begin
        if (!hand_detected) begin
            // No hand detected - go to home position
            target_base     = HOME_BASE;
            target_shoulder = HOME_SHOULDER;
            target_elbow    = HOME_ELBOW;
            target_gripper  = HOME_GRIPPER;
        end else begin
            case (finger_count)
                3'd0: begin
                    target_base     = HOME_BASE;
                    target_shoulder = HOME_SHOULDER;
                    target_elbow    = HOME_ELBOW;
                    target_gripper  = HOME_GRIPPER;
                end
                3'd1: begin
                    target_base     = 192;  // Rotate right
                    target_shoulder = HOME_SHOULDER;
                    target_elbow    = HOME_ELBOW;
                    target_gripper  = HOME_GRIPPER;
                end
                3'd2: begin
                    target_base     = 192;
                    target_shoulder = 128;  // Lift
                    target_elbow    = HOME_ELBOW;
                    target_gripper  = HOME_GRIPPER;
                end
                3'd3: begin
                    target_base     = 192;
                    target_shoulder = 128;
                    target_elbow    = 160;  // Extend
                    target_gripper  = HOME_GRIPPER;
                end
                3'd4: begin
                    target_base     = 192;
                    target_shoulder = 128;
                    target_elbow    = 160;
                    target_gripper  = 200;  // Open
                end
                3'd5: begin
                    target_base     = 192;
                    target_shoulder = 128;
                    target_elbow    = 160;
                    target_gripper  = 50;   // Close/grab
                end
                default: begin
                    target_base     = HOME_BASE;
                    target_shoulder = HOME_SHOULDER;
                    target_elbow    = HOME_ELBOW;
                    target_gripper  = HOME_GRIPPER;
                end
            endcase
        end
    end

    // Ramp counter for smooth transitions
    reg [15:0] ramp_counter;

    always @(posedge clk) begin
        if (!rst_n) begin
            ramp_counter <= 0;
        end else begin
            ramp_counter <= ramp_counter + 1;
        end
    end

    // Smooth angle ramping (increment/decrement by 1 each period)
    wire ramp_tick = (ramp_counter == 0);

    always @(posedge clk) begin
        if (!rst_n) begin
            angle_base     <= HOME_BASE;
            angle_shoulder <= HOME_SHOULDER;
            angle_elbow    <= HOME_ELBOW;
            angle_gripper  <= HOME_GRIPPER;
        end else if (ramp_tick) begin
            // Base
            if (angle_base < target_base)
                angle_base <= angle_base + 1;
            else if (angle_base > target_base)
                angle_base <= angle_base - 1;
            
            // Shoulder
            if (angle_shoulder < target_shoulder)
                angle_shoulder <= angle_shoulder + 1;
            else if (angle_shoulder > target_shoulder)
                angle_shoulder <= angle_shoulder - 1;
            
            // Elbow
            if (angle_elbow < target_elbow)
                angle_elbow <= angle_elbow + 1;
            else if (angle_elbow > target_elbow)
                angle_elbow <= angle_elbow - 1;
            
            // Gripper
            if (angle_gripper < target_gripper)
                angle_gripper <= angle_gripper + 1;
            else if (angle_gripper > target_gripper)
                angle_gripper <= angle_gripper - 1;
        end
    end

endmodule
