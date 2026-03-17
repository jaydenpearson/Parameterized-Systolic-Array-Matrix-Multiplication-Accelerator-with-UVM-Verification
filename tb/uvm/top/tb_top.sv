`timescale 1ns/1ps

// import UVM package and all UVM components
import uvm_pkg::*;
`include "uvm_macros.svh"

// import all UVM TB files
`include "mm_if.sv"
`include "mm_uvm_pkg.sv"
import mm_uvm_pkg::*;

module tb_top;

    // ----------------------------------------------------------------
    // Parameters
    // ----------------------------------------------------------------
    localparam N           = 4;
    localparam DATA_WIDTH  = 8;
    localparam ACCUM_WIDTH = 32;
    localparam CLK_PERIOD  = 10; // 100MHz

    // ----------------------------------------------------------------
    // Clock and reset generation
    // ----------------------------------------------------------------
    logic clk;
    logic rst_n;

    // clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // reset generation — hold reset for 10 cycles then release
    initial begin
        rst_n = 0;
        repeat(10) @(posedge clk);
        @(posedge clk);
        rst_n = 1;
    end

    // ----------------------------------------------------------------
    // Interface instantiation
    // clk and rst_n are ports of the interface
    // ----------------------------------------------------------------
    mm_if #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut_if (
        .clk  (clk),
        .rst_n(rst_n)
    );

    // ----------------------------------------------------------------
    // DUT instantiation
    // all signals connected through the interface
    // ----------------------------------------------------------------
    mm_accelerator_top #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) u_dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (dut_if.start),
        .a_in             (dut_if.a_in),
        .b_in             (dut_if.b_in),
        .valid_in_upstream(dut_if.valid_in_upstream),
        .ready            (dut_if.ready),
        .result_valid     (dut_if.result_valid),
        .result           (dut_if.result)
    );

    // ----------------------------------------------------------------
    // UVM configuration and startup
    // ----------------------------------------------------------------
    initial begin
        // waveform capture
        $shm_open("uvm_waves.shm");
        $shm_probe(tb_top, "AS");

        // put virtual interface into config_db
        // driver and monitor retrieve this in their build_phase
        // path "" means available to all components from uvm_root down
        uvm_config_db #(virtual mm_if #(
            .N          (N),
            .DATA_WIDTH (DATA_WIDTH),
            .ACCUM_WIDTH(ACCUM_WIDTH)
        ))::set(null, "uvm_test_top.*", "mm_vif", dut_if);

        // hand control to UVM
        // test name selected via +UVM_TESTNAME on command line
        run_test();
    end

    // ----------------------------------------------------------------
    // Timeout watchdog
    // kills simulation if it runs too long — catches hung tests
    // ----------------------------------------------------------------
    initial begin
        #(CLK_PERIOD * 100000);
        `uvm_fatal("TIMEOUT",
            "Simulation exceeded maximum cycle count - possible hang")
    end

endmodule
