class mm_coverage extends uvm_subscriber #(mm_seq_item);

    `uvm_component_utils(mm_coverage)

    // local parameters
    localparam N           = 4;
    localparam DATA_WIDTH  = 8;
    localparam ACCUM_WIDTH = 32;

    // handle to the current transaction being sampled
    mm_seq_item item;

    // ----------------------------------------------------------------
    // Covergroups
    // ----------------------------------------------------------------

    // covers data value ranges for matrix A and B inputs
    covergroup cg_data_ranges;

        // cover zero values in A
        cp_a_zero: coverpoint item.A[0][0] {
            bins zero        = {0};
            bins sm          = {[1:15]};
            bins mid         = {[16:127]};
            bins lg          = {[128:254]};
            bins max_val     = {255};
        }

        // cover zero values in B
        cp_b_zero: coverpoint item.B[0][0] {
            bins zero        = {0};
            bins sm          = {[1:15]};
            bins mid         = {[16:127]};
            bins lg          = {[128:254]};
            bins max_val     = {255};
        }

        // cross coverage — both A and B at max simultaneously
        // this is the overflow risk scenario
        cx_ab_ranges: cross cp_a_zero, cp_b_zero;

    endgroup

    // covers matrix pattern scenarios
    covergroup cg_matrix_patterns;

        // identity matrix detection for A
        // checks if diagonal is all 1s and off-diagonal is all 0s
        cp_a_identity: coverpoint is_identity(item.A) {
            bins not_identity = {0};
            bins identity     = {1};
        }

        // identity matrix detection for B
        cp_b_identity: coverpoint is_identity(item.B) {
            bins not_identity = {0};
            bins identity     = {1};
        }

        // all-zeros matrix detection
        cp_a_all_zeros: coverpoint is_all_zeros_a(item.A) {
            bins not_zero = {0};
            bins all_zero = {1};
        }

        cp_b_all_zeros: coverpoint is_all_zeros_b(item.B) {
            bins not_zero = {0};
            bins all_zero = {1};
        }

        // all-max matrix — maximum accumulator stress
        cp_a_all_max: coverpoint is_all_max(item.A) {
            bins not_max  = {0};
            bins all_max  = {1};
        }

        cp_b_all_max: coverpoint is_all_max(item.B) {
            bins not_max  = {0};
            bins all_max  = {1};
        }

    endgroup

    // covers accumulator output ranges
    // ensures we have exercised small, mid, and large output values
    covergroup cg_result_ranges;

        cp_result_corner: coverpoint item.result_C[0][0] {
            bins zero         = {0};
            bins sm           = {[1:255]};
            bins mid          = {[256:65535]};
            bins lg           = {[65536:16777215]};
            bins near_max     = {[16777216:$]};
        }

    endgroup

    // ----------------------------------------------------------------
    // Constructor — create covergroups here
    // ----------------------------------------------------------------
    function new(string name = "mm_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_data_ranges     = new();
        cg_matrix_patterns = new();
        cg_result_ranges   = new();
    endfunction

    // ----------------------------------------------------------------
    // build_phase
    // ----------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
	cg_data_ranges.start();
	cg_matrix_patterns.start();
	cg_result_ranges.start();
    endfunction

    // ----------------------------------------------------------------
    // write — called automatically when monitor broadcasts
    // sample all covergroups with current transaction
    // ----------------------------------------------------------------
    function void write(mm_seq_item t);
        item = t;
        cg_data_ranges.sample();
        cg_matrix_patterns.sample();
        cg_result_ranges.sample();
    endfunction

    // ----------------------------------------------------------------
    // report_phase — print coverage summary at end of simulation
    // ----------------------------------------------------------------
    function void report_phase(uvm_phase phase);
	real overall;
	overall = (cg_data_ranges.get_coverage() + cg_matrix_patterns.get_coverage() + cg_result_ranges.get_coverage()) / 3.0;
        `uvm_info("COVERAGE",
            $sformatf("\n========================================\n  COVERAGE SUMMARY\n  Data Ranges:     %.1f%%\n  Matrix Patterns: %.1f%%\n  Result Ranges:   %.1f%%\n  Overall:         %.1f%%\n========================================",
                cg_data_ranges.get_coverage(),
                cg_matrix_patterns.get_coverage(),
                cg_result_ranges.get_coverage(),
                overall),
            UVM_LOW)
    endfunction

    // ----------------------------------------------------------------
    // Helper functions — used by covergroup coverpoints
    // ----------------------------------------------------------------

    // returns 1 if matrix is an identity matrix
    function automatic bit is_identity(logic [DATA_WIDTH-1:0] mat [N][N]);
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++) begin
                if (i == j && mat[i][j] !== 1) return 0;
                if (i != j && mat[i][j] !== 0) return 0;
            end
        return 1;
    endfunction

    // returns 1 if matrix A is all zeros
    function automatic bit is_all_zeros_a(logic [DATA_WIDTH-1:0] mat [N][N]);
        foreach (mat[i,j])
            if (mat[i][j] !== 0) return 0;
        return 1;
    endfunction

    // returns 1 if matrix B is all zeros
    function automatic bit is_all_zeros_b(logic [DATA_WIDTH-1:0] mat [N][N]);
        foreach (mat[i,j])
            if (mat[i][j] !== 0) return 0;
        return 1;
    endfunction

    // returns 1 if all elements are at max value (255 for 8-bit)
    function automatic bit is_all_max(logic [DATA_WIDTH-1:0] mat [N][N]);
        foreach (mat[i,j])
            if (mat[i][j] !== {DATA_WIDTH{1'b1}}) return 0;
        return 1;
    endfunction

endclass
