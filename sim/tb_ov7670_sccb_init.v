// tb_ov7670_sccb_init.v
// Testbench for the OV7670 SCCB initialization controller
// Checks that init_done goes high after all 17 registers are written

`timescale 1ns / 1ps

module tb_ov7670_sccb_init;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg  clk;
    reg  rst_n;
    wire sioc;
    wire siod;
    wire init_done;

    // -----------------------------------------------------------------------
    // Instantiate DUT
    // -----------------------------------------------------------------------
    ov7670_sccb_init dut (
        .clk(clk),
        .rst_n(rst_n),
        .sioc(sioc),
        .siod(siod),
        .init_done(init_done)
    );

    // -----------------------------------------------------------------------
    // Clock generation: 100 MHz
    // -----------------------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns period
    end

    // -----------------------------------------------------------------------
    // VCD dump
    // -----------------------------------------------------------------------
    initial begin
        $dumpfile("tb_ov7670_sccb_init.vcd");
        $dumpvars(0, tb_ov7670_sccb_init);
    end

    // -----------------------------------------------------------------------
    // SIOD transition monitor
    // -----------------------------------------------------------------------
    integer sioc_edges;
    integer siod_edges;

    initial begin
        sioc_edges = 0;
        siod_edges = 0;
    end

    always @(posedge sioc or negedge sioc) sioc_edges = sioc_edges + 1;
    always @(posedge siod or negedge siod) siod_edges = siod_edges + 1;

    // -----------------------------------------------------------------------
    // Test sequence
    // -----------------------------------------------------------------------
    initial begin
        $display("tb_ov7670_sccb_init: starting simulation");

        // Apply reset
        rst_n = 0;
        #200;
        rst_n = 1;
        $display("Reset released at time %t", $time);

        // Wait for init_done.
        // Worst-case timing estimate:
        //   Initial delay  : 100,000 cycles
        //   Soft-reset write + 1 ms post-delay: ~130,000 cycles
        //   Remaining 16 writes @ ~30,000 cycles each + 5,000 delay: ~560,000 cycles
        //   Total          : ~790,000 cycles = ~7.9 ms at 100 MHz
        // Use 15 ms (15,000,000 ns) timeout for margin.
        fork
            begin : wait_done
                @(posedge init_done);
                $display("init_done asserted at time %t", $time);
                $display("SIOC edges observed: %0d", sioc_edges);
                $display("SIOD edges observed: %0d", siod_edges);
                disable timeout_check;
            end
            begin : timeout_check
                #15_000_000;
                $display("TIMEOUT: init_done never asserted");
                $finish;
            end
        join

        // Verify init_done stays high
        #1000;
        if (init_done !== 1'b1) begin
            $display("FAIL: init_done de-asserted unexpectedly");
            $finish;
        end

        // Verify sioc stays idle-high after done
        if (sioc !== 1'b1) begin
            $display("FAIL: sioc not idle-high after init_done");
            $finish;
        end

        $display("PASS: OV7670 SCCB initialization completed successfully");
        $display("tb_ov7670_sccb_init: simulation finished");
        $finish;
    end

endmodule
