module controller_assertions #(
    parameter N = 4
)(
    input logic clk,
    input logic rst_n,
    input logic start,
    input logic valid_in_upstream,
    input logic ready,
    input logic valid_in,
    input logic result_valid,
    input logic clear
);

    // ----------------------------------------------------------------
    // Local parameters
    // ----------------------------------------------------------------
    localparam DRAIN_CYCLES  = 2*N;
    localparam MAX_LATENCY   = N + DRAIN_CYCLES + 4; // total cycles from start to result_valid

    // ----------------------------------------------------------------
    // Protocol Assertion 1 — ready should only be high in LOAD state
    // if ready is high, valid_in_upstream should be the only thing
    // that can cause a state change
    // ----------------------------------------------------------------
    property p_ready_only_when_load;
        @(posedge clk) disable iff (!rst_n)
        ready |-> !result_valid;
    endproperty

    ast_ready_not_with_result_valid: assert property (p_ready_only_when_load)
        else $error("CTRL: ready and result_valid both high simultaneously");

    // ----------------------------------------------------------------
    // Protocol Assertion 2 — result_valid and ready are mutually exclusive
    // they represent different FSM states and should never overlap
    // ----------------------------------------------------------------
    property p_result_valid_not_ready;
        @(posedge clk) disable iff (!rst_n)
        result_valid |-> !ready;
    endproperty

    ast_result_valid_not_ready: assert property (p_result_valid_not_ready)
        else $error("CTRL: result_valid and ready both high simultaneously");

    // ----------------------------------------------------------------
    // Protocol Assertion 3 — valid_in should only be high when ready is high
    // controller should not assert valid_in unless it is in LOAD state
    // ----------------------------------------------------------------
    property p_valid_in_requires_ready;
        @(posedge clk) disable iff (!rst_n)
        valid_in |-> ready;
    endproperty

    ast_valid_in_requires_ready: assert property (p_valid_in_requires_ready)
        else $error("CTRL: valid_in high but ready is low");

    // ----------------------------------------------------------------
    // Protocol Assertion 4 — result_valid should only pulse for one cycle
    // controller goes DONE -> IDLE in one cycle so result_valid
    // should never be high for two consecutive cycles
    // ----------------------------------------------------------------
    property p_result_valid_one_cycle;
        @(posedge clk) disable iff (!rst_n)
        result_valid |=> !result_valid;
    endproperty

    ast_result_valid_one_cycle: assert property (p_result_valid_one_cycle)
        else $error("CTRL: result_valid held high for more than one cycle");

    // ----------------------------------------------------------------
    // Protocol Assertion 5 — clear should only pulse for one cycle
    // controller asserts clear on IDLE->LOAD transition for one cycle
    // ----------------------------------------------------------------
    property p_clear_one_cycle;
        @(posedge clk) disable iff (!rst_n)
        clear |=> !clear;
    endproperty

    ast_clear_one_cycle: assert property (p_clear_one_cycle)
        else $error("CTRL: clear held high for more than one cycle");

    // ----------------------------------------------------------------
    // Protocol Assertion 6 — start should not assert while ready is high
    // starting a new computation while one is in progress is illegal
    // ----------------------------------------------------------------
    property p_no_start_during_load;
        @(posedge clk) disable iff (!rst_n)
        ready |-> !start;
    endproperty

    ast_no_start_during_load: assert property (p_no_start_during_load)
        else $error("CTRL: start asserted while controller is in LOAD state");

    // ----------------------------------------------------------------
    // Liveness Assertion 1 — if start pulses, result_valid must
    // assert within MAX_LATENCY cycles
    // this catches hang conditions where the FSM gets stuck
    // ----------------------------------------------------------------
    property p_start_leads_to_result;
        @(posedge clk) disable iff (!rst_n)
        $rose(start) |-> ##[1:MAX_LATENCY] result_valid;
    endproperty

    ast_start_leads_to_result: assert property (p_start_leads_to_result)
        else $error("CTRL: result_valid did not assert within %0d cycles of start",
                    MAX_LATENCY);

    // ----------------------------------------------------------------
    // Liveness Assertion 2 — ready must assert within a few cycles
    // of start being pulsed
    // ----------------------------------------------------------------
    property p_start_leads_to_ready;
        @(posedge clk) disable iff (!rst_n)
        $rose(start) |-> ##[1:4] ready;
    endproperty

    ast_start_leads_to_ready: assert property (p_start_leads_to_ready)
        else $error("CTRL: ready did not assert within 4 cycles of start");

    // ----------------------------------------------------------------
    // Liveness Assertion 3 — once ready asserts, result_valid must
    // eventually assert within DRAIN_CYCLES + N + 2 cycles
    // ----------------------------------------------------------------
    property p_ready_leads_to_result;
        @(posedge clk) disable iff (!rst_n)
        $rose(ready) |-> ##[N:DRAIN_CYCLES+N+2] result_valid;
    endproperty

    ast_ready_leads_to_result: assert property (p_ready_leads_to_result)
        else $error("CTRL: result_valid did not assert after ready");

    // ----------------------------------------------------------------
    // Liveness Assertion 4 — clear must assert exactly once per
    // computation — on the cycle after start is pulsed
    // ----------------------------------------------------------------
    property p_start_leads_to_clear;
        @(posedge clk) disable iff (!rst_n)
        $rose(start) |=> clear;
    endproperty

    ast_start_leads_to_clear: assert property (p_start_leads_to_clear)
        else $error("CTRL: clear did not assert the cycle after start");

    // ----------------------------------------------------------------
    // Cover properties — verify these scenarios are exercised
    // ----------------------------------------------------------------
    cov_start_pulse:       cover property (@(posedge clk) $rose(start));
    cov_result_valid:      cover property (@(posedge clk) $rose(result_valid));
    cov_ready_high:        cover property (@(posedge clk) ready);
    cov_back_to_back:      cover property (@(posedge clk)
                               result_valid ##1 $rose(start));
    cov_full_handshake:    cover property (@(posedge clk)
                               $rose(start) ##[1:MAX_LATENCY] result_valid);

endmodule
