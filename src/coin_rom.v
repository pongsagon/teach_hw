`timescale 1ns / 1ps

// 64 x 16, 4 tile 
module coin_rom(
	input wire clk, 
	input wire [1:0] tile,			// 4 tile
	input wire [3:0] offsetX,		// 16x16 per tile
	input wire [3:0] offsetY,
	output reg [5:0] color
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [5:0] mem[1023:0]; 
	wire [9:0] mem_index;

	initial begin
		$readmemh("../data/coinj.mem", mem);
	end

	assign mem_index = ({1'b0,offsetY} < 16 && {1'b0,tile,offsetX} < 64)? 
						(offsetY * 64 + {3'b000,tile,offsetX}) : 0 ; 	
	

	always @(posedge clk) begin	
	   color <= mem[mem_index];
	end


endmodule