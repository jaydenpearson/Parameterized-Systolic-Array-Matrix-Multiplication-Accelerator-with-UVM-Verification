class mm_driver extends uvm_driver #(mm_seq_item);

    `uvm_component_utils(mm_driver)

    // handle to the virtual interface — set by tb_top via config_db
    virtual mm_if #(.N(4), .DATA_WIDTH(8), .ACCUM_WIDTH(32)) vif;

    // local parameters matching DUT
    localparam N          = 4;
    localparam DATA_WIDTH = 8;

    // ----------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------
    function new(string name = "mm_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ----------------------------------------------------------------
    // build_phase — retrieve virtual interface from config_db
    // ----------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual mm_if)::get(
            this, "", "mm_vif", vif))
            `uvm_fatal("NO_VIF",
                "mm_driver: could not get virtual interface from config_db")
    endfunction

    // ----------------------------------------------------------------
    // run_phase — main driver loop
    // ----------------------------------------------------------------
    task run_phase(uvm_phase phase);
        // initialize all inputs to safe idle state
        vif.driver_mp.start            <= 0;
        vif.driver_mp.valid_in_upstream <= 0;
        vif.driver_mp.a_in             <= '0;
        vif.driver_mp.b_in             <= '0;

        // wait for reset to deassert before driving anything
        @(posedge vif.clk);
        wait (vif.rst_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            // get next transaction from sequencer — blocks until available
            seq_item_port.get_next_item(req);

            // drive the transaction
            drive_transaction(req);

            // tell sequencer this item is done
            seq_item_port.item_done();
        end
    endtask

    // ----------------------------------------------------------------
    // drive_transaction — converts one seq_item into pin wiggles
    // ----------------------------------------------------------------
    task drive_transaction(mm_seq_item item);

        // wait for DUT to be ready
        // pulse start then wait for ready to assert
        @(posedge vif.clk);
        vif.driver_mp.start <= 1;
        @(posedge vif.clk);
        vif.driver_mp.start <= 0;

        // wait until controller asserts ready
        wait (vif.driver_mp.ready === 1'b1);

        // feed N cycles of matrix data
        // each cycle: one column of A across all row lanes
        //             one row of B across all col lanes
        for (int cycle = 0; cycle < N; cycle++) begin
            @(posedge vif.clk);
            vif.driver_mp.valid_in_upstream <= 1;

            // drive column 'cycle' of A into a_in lanes
            for (int row = 0; row < N; row++)
                vif.driver_mp.a_in[row*DATA_WIDTH +: DATA_WIDTH] <=
                    item.A[row][cycle];

            // drive row 'cycle' of B into b_in lanes
            for (int col = 0; col < N; col++)
                vif.driver_mp.b_in[col*DATA_WIDTH +: DATA_WIDTH] <=
                    item.B[cycle][col];
        end

        // deassert valid after N cycles of data
        @(posedge vif.clk);
        vif.driver_mp.valid_in_upstream <= 0;
        vif.driver_mp.a_in             <= '0;
        vif.driver_mp.b_in             <= '0;

        // wait for result_valid — DUT signals computation complete
        wait (vif.driver_mp.result_valid === 1'b1);
        @(posedge vif.clk);

    endtask

endclass
