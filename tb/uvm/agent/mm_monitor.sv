class mm_monitor extends uvm_monitor;

    `uvm_component_utils(mm_monitor)

    // handle to virtual interface
    virtual mm_if #(.N(4), .DATA_WIDTH(8), .ACCUM_WIDTH(32)) vif;

    // analysis port — broadcasts completed transactions to subscribers
    uvm_analysis_port #(mm_seq_item) ap;

    // local parameters
    localparam N           = 4;
    localparam DATA_WIDTH  = 8;
    localparam ACCUM_WIDTH = 32;

    // ----------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------
    function new(string name = "mm_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ----------------------------------------------------------------
    // build_phase — get virtual interface, create analysis port
    // ----------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // create the analysis port
        ap = new("ap", this);

        // retrieve virtual interface from config_db
        if (!uvm_config_db #(virtual mm_if)::get(
            this, "", "mm_vif", vif))
            `uvm_fatal("NO_VIF",
                "mm_monitor: could not get virtual interface from config_db")
    endfunction

    // ----------------------------------------------------------------
    // run_phase — main monitor loop
    // ----------------------------------------------------------------
    task run_phase(uvm_phase phase);

        // wait for reset to deassert before monitoring anything
        @(posedge vif.clk);
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            collect_transaction();
        end
    endtask

    // ----------------------------------------------------------------
    // collect_transaction — watches DUT and assembles one transaction
    // ----------------------------------------------------------------
    task collect_transaction();
        mm_seq_item item;
        item = mm_seq_item::type_id::create("item");

        // ---- capture stimulus side ----
        // wait for start pulse to begin
        @(posedge vif.clk iff vif.monitor_mp.start === 1'b1);

        // wait for valid_in_upstream to assert — data is flowing
        @(posedge vif.clk iff vif.monitor_mp.valid_in_upstream === 1'b1);

        // capture N cycles of input data
        for (int cycle = 0; cycle < N; cycle++) begin
            // capture column 'cycle' of A from a_in lanes
            for (int row = 0; row < N; row++)
                item.A[row][cycle] =
                    vif.monitor_mp.a_in[row*DATA_WIDTH +: DATA_WIDTH];

            // capture row 'cycle' of B from b_in lanes
            for (int col = 0; col < N; col++)
                item.B[cycle][col] =
                    vif.monitor_mp.b_in[col*DATA_WIDTH +: DATA_WIDTH];

            // advance one cycle unless this is the last data cycle
            if (cycle < N-1) @(posedge vif.clk);
        end

        // ---- capture response side ----
        // wait for result_valid to assert — DUT is done
        @(posedge vif.clk iff vif.monitor_mp.result_valid === 1'b1);

        // unpack flat result bus into 2D array
        for (int i = 0; i < N; i++)
            for (int j = 0; j < N; j++)
                item.result_C[i][j] =
                    vif.monitor_mp.result[(i*N+j)*ACCUM_WIDTH +: ACCUM_WIDTH];

        // compute expected result using reference model in seq_item
        item.compute_expected();

        // log the transaction at medium verbosity
        `uvm_info("MONITOR", item.convert2string(), UVM_MEDIUM)

        // broadcast to all subscribers
        ap.write(item);

    endtask

endclass
