`timescale 1ns / 1ps


module map_rom(
	input wire clk, 
	input wire [6:0] x_scroll,			// tile unit, max 80 of 128
	input wire [9:0] y,
	output reg [7:0] tile
	);

	//(* rom_style = "block" *)			// Infer ROM as Block RAM
	reg [7:0] mem[2399:0]; 				// 80 x 30, 1280 x 480
	wire [11:0] mem_index;


	initial begin
		$readmemh("../data/map2.mem", mem);
	end

	assign mem_index = (y[8:4] < 30 && x_scroll < 80)? y[8:4]*80 + {4'b0000,x_scroll} : 0;
	

	always @(posedge clk) begin
	   tile <= mem[mem_index];
	end


endmodule