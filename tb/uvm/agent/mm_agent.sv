class mm_agent extends uvm_agent;

    `uvm_component_utils(mm_agent)

    // ----------------------------------------------------------------
    // Component handles — child components this agent owns
    // ----------------------------------------------------------------
    mm_driver    driver;
    mm_monitor   monitor;
    uvm_sequencer #(mm_seq_item) sequencer;

    // analysis port — pass-through from monitor to env level
    // env connects this to scoreboard and coverage
    uvm_analysis_port #(mm_seq_item) ap;

    // ----------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------
    function new(string name = "mm_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ----------------------------------------------------------------
    // build_phase — instantiate child components
    // is_active is a built-in UVM field — UVM_ACTIVE or UVM_PASSIVE
    // ----------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // always build the monitor — active and passive both observe
        monitor = mm_monitor::type_id::create("monitor", this);

        // only build driver and sequencer in active mode
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = mm_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(mm_seq_item)::type_id::create(
                            "sequencer", this);
        end
    endfunction

    // ----------------------------------------------------------------
    // connect_phase — wire components together
    // connect_phase runs after ALL build_phases complete
    // this guarantees driver and sequencer both exist before connecting
    // ----------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        // connect monitor's analysis port up to agent level
        // env will connect this further to scoreboard and coverage
        ap = monitor.ap;

        // connect driver to sequencer — the TLM connection
        // driver pulls items from sequencer via this port
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass
