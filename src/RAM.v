`timescale 1ns / 1ps


// 64 sprites x 24 bits, 32 for coins, 31 for kuribo
// kuribo
//  [23] move left 1 / right 0
//	[22:21] state machine
//  [20:10] posX
//  [9:0] posY
// coin
//  [23] active 1 / inactive 0
//	[22:21] sprite animation
//  [20:10] posX
//  [9:0] posY
module RAM(
	input wire clk, 
	input wire [23:0] dat_in,
	input wire [5:0] wr_adr,
	input wire wr_en,
	output reg [23:0] dat_out,
	input wire [5:0] rd_adr
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [23:0] mem[63:0]; 		

	initial begin
		$readmemh("../data/sprites_arr.mem", mem);
	end


	always @(posedge clk) begin	
		if (wr_en)
			mem[wr_adr] <= dat_in;
		dat_out <= mem[rd_adr];
	end


endmodule