// ----------------------------------------------------------------
// bind_assertions.sv
// Binds all assertion modules to their target RTL modules
// Include this file in your xrun command alongside the RTL
// ----------------------------------------------------------------

// ----------------------------------------------------------------
// Bind PE assertions to every PE instance in the systolic array
// The bind targets worklib.pe which means ALL instances of pe
// get the assertions automatically — all 16 PEs in a 4x4 array
// ----------------------------------------------------------------
bind pe pe_assertions #(
    .DATA_WIDTH  (DATA_WIDTH),
    .ACCUM_WIDTH (ACCUM_WIDTH)
) pe_assert_inst (
    .clk      (clk),
    .rst_n    (rst_n),
    .a_in     (a_in),
    .b_in     (b_in),
    .a_out    (a_out),
    .b_out    (b_out),
    .accum    (accum),
    .valid_in (valid_in),
    .valid_out(valid_out),
    .clear    (clear)
);

bind controller controller_assertions #(
    .N (N)
) ctrl_assert_inst (
    .clk              (clk),
    .rst_n            (rst_n),
    .start            (start),
    .valid_in_upstream(valid_in_upstream),
    .ready            (ready),
    .valid_in         (valid_in),
    .result_valid     (result_valid),
    .clear            (clear)
);
