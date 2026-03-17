class mm_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(mm_scoreboard)

    // analysis export — monitor connects to this
    uvm_analysis_imp #(mm_seq_item, mm_scoreboard) analysis_export;

    // scorecard counters
    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned total_count;

    // local parameters
    localparam N           = 4;
    localparam ACCUM_WIDTH = 32;

    // ----------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------
    function new(string name = "mm_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        pass_count  = 0;
        fail_count  = 0;
        total_count = 0;
    endfunction

    // ----------------------------------------------------------------
    // build_phase — create analysis export
    // ----------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    // ----------------------------------------------------------------
    // write — called automatically by UVM every time monitor
    // broadcasts a transaction via ap.write()
    // ----------------------------------------------------------------
    function void write(mm_seq_item item);
        int unsigned errors;
        errors = 0;
        total_count++;

        // reference model already computed expected_C in monitor
        // just compare result_C vs expected_C
        for (int i = 0; i < N; i++) begin
            for (int j = 0; j < N; j++) begin
                if (item.result_C[i][j] !== item.expected_C[i][j]) begin
                    `uvm_error("SCOREBOARD",
                        $sformatf("MISMATCH at C[%0d][%0d]: got=%0d expected=%0d",
                            i, j,
                            item.result_C[i][j],
                            item.expected_C[i][j]))
                    errors++;
                end
            end
        end

        if (errors == 0) begin
            pass_count++;
            `uvm_info("SCOREBOARD",
                $sformatf("PASS -  transaction %0d all %0d elements match",
                    total_count, N*N),
                UVM_MEDIUM)
        end else begin
            fail_count++;
            `uvm_error("SCOREBOARD",
                $sformatf("FAIL - transaction %0d had %0d mismatches",
                    total_count, errors))
            // print the full transaction for debug
            `uvm_info("SCOREBOARD", item.convert2string(), UVM_LOW)
        end

    endfunction

    // ----------------------------------------------------------------
    // report_phase — runs after simulation ends
    // prints final summary of all transactions
    // ----------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", 
            $sformatf("\n========================================\n  SCOREBOARD SUMMARY\n  Total:  %0d\n  Passed: %0d\n  Failed: %0d\n========================================",
                total_count, pass_count, fail_count),
            UVM_LOW)

        // fail the simulation if any transactions failed
        if (fail_count > 0)
            `uvm_fatal("SCOREBOARD",
                $sformatf("SIMULATION FAILED - %0d transactions failed", 
                    fail_count))
    endfunction

endclass
