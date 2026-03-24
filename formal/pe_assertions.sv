module pe_assertions #(
    parameter DATA_WIDTH  = 8,
    parameter ACCUM_WIDTH = 32
)(
    input logic                   clk,
    input logic                   rst_n,
    input logic [DATA_WIDTH-1:0]  a_in,
    input logic [DATA_WIDTH-1:0]  b_in,
    input logic [DATA_WIDTH-1:0]  a_out,
    input logic [DATA_WIDTH-1:0]  b_out,
    input logic [ACCUM_WIDTH-1:0] accum,
    input logic                   valid_in,
    input logic                   valid_out,
    input logic                   clear
);

    // ----------------------------------------------------------------
    // Helper signals — capture previous cycle values for comparison
    // ----------------------------------------------------------------
    logic [DATA_WIDTH-1:0]  a_in_d;
    logic [DATA_WIDTH-1:0]  b_in_d;
    logic [ACCUM_WIDTH-1:0] accum_d;
    logic                   valid_in_d;
    logic                   clear_d;

    always_ff @(posedge clk) begin
        a_in_d    <= a_in;
        b_in_d    <= b_in;
        accum_d   <= accum;
        valid_in_d <= valid_in;
        clear_d   <= clear;
    end

    // ----------------------------------------------------------------
    // Assertion 1 — a_out is always a_in delayed by 1 cycle
    // pass-through register must always update regardless of valid
    // ----------------------------------------------------------------
    property p_a_passthrough;
        @(posedge clk) disable iff (!rst_n)
        ##1 a_out == $past(a_in);
    endproperty

    ast_a_passthrough: assert property (p_a_passthrough)
        else $error("PE: a_out mismatch — expected %0h got %0h",
                    $past(a_in), a_out);

    // ----------------------------------------------------------------
    // Assertion 2 — b_out is always b_in delayed by 1 cycle
    // ----------------------------------------------------------------
    property p_b_passthrough;
        @(posedge clk) disable iff (!rst_n)
        ##1 b_out == $past(b_in);
    endproperty

    ast_b_passthrough: assert property (p_b_passthrough)
        else $error("PE: b_out mismatch — expected %0h got %0h",
                    $past(b_in), b_out);

    // ----------------------------------------------------------------
    // Assertion 3 — valid_out is always valid_in delayed by 1 cycle
    // ----------------------------------------------------------------
    property p_valid_pipeline;
        @(posedge clk) disable iff (!rst_n)
        ##1 valid_out == $past(valid_in);
    endproperty

    ast_valid_pipeline: assert property (p_valid_pipeline)
        else $error("PE: valid_out mismatch — expected %0b got %0b",
                    $past(valid_in), valid_out);

    // ----------------------------------------------------------------
    // Assertion 4 — when valid_in is high and clear is low,
    // accum must increase by exactly a_in * b_in
    // ----------------------------------------------------------------
    property p_accum_update;
        @(posedge clk) disable iff (!rst_n)
        (valid_in && !clear) |=>
            accum == (accum_d + ACCUM_WIDTH'(a_in_d) * ACCUM_WIDTH'(b_in_d));
    endproperty

    ast_accum_update: assert property (p_accum_update)
        else $error("PE: accum incorrect — expected %0d got %0d",
                    accum_d + ACCUM_WIDTH'(a_in_d) * ACCUM_WIDTH'(b_in_d),
                    accum);

    // ----------------------------------------------------------------
    // Assertion 5 — when valid_in is low and clear is low,
    // accum must hold its value
    // ----------------------------------------------------------------
    property p_accum_hold;
        @(posedge clk) disable iff (!rst_n)
        (!valid_in && !clear) |=> accum == accum_d;
    endproperty

    ast_accum_hold: assert property (p_accum_hold)
        else $error("PE: accum changed when valid_in=0 — was %0d now %0d",
                    accum_d, accum);

    // ----------------------------------------------------------------
    // Assertion 6 — when clear is high, accum must be zero next cycle
    // ----------------------------------------------------------------
    property p_clear;
        @(posedge clk) disable iff (!rst_n)
        clear |=> accum == '0;
    endproperty

    ast_clear: assert property (p_clear)
        else $error("PE: accum not cleared — expected 0 got %0d", accum);

    // ----------------------------------------------------------------
    // Assertion 7 — valid_out must never be X or Z during normal operation
    // ----------------------------------------------------------------
    property p_valid_out_no_x;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(valid_out);
    endproperty

    ast_valid_out_no_x: assert property (p_valid_out_no_x)
        else $error("PE: valid_out is X or Z");

    // ----------------------------------------------------------------
    // Cover properties — confirm these scenarios actually happen
    // tools use these to verify assertions are reachable
    // ----------------------------------------------------------------
    cov_valid_in_high:  cover property (@(posedge clk) valid_in);
    cov_clear_high:     cover property (@(posedge clk) clear);
    cov_accum_nonzero:  cover property (@(posedge clk) accum != '0);
    cov_back_to_back:   cover property (@(posedge clk) valid_in ##1 valid_in);

endmodule
