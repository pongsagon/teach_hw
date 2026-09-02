`timescale 1ns / 1ps

// 32 x 16, 2 tile 
module kuribo_rom(
	input wire clk, 
	input wire tile,			// 2 tile
	input wire [3:0] offsetX,	// 16x16 per tile
	input wire [3:0] offsetY,
	output reg [5:0] color
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [5:0] mem[511:0]; 
	wire [8:0] mem_index;

	initial begin
		$readmemh("../data/kuribo16j.mem", mem);
	end

	assign mem_index = ({1'b0,offsetY} < 16 && {1'b0,tile,offsetX} < 32)? 
						(offsetY * 32 + {3'b000,tile,offsetX}) : 0 ; 	
	

	always @(posedge clk) begin	
	   color <= mem[mem_index];
	end


endmodule