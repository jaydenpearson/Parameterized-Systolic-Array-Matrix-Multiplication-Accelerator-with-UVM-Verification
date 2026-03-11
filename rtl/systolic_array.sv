module systolic_array #(
	parameter N		= 4,
	parameter DATA_WIDTH	= 8,
	parameter ACCUM_WIDTH	= 32
)(
	input  logic			   clk, rst_n,
	input  logic [N*DATA_WIDTH-1:0]	   a_row,
	input  logic [N*DATA_WIDTH-1:0]	   b_col,
	input  logic			   valid_in,
	output logic [N*N*ACCUM_WIDTH-1:0] result,
	output logic			   valid_out
);

wire [DATA_WIDTH-1:0] a_wire [N][N+1];
wire [DATA_WIDTH-1:0] b_wire [N+1][N];
wire valid_wire [N+1][N+1];
wire [ACCUM_WIDTH-1:0] result_wire [N][N];

genvar i,j;

generate
	for (i=0;i < N;i++) begin
		assign a_wire[i][0] = a_row[i*DATA_WIDTH +: DATA_WIDTH];
		assign valid_wire[i][0] = valid_in;
	end

	for (j=0;j < N;j++) begin
		assign b_wire[0][j] = b_col[j*DATA_WIDTH +: DATA_WIDTH];
	end

	for (i=0;i < N;i++) begin
		for (j=0; j < N; j++) begin
			pe #(
				.DATA_WIDTH (DATA_WIDTH), 
				.ACCUM_WIDTH (ACCUM_WIDTH)
			) pe_inst (
				.clk (clk),
				.rst_n (rst_n),
				.a_in (a_wire[i][j]),
				.a_out (a_wire[i][j+1]),
				.b_in (b_wire[i][j]),
				.b_out (b_wire[i+1][j]),
				.valid_in (valid_wire[i][j]),
				.valid_out (valid_wire[i][j+1]),
				.accum (result_wire[i][j])
			);			
		end
	end


for (i=0;i < N;i++) begin : pack_row
	for (j=0; j < N; j++) begin : pack_col
		assign result[(i*N+j)*ACCUM_WIDTH +: ACCUM_WIDTH] = result_wire[i][j];
	end
end

endgenerate

assign valid_out = valid_wire[N-1][N];

endmodule
