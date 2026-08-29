`timescale 1ns / 1ps


module bg_rom(
	input wire clk, 
	input wire [7:0] tile,
	input wire [3:0] offsetX,
	input wire [3:0] offsetY,
	output reg [11:0] color
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [5:0] mem[69631:0]; 
	wire [16:0] mem_index;

	initial begin
		$readmemh("../data/mariobg256j.mem", mem);
	end

	assign mem_index = ({1'b0,tile[7:4],offsetY} < 256 && {1'b0,tile[3:0],offsetX} < 256)? 
						({tile[7:4],offsetY} * 256 + {9'b0_0000_0000,tile[3:0],offsetX}) : 0 ; 	
	

	always @(posedge clk) begin	
	   color <= (tile == 0)? 6'b111111 : mem[mem_index];
	end


endmodule