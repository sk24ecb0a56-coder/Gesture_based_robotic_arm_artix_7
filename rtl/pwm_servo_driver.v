// pwm_servo_driver.v
// 4-channel servo PWM generator
// 50Hz period (20ms), 1-2ms pulse width control

module pwm_servo_driver #(
    parameter CLK_FREQ = 100_000_000,  // 100 MHz
    parameter PWM_FREQ = 50,           // 50 Hz
    parameter PWM_MIN  = 100_000,      // 1.0 ms in clock cycles
    parameter PWM_MAX  = 200_000       // 2.0 ms in clock cycles
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] angle_0,         // Base servo angle (0-255)
    input  wire [7:0] angle_1,         // Shoulder servo angle
    input  wire [7:0] angle_2,         // Elbow servo angle
    input  wire [7:0] angle_3,         // Gripper servo angle
    output reg        pwm_0,
    output reg        pwm_1,
    output reg        pwm_2,
    output reg        pwm_3
);

    localparam PERIOD = CLK_FREQ / PWM_FREQ;  // 2,000,000 cycles for 20ms

    reg [20:0] period_counter;
    reg [20:0] duty_0, duty_1, duty_2, duty_3;

    // Calculate duty cycle for each servo
    // PWM_MIN + (angle * (PWM_MAX - PWM_MIN) / 256)
    // Approximately: PWM_MIN + angle * 392
    always @(posedge clk) begin
        if (!rst_n) begin
            duty_0 <= PWM_MIN;
            duty_1 <= PWM_MIN;
            duty_2 <= PWM_MIN;
            duty_3 <= PWM_MIN;
        end else begin
            duty_0 <= PWM_MIN + (angle_0 * 392);
            duty_1 <= PWM_MIN + (angle_1 * 392);
            duty_2 <= PWM_MIN + (angle_2 * 392);
            duty_3 <= PWM_MIN + (angle_3 * 392);
        end
    end

    // Period counter (shared for all channels)
    always @(posedge clk) begin
        if (!rst_n) begin
            period_counter <= 0;
        end else begin
            if (period_counter == PERIOD - 1) begin
                period_counter <= 0;
            end else begin
                period_counter <= period_counter + 1;
            end
        end
    end

    // PWM output generation
    always @(posedge clk) begin
        if (!rst_n) begin
            pwm_0 <= 1'b0;
            pwm_1 <= 1'b0;
            pwm_2 <= 1'b0;
            pwm_3 <= 1'b0;
        end else begin
            pwm_0 <= (period_counter < duty_0);
            pwm_1 <= (period_counter < duty_1);
            pwm_2 <= (period_counter < duty_2);
            pwm_3 <= (period_counter < duty_3);
        end
    end

endmodule
