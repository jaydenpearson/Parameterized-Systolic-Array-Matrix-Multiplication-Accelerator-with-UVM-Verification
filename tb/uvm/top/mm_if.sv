interface mm_if #(
	parameter N = 4,
	parameter DATA_WIDTH = 8,
	parameter ACCUM_WIDTH = 32
)(
	input logic clk,
	input logic rst_n
);
	// DUT signals
	logic start;
	logic [N*DATA_WIDTH-1:0] a_in;
	logic [N*DATA_WIDTH-1:0] b_in;
	logic valid_in_upstream;
	logic ready;
	logic result_valid;
	logic [N*N*ACCUM_WIDTH-1:0] result;

	// Driver modport - signals driver is allowed to drive 
	// clk and rst_n are inputs because driver only reads them
	modport driver_mp (
		input clk,
		input rst_n,
		input ready,
		input result_valid,
		input result,
		output start,
		output a_in,
		output b_in,
		output valid_in_upstream
);
	// Monitor modport - monitir only observes, never drives
	modport monitor_mp (
		input clk,
		input rst_n,
		input start,
		input a_in,
		input b_in,
		input valid_in_upstream,
		input ready,
		input result_valid,
		input result
);

endinterface
