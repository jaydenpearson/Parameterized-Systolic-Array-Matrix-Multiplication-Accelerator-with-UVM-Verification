// ----------------------------------------------------------------
// Base test — all tests extend this
// creates env, retrieves virtual interface, common configuration
// ----------------------------------------------------------------
class mm_base_test extends uvm_test;

    `uvm_component_utils(mm_base_test)

    mm_env env;

    localparam N           = 4;
    localparam DATA_WIDTH  = 8;
    localparam ACCUM_WIDTH = 32;

    function new(string name = "mm_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // create the env — this triggers build_phase cascade
        // down through agent, driver, monitor, scoreboard, coverage
        env = mm_env::type_id::create("env", this);

    endfunction

    // end_of_elaboration_phase — good place to print topology
    // runs after all build and connect phases complete
    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    // base run_phase — subclasses override this with their sequence
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        phase.drop_objection(this);
    endtask

endclass


// ----------------------------------------------------------------
// Corner test — runs corner case sequence only
// fast smoke test, run this first
// ----------------------------------------------------------------
class mm_corner_test extends mm_base_test;

    `uvm_component_utils(mm_corner_test)

    function new(string name = "mm_corner_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        mm_corner_seq seq;
        seq = mm_corner_seq::type_id::create("seq");

        phase.raise_objection(this);

        // small drain time before starting — let reset propagate
        #50;

        seq.start(env.agent.sequencer);

        // small drain time after sequence — let last transaction complete
        #100;

        phase.drop_objection(this);
    endtask

endclass


// ----------------------------------------------------------------
// Random test — runs fully random sequence
// main coverage gathering test
// ----------------------------------------------------------------
class mm_rand_test extends mm_base_test;

    `uvm_component_utils(mm_rand_test)

    function new(string name = "mm_rand_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        mm_rand_seq seq;
        seq = mm_rand_seq::type_id::create("seq");

        phase.raise_objection(this);
        #50;

        // override number of transactions from command line if provided
        // xrun ... +NUM_TRANSACTIONS=500
        begin
            int unsigned n;
            if ($value$plusargs("NUM_TRANSACTIONS=%0d", n))
                seq.num_transactions = n;
        end

        seq.start(env.agent.sequencer);
        #100;

        phase.drop_objection(this);
    endtask

endclass


// ----------------------------------------------------------------
// Stress test — back to back transactions
// tests reset between consecutive multiplies
// ----------------------------------------------------------------
class mm_stress_test extends mm_base_test;

    `uvm_component_utils(mm_stress_test)

    function new(string name = "mm_stress_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        mm_stress_seq seq;
        seq = mm_stress_seq::type_id::create("seq");

        phase.raise_objection(this);
        #50;

        seq.start(env.agent.sequencer);
        #100;

        phase.drop_objection(this);
    endtask

endclass


// ----------------------------------------------------------------
// Regression test — runs all sequences end to end
// this is what CI/CD runs
// ----------------------------------------------------------------
class mm_regression_test extends mm_base_test;

    `uvm_component_utils(mm_regression_test)

    function new(string name = "mm_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        mm_regression_seq seq;
        seq = mm_regression_seq::type_id::create("seq");

        phase.raise_objection(this);
        #50;

        seq.start(env.agent.sequencer);
        #100;

        phase.drop_objection(this);
    endtask

endclass
