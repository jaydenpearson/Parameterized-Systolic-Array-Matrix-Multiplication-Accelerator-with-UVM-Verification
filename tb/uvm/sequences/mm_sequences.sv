// ----------------------------------------------------------------
// Base sequence — all sequences extend this
// contains common utilities
// ----------------------------------------------------------------
class mm_base_seq extends uvm_sequence #(mm_seq_item);

    `uvm_object_utils(mm_base_seq)

    localparam N          = 4;
    localparam DATA_WIDTH = 8;

    function new(string name = "mm_base_seq");
        super.new(name);
    endfunction

    // utility — send one item with optional constraint override
    task send_item(mm_seq_item item);
        start_item(item);
        if (!item.randomize())
            `uvm_fatal("RAND_FAIL", "mm_base_seq: randomization failed")
        finish_item(item);
    endtask

endclass


// ----------------------------------------------------------------
// Random sequence — fully constrained random matrices
// workhorse sequence for regression runs
// ----------------------------------------------------------------
class mm_rand_seq extends mm_base_seq;

    `uvm_object_utils(mm_rand_seq)

    // number of random transactions to run
    int unsigned num_transactions = 100;

    function new(string name = "mm_rand_seq");
        super.new(name);
    endfunction

    task body();
        mm_seq_item item;

        repeat (num_transactions) begin
            item = mm_seq_item::type_id::create("item");
            send_item(item);
        end

        `uvm_info("RAND_SEQ",
            $sformatf("Completed %0d random transactions", num_transactions),
            UVM_LOW)
    endtask

endclass


// ----------------------------------------------------------------
// Corner sequence — targeted corner case scenarios
// hits specific bins that random is unlikely to find quickly
// ----------------------------------------------------------------
class mm_corner_seq extends mm_base_seq;

    `uvm_object_utils(mm_corner_seq)

    function new(string name = "mm_corner_seq");
        super.new(name);
    endfunction

    task body();
        mm_seq_item item;

        // ---- Test 1: all zeros ----
        item = mm_seq_item::type_id::create("item");
        start_item(item);
        foreach (item.A[i,j]) item.A[i][j] = '0;
        foreach (item.B[i,j]) item.B[i][j] = '0;
        finish_item(item);
        `uvm_info("CORNER_SEQ", "Sent all-zeros transaction", UVM_MEDIUM)

        // ---- Test 2: identity x identity ----
        item = mm_seq_item::type_id::create("item");
        start_item(item);
        foreach (item.A[i,j]) item.A[i][j] = (i == j) ? 8'd1 : 8'd0;
        foreach (item.B[i,j]) item.B[i][j] = (i == j) ? 8'd1 : 8'd0;
        finish_item(item);
        `uvm_info("CORNER_SEQ", "Sent identity x identity transaction", UVM_MEDIUM)

        // ---- Test 3: all ones ----
        item = mm_seq_item::type_id::create("item");
        start_item(item);
        foreach (item.A[i,j]) item.A[i][j] = 8'd1;
        foreach (item.B[i,j]) item.B[i][j] = 8'd1;
        finish_item(item);
        `uvm_info("CORNER_SEQ", "Sent all-ones transaction", UVM_MEDIUM)

        // ---- Test 4: max values — accumulator stress ----
        item = mm_seq_item::type_id::create("item");
        start_item(item);
        foreach (item.A[i,j]) item.A[i][j] = 8'hFF;
        foreach (item.B[i,j]) item.B[i][j] = 8'hFF;
        finish_item(item);
        `uvm_info("CORNER_SEQ", "Sent all-max transaction", UVM_MEDIUM)

        // ---- Test 5: identity x random ----
        // result should equal B exactly
        item = mm_seq_item::type_id::create("item");
        start_item(item);
        foreach (item.A[i,j]) item.A[i][j] = (i == j) ? 8'd1 : 8'd0;
        if (!item.randomize())
            `uvm_fatal("RAND_FAIL", "randomization failed")
        foreach (item.A[i,j]) item.A[i][j] = (i == j) ? 8'd1 : 8'd0;
	finish_item(item);
        `uvm_info("CORNER_SEQ", "Sent identity x random transaction", UVM_MEDIUM)

        // ---- Test 6: random x identity ----
        // result should equal A exactly
        item = mm_seq_item::type_id::create("item");
        start_item(item);
        if (!item.randomize())
            `uvm_fatal("RAND_FAIL", "randomization failed")
        foreach (item.B[i,j]) item.B[i][j] = (i == j) ? 8'd1 : 8'd0;
        finish_item(item);
        `uvm_info("CORNER_SEQ", "Sent random x identity transaction", UVM_MEDIUM)

        `uvm_info("CORNER_SEQ", "All corner cases complete", UVM_LOW)
    endtask

endclass


// ----------------------------------------------------------------
// Stress sequence — back to back transactions with no idle cycles
// tests that DUT correctly resets between consecutive multiplies
// ----------------------------------------------------------------
class mm_stress_seq extends mm_base_seq;

    `uvm_object_utils(mm_stress_seq)

    int unsigned num_transactions = 20;

    function new(string name = "mm_stress_seq");
        super.new(name);
    endfunction

    task body();
        mm_seq_item item;

        // back to back — finish_item returns the moment driver
        // calls item_done, next item starts immediately
        repeat (num_transactions) begin
            item = mm_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("RAND_FAIL", "randomization failed")
            finish_item(item);
        end

        `uvm_info("STRESS_SEQ",
            $sformatf("Completed %0d back-to-back transactions",
                num_transactions),
            UVM_LOW)
    endtask

endclass


// ----------------------------------------------------------------
// Regression sequence — runs all sequences in order
// one sequence to rule them all for CI/CD regression
// ----------------------------------------------------------------
class mm_regression_seq extends mm_base_seq;

    `uvm_object_utils(mm_regression_seq)

    function new(string name = "mm_regression_seq");
        super.new(name);
    endfunction

    task body();
        mm_corner_seq corner_seq;
        mm_rand_seq   rand_seq;
        mm_stress_seq stress_seq;

        // corners first — shake out obvious bugs cheaply
        corner_seq = mm_corner_seq::type_id::create("corner_seq");
        corner_seq.start(m_sequencer);

        // then random — broad coverage
        rand_seq = mm_rand_seq::type_id::create("rand_seq");
        rand_seq.num_transactions = 200;
        rand_seq.start(m_sequencer);

        // then stress — back to back
        stress_seq = mm_stress_seq::type_id::create("stress_seq");
        stress_seq.num_transactions = 50;
        stress_seq.start(m_sequencer);

        `uvm_info("REGRESSION_SEQ", "Full regression complete", UVM_LOW)
    endtask

endclass
