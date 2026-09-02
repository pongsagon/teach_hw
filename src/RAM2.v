`timescale 1ns / 1ps

// empty ram
module RAM2
	#(
        parameter DATA_SIZE = 24,
        parameter ADDR_SIZE = 6
    )
	(
	input wire clk, 
	input wire [DATA_SIZE-1:0] dat_in,
	input wire [ADDR_SIZE-1:0] wr_adr,
	input wire wr_en,
	output reg [DATA_SIZE-1:0] dat_out,
	input wire [ADDR_SIZE-1:0] rd_adr
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [DATA_SIZE-1:0] mem[2**ADDR_SIZE-1:0]; 		


	always @(posedge clk) begin	
		if (wr_en)
			mem[wr_adr] <= dat_in;
		dat_out <= mem[rd_adr];
	end


endmodule