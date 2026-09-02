`timescale 1ns / 1ps

// 128 x 32, 4 tile 
module mario_rom(
	input wire clk, 
	input wire [1:0] tile,			// 4 tile
	input wire [4:0] offsetX,		// 32x32 per tile
	input wire [4:0] offsetY,
	output reg [5:0] color
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [5:0] mem[4095:0]; 
	wire [11:0] mem_index;

	initial begin
		$readmemh("../data/mario32j.mem", mem);
	end

	assign mem_index = ({1'b0,offsetY} < 32 && {1'b0,tile,offsetX} < 128)? 
						(offsetY * 128 + {4'b0000,tile,offsetX}) : 0 ; 	
	

	always @(posedge clk) begin	
	   color <= mem[mem_index];
	end


endmodule