class mm_env extends uvm_env;

    `uvm_component_utils(mm_env)

    // ----------------------------------------------------------------
    // Component handles
    // ----------------------------------------------------------------
    mm_agent      agent;
    mm_scoreboard scoreboard;
    mm_coverage   coverage;

    // ----------------------------------------------------------------
    // Constructor
    // ----------------------------------------------------------------
    function new(string name = "mm_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // ----------------------------------------------------------------
    // build_phase — instantiate all components
    // ----------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        agent      = mm_agent::type_id::create("agent", this);
        scoreboard = mm_scoreboard::type_id::create("scoreboard", this);
        coverage   = mm_coverage::type_id::create("coverage", this);

        // set agent to active mode — we want to drive and observe
        uvm_config_db #(uvm_active_passive_enum)::set(
            this, "agent", "is_active", UVM_ACTIVE);

    endfunction

    // ----------------------------------------------------------------
    // connect_phase — wire analysis ports to exports
    // agent.ap broadcasts to both scoreboard and coverage
    // ----------------------------------------------------------------
    function void connect_phase(uvm_phase phase);

        // monitor → scoreboard
        agent.ap.connect(scoreboard.analysis_export);

        // monitor → coverage
        agent.ap.connect(coverage.analysis_export);

    endfunction

endclass
