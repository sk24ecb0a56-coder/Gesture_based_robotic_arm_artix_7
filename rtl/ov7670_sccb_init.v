// ov7670_sccb_init.v
// SCCB (I2C-compatible) master controller for OV7670 camera initialization
// Configures the camera for RGB565 output on power-up

module ov7670_sccb_init (
    input  wire clk,        // 100 MHz system clock
    input  wire rst_n,      // Active-low reset
    output reg  sioc,       // SCCB clock output
    inout  wire siod,       // SCCB data (bidirectional)
    output reg  init_done   // High when all registers written
);

    // -----------------------------------------------------------------------
    // SIOD tristate
    // -----------------------------------------------------------------------
    reg siod_out;
    reg siod_oe;
    assign siod = siod_oe ? siod_out : 1'bz;

    // -----------------------------------------------------------------------
    // Clock divider: 100 MHz -> ~100 kHz (divide by 1000)
    // Each SCCB bit period = 1000 cycles; quarter-period = 250 cycles
    // -----------------------------------------------------------------------
    localparam CLK_DIV     = 250;  // quarter-period in sys-clk cycles

    // -----------------------------------------------------------------------
    // Post-reset delay: ~1 ms = 100,000 cycles
    // Inter-write delay: ~5,000 cycles
    // -----------------------------------------------------------------------
    localparam RESET_DELAY = 100_000;
    localparam WRITE_DELAY = 5_000;

    // OV7670 write address
    localparam DEV_ADDR    = 8'h42;

    // Number of registers to write
    localparam NUM_REGS    = 17;

    // Register table: {reg_addr, reg_data}
    reg [15:0] reg_table [0:NUM_REGS-1];

    initial begin
        reg_table[ 0] = 16'h1280;  // soft reset
        reg_table[ 1] = 16'h1204;  // RGB output enable
        reg_table[ 2] = 16'h40D0;  // RGB565 format
        reg_table[ 3] = 16'h1101;  // clock prescaler
        reg_table[ 4] = 16'h0C00;  // disable DCW
        reg_table[ 5] = 16'h3E00;  // no PCLK divider
        reg_table[ 6] = 16'h8C00;  // disable RGB444
        reg_table[ 7] = 16'h0400;  // no mirror/flip
        reg_table[ 8] = 16'h3A04;  // line sequence config
        reg_table[ 9] = 16'h1418;  // AGC ceiling 4x
        reg_table[10] = 16'h4F80;  // matrix coefficient 1
        reg_table[11] = 16'h5080;  // matrix coefficient 2
        reg_table[12] = 16'h5100;  // matrix coefficient 3
        reg_table[13] = 16'h5222;  // matrix coefficient 4
        reg_table[14] = 16'h535E;  // matrix coefficient 5
        reg_table[15] = 16'h5480;  // matrix coefficient 6
        reg_table[16] = 16'h1E37;  // mirror/flip config
    end

    // -----------------------------------------------------------------------
    // State machine
    // -----------------------------------------------------------------------
    localparam ST_IDLE  = 3'd0;
    localparam ST_DELAY = 3'd1;
    localparam ST_START = 3'd2;
    localparam ST_BITS  = 3'd3;
    localparam ST_ACK   = 3'd4;
    localparam ST_STOP  = 3'd5;
    localparam ST_DONE  = 3'd6;

    reg [2:0]  state;
    reg [2:0]  next_state_after_delay;

    // reg_idx: which register entry we are currently writing (0..16)
    reg [4:0]  reg_idx;

    // byte_idx: which byte within a register write (0=dev_addr, 1=reg_addr, 2=data)
    reg [1:0]  byte_idx;

    // bit_idx: which bit within the current byte (7 downto 0)
    reg [2:0]  bit_idx;

    // shift_reg: holds the byte being shifted out MSB first
    reg [7:0]  shift_reg;

    // phase: quarter-period sub-state (0..3); advances every qtr_tick
    reg [1:0]  phase;

    // clk_cnt: quarter-period divider (0..CLK_DIV-1)
    reg [7:0]  clk_cnt;

    // delay_cnt: general long-delay counter (up to RESET_DELAY)
    reg [16:0] delay_cnt;

    // Quarter-period tick
    wire qtr_tick = (clk_cnt == CLK_DIV - 1);

    // -----------------------------------------------------------------------
    // Quarter-period clock divider
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            clk_cnt <= 0;
        else if (clk_cnt == CLK_DIV - 1)
            clk_cnt <= 0;
        else
            clk_cnt <= clk_cnt + 1;
    end

    // -----------------------------------------------------------------------
    // Main FSM
    // -----------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state                  <= ST_IDLE;
            next_state_after_delay <= ST_IDLE;
            sioc                   <= 1'b1;
            siod_out               <= 1'b1;
            siod_oe                <= 1'b1;
            init_done              <= 1'b0;
            reg_idx                <= 0;
            byte_idx               <= 0;
            bit_idx                <= 7;
            shift_reg              <= 0;
            phase                  <= 0;
            delay_cnt              <= 0;
        end else begin
            case (state)

                // ---- Idle: hold bus high, then start 1 ms reset delay ----
                ST_IDLE: begin
                    sioc     <= 1'b1;
                    siod_out <= 1'b1;
                    siod_oe  <= 1'b1;
                    phase    <= 0;
                    // Begin initial 1 ms power-up delay
                    delay_cnt              <= RESET_DELAY - 1;
                    next_state_after_delay <= ST_START;
                    state                  <= ST_DELAY;
                end

                // ---- Generic cycle-count delay ----
                ST_DELAY: begin
                    if (delay_cnt == 0)
                        state <= next_state_after_delay;
                    else
                        delay_cnt <= delay_cnt - 1;
                end

                // ---- START condition ----
                // phase 0: SIOC=1, SIOD=1 (idle hold, one qtr-period)
                // phase 1: SIOC=1, SIOD=0 (SDA falls — START)
                // phase 2: SIOC=0, SIOD=0 (clock falls, ready for first bit)
                // phase 3: Load first byte (DEV_ADDR), move to ST_BITS
                ST_START: begin
                    if (qtr_tick) begin
                        phase <= phase + 1;
                        case (phase)
                            2'd0: begin sioc <= 1'b1; siod_out <= 1'b1; siod_oe <= 1'b1; end
                            2'd1: begin sioc <= 1'b1; siod_out <= 1'b0; siod_oe <= 1'b1; end
                            2'd2: begin sioc <= 1'b0; siod_out <= 1'b0; siod_oe <= 1'b1; end
                            2'd3: begin
                                // Load device address, reset byte/bit counters
                                byte_idx  <= 0;
                                bit_idx   <= 7;
                                shift_reg <= DEV_ADDR;
                                phase     <= 0;
                                state     <= ST_BITS;
                            end
                        endcase
                    end
                end

                // ---- Send one bit (8 bits per byte, 3 bytes per register write) ----
                // phase 0: SIOC=0, output current bit on SIOD
                // phase 1: SIOC=1 (rising edge — camera samples SIOD)
                // phase 2: SIOC=1 (hold)
                // phase 3: SIOC=0 (falling edge); advance bit or go to ACK
                ST_BITS: begin
                    if (qtr_tick) begin
                        phase <= phase + 1;
                        case (phase)
                            2'd0: begin
                                sioc     <= 1'b0;
                                siod_out <= shift_reg[7];
                                siod_oe  <= 1'b1;
                            end
                            2'd1: begin sioc <= 1'b1; end
                            2'd2: begin sioc <= 1'b1; end
                            2'd3: begin
                                sioc  <= 1'b0;
                                phase <= 0;
                                if (bit_idx == 0) begin
                                    // All 8 bits of this byte sent — go to ACK
                                    state <= ST_ACK;
                                end else begin
                                    bit_idx   <= bit_idx - 1;
                                    shift_reg <= {shift_reg[6:0], 1'b0};
                                end
                            end
                        endcase
                    end
                end

                // ---- ACK slot: release SIOD, pulse SIOC, then load next byte ----
                // phase 0: SIOC=0, release SIOD (input)
                // phase 1: SIOC=1
                // phase 2: SIOC=1
                // phase 3: SIOC=0; decide next action
                ST_ACK: begin
                    if (qtr_tick) begin
                        phase <= phase + 1;
                        case (phase)
                            2'd0: begin sioc <= 1'b0; siod_oe <= 1'b0; end
                            2'd1: begin sioc <= 1'b1; end
                            2'd2: begin sioc <= 1'b1; end
                            2'd3: begin
                                sioc    <= 1'b0;
                                siod_oe <= 1'b1;
                                siod_out<= 1'b0;
                                phase   <= 0;
                                bit_idx <= 7;
                                case (byte_idx)
                                    2'd0: begin
                                        // Device address sent; now send register address
                                        byte_idx  <= 1;
                                        shift_reg <= reg_table[reg_idx][15:8];
                                        state     <= ST_BITS;
                                    end
                                    2'd1: begin
                                        // Register address sent; now send data
                                        byte_idx  <= 2;
                                        shift_reg <= reg_table[reg_idx][7:0];
                                        state     <= ST_BITS;
                                    end
                                    default: begin
                                        // Data sent; send STOP
                                        state <= ST_STOP;
                                    end
                                endcase
                            end
                        endcase
                    end
                end

                // ---- STOP condition ----
                // phase 0: SIOC=0, SIOD=0
                // phase 1: SIOC=1, SIOD=0
                // phase 2: SIOC=1, SIOD=1 (SDA rises — STOP)
                // phase 3: advance reg_idx; schedule next write or finish
                ST_STOP: begin
                    if (qtr_tick) begin
                        phase <= phase + 1;
                        case (phase)
                            2'd0: begin sioc <= 1'b0; siod_out <= 1'b0; siod_oe <= 1'b1; end
                            2'd1: begin sioc <= 1'b1; siod_out <= 1'b0; end
                            2'd2: begin sioc <= 1'b1; siod_out <= 1'b1; end
                            2'd3: begin
                                phase <= 0;
                                if (reg_idx == NUM_REGS - 1) begin
                                    // All registers written
                                    state <= ST_DONE;
                                end else begin
                                    // Insert post-soft-reset delay after reg 0,
                                    // otherwise use the standard inter-write delay
                                    reg_idx   <= reg_idx + 1;
                                    byte_idx  <= 0;
                                    next_state_after_delay <= ST_START;
                                    if (reg_idx == 0) begin
                                        delay_cnt <= RESET_DELAY - 1;
                                    end else begin
                                        delay_cnt <= WRITE_DELAY - 1;
                                    end
                                    state <= ST_DELAY;
                                end
                            end
                        endcase
                    end
                end

                // ---- All registers written ----
                ST_DONE: begin
                    sioc      <= 1'b1;
                    siod_out  <= 1'b1;
                    siod_oe   <= 1'b1;
                    init_done <= 1'b1;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
