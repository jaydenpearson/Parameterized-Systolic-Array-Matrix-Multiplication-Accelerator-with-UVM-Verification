class mm_seq_item extends uvm_sequence_item;

    // register this class with the UVM factory
    `uvm_object_utils(mm_seq_item)

    // parameters — must match DUT
    localparam N           = 4;
    localparam DATA_WIDTH  = 8;
    localparam ACCUM_WIDTH = 32;

    // ----------------------------------------------------------------
    // Stimulus fields — randomizable inputs to the DUT
    // ----------------------------------------------------------------
    rand logic [DATA_WIDTH-1:0]  A [N][N];   // input matrix A
    rand logic [DATA_WIDTH-1:0]  B [N][N];   // input matrix B

    // ----------------------------------------------------------------
    // Response fields — captured from DUT output, not randomized
    // ----------------------------------------------------------------
    logic [ACCUM_WIDTH-1:0] result_C [N][N]; // DUT result
    logic [ACCUM_WIDTH-1:0] expected_C [N][N]; // reference model result

    // ----------------------------------------------------------------
    // Constraints
    // ----------------------------------------------------------------

    // default — full random, no restrictions
    // add more constraints in extended classes for corner cases

    // prevent all-zero matrices from dominating random runs
    constraint non_zero_A {
        A.sum() with (int'(item)) > 0;
    }

    constraint non_zero_B {
        B.sum() with (int'(item)) > 0;
    }

    // keep values small enough to prevent overflow
    // max accumulator value = N * (2^DATA_WIDTH-1)^2
    // for N=4, DATA_WIDTH=8: 4 * 255^2 = 260100 which fits in 32-bit
    // no constraint needed for default params but good practice
    constraint data_range {
        foreach (A[i,j]) A[i][j] inside {[0:255]};
        foreach (B[i,j]) B[i][j] inside {[0:255]};
    }

    // ----------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------
    function new(string name = "mm_seq_item");
        super.new(name);
    endfunction

    // ----------------------------------------------------------------
    // Reference model — compute expected result from A and B
    // called by scoreboard after transaction is complete
    // ----------------------------------------------------------------
    function void compute_expected();
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                expected_C[i][j] = '0;
                for (int k = 0; k < N; k++)
                    expected_C[i][j] += ACCUM_WIDTH'(A[i][k]) * ACCUM_WIDTH'(B[k][j]);
            end
    endfunction

    // ----------------------------------------------------------------
    // UVM built-in utilities
    // ----------------------------------------------------------------

    // convert transaction to string — used by UVM logging
    function string convert2string();
        string s;
        s = $sformatf("mm_seq_item:\n");
        for (int i = 0; i < N; i++) begin
            s = {s, $sformatf("  A[%0d] = ", i)};
            for (int j = 0; j < N; j++)
                s = {s, $sformatf("%3d ", A[i][j])};
            s = {s, "\n"};
        end
        for (int i = 0; i < N; i++) begin
            s = {s, $sformatf("  B[%0d] = ", i)};
            for (int j = 0; j < N; j++)
                s = {s, $sformatf("%3d ", B[i][j])};
            s = {s, "\n"};
        end
        for (int i = 0; i < N; i++) begin
            s = {s, $sformatf("  C[%0d] = ", i)};
            for (int j = 0; j < N; j++)
                s = {s, $sformatf("%6d ", result_C[i][j])};
            s = {s, "\n"};
        end
        return s;
    endfunction

    // do_compare — used by scoreboard to compare two transactions
    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        mm_seq_item rhs_;
        if (!$cast(rhs_, rhs)) return 0;
        foreach (result_C[i,j])
            if (result_C[i][j] !== rhs_.result_C[i][j]) return 0;
        return 1;
    endfunction

endclass
