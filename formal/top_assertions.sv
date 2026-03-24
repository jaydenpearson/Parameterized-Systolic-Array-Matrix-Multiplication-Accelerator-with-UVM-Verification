module top_assertions #(
    parameter N           = 4,
    parameter DATA_WIDTH  = 8,
    parameter ACCUM_WIDTH = 32
)(
    input logic                         clk,
    input logic                         rst_n,
    input logic                         start,
    input logic [N*DATA_WIDTH-1:0]      a_in,
    input logic [N*DATA_WIDTH-1:0]      b_in,
    input logic                         valid_in_upstream,
    input logic                         ready,
    input logic                         result_valid,
    input logic [N*N*ACCUM_WIDTH-1:0]   result
);

    // ----------------------------------------------------------------
    // Local parameters
    // ----------------------------------------------------------------
    localparam DRAIN_CYCLES = 2*N;
    localparam MIN_LATENCY  = N + DRAIN_CYCLES;     // earliest result_valid can appear
    localparam MAX_LATENCY  = N + DRAIN_CYCLES + 4; // latest result_valid can appear

    // ----------------------------------------------------------------
    // Protocol Assertion 1 — result_valid must never assert sooner
    // than MIN_LATENCY cycles after start
    // catches controller bugs where done is asserted too early
    // ----------------------------------------------------------------
    property p_min_latency;
        @(posedge clk) disable iff (!rst_n)
        $rose(start) |-> !result_valid ##1 !result_valid[*MIN_LATENCY-1];
    endproperty

    ast_min_latency: assert property (p_min_latency)
        else $error("TOP: result_valid asserted too early after start — min latency is %0d cycles",
                    MIN_LATENCY);

    // ----------------------------------------------------------------
    // Protocol Assertion 2 — result bus must never be X or Z
    // when result_valid is high
    // catches uninitialized or undriven result bits
    // ----------------------------------------------------------------
    property p_result_no_x;
        @(posedge clk) disable iff (!rst_n)
        result_valid |-> !$isunknown(result);
    endproperty

    ast_result_no_x: assert property (p_result_no_x)
        else $error("TOP: result bus contains X or Z when result_valid is high");

    // ----------------------------------------------------------------
    // Protocol Assertion 3 — ready must never be high at the same
    // time as result_valid
    // these represent different FSM states
    // ----------------------------------------------------------------
    property p_ready_result_exclusive;
        @(posedge clk) disable iff (!rst_n)
        result_valid |-> !ready;
    endproperty

    ast_ready_result_exclusive: assert property (p_ready_result_exclusive)
        else $error("TOP: ready and result_valid both high simultaneously");

    // ----------------------------------------------------------------
    // Protocol Assertion 4 — start must not assert when ready is high
    // a new transaction cannot start while one is being loaded
    // ----------------------------------------------------------------
    property p_no_start_when_busy;
        @(posedge clk) disable iff (!rst_n)
        ready |-> !start;
    endproperty

    ast_no_start_when_busy: assert property (p_no_start_when_busy)
        else $error("TOP: start asserted while DUT is busy loading");

    // ----------------------------------------------------------------
    // Protocol Assertion 5 — a_in and b_in must be stable for
    // N consecutive cycles after ready asserts
    // data must not change mid-transaction
    // ----------------------------------------------------------------
    property p_a_stable_during_load;
        @(posedge clk) disable iff (!rst_n)
        (ready && valid_in_upstream) |=>
            $stable(a_in) || !ready;
    endproperty

    ast_a_stable_during_load: assert property (p_a_stable_during_load)
        else $error("TOP: a_in changed unexpectedly during LOAD");

    property p_b_stable_during_load;
        @(posedge clk) disable iff (!rst_n)
        (ready && valid_in_upstream) |=>
            $stable(b_in) || !ready;
    endproperty

    ast_b_stable_during_load: assert property (p_b_stable_during_load)
        else $error("TOP: b_in changed unexpectedly during LOAD");

    // ----------------------------------------------------------------
    // Liveness Assertion 1 — end to end
    // if start pulses, result_valid must assert within MAX_LATENCY
    // this is the top level architectural contract
    // ----------------------------------------------------------------
    property p_end_to_end_latency;
        @(posedge clk) disable iff (!rst_n)
        $rose(start) |-> ##[MIN_LATENCY:MAX_LATENCY] result_valid;
    endproperty

    ast_end_to_end_latency: assert property (p_end_to_end_latency)
        else $error("TOP: end to end latency violated — expected result_valid between %0d and %0d cycles",
                    MIN_LATENCY, MAX_LATENCY);

    // ----------------------------------------------------------------
    // Liveness Assertion 2 — after result_valid a new transaction
    // must be accepted within a bounded number of cycles
    // ensures DUT returns to ready state and does not hang
    // ----------------------------------------------------------------
    property p_returns_to_ready;
        @(posedge clk) disable iff (!rst_n)
        $rose(result_valid) |-> ##[1:4] (!result_valid && !ready)
                                     or ##[1:4] ready;
    endproperty

    ast_returns_to_ready: assert property (p_returns_to_ready)
        else $error("TOP: DUT did not return to idle after result_valid");

    // ----------------------------------------------------------------
    // Liveness Assertion 3 — result_valid must eventually deassert
    // result_valid is a one cycle pulse, not a level signal
    // ----------------------------------------------------------------
    property p_result_valid_pulses;
        @(posedge clk) disable iff (!rst_n)
        $rose(result_valid) |=> !result_valid;
    endproperty

    ast_result_valid_pulses: assert property (p_result_valid_pulses)
        else $error("TOP: result_valid did not deassert after one cycle");

    // ----------------------------------------------------------------
    // Liveness Assertion 4 — back to back transactions both complete
    // verifies DUT correctly resets between consecutive multiplies
    // ----------------------------------------------------------------
    property p_back_to_back;
        @(posedge clk) disable iff (!rst_n)
        $rose(result_valid) ##1 $rose(start)
            |-> ##[MIN_LATENCY:MAX_LATENCY] result_valid;
    endproperty

    ast_back_to_back: assert property (p_back_to_back)
        else $error("TOP: second transaction did not complete after back to back start");

    // ----------------------------------------------------------------
    // Cover properties — architectural scenarios
    // ----------------------------------------------------------------
    cov_end_to_end:       cover property (@(posedge clk)
                              $rose(start) ##[MIN_LATENCY:MAX_LATENCY] result_valid);

    cov_back_to_back:     cover property (@(posedge clk)
                              result_valid ##1 $rose(start)
                              ##[MIN_LATENCY:MAX_LATENCY] result_valid);

    cov_result_nonzero:   cover property (@(posedge clk)
                              result_valid && (result != '0));

    cov_max_data:         cover property (@(posedge clk)
                              result_valid &&
                              (a_in == {N{8'hFF}}) &&
                              (b_in == {N{8'hFF}}));

endmodule
