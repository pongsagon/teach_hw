`timescale 1ns / 1ps


module bg_renderer(
	input wire clk, 
	input wire reset,
	input wire [10:0] x_scroll,
	input wire [9:0] y,
	output reg [5:0] color
	);

	//(* rom_style = "block" *)	// Infer ROM as Block RAM
	reg [5:0] mem[69631:0]; 
	wire [16:0] mem_index;
	wire [7:0] tile;
	wire [3:0] offsetX, offsetY;

	initial begin
		$readmemh("../data/mariobg256j.mem", mem);
	end

	// delayed pixel count
    reg [9:0] pix_x1_reg;
    reg [9:0] pix_y1_reg;
	always @(posedge clk) begin
		if(reset)begin
			pix_x1_reg <= 0;
            pix_y1_reg <= 0;
		end
		else begin
			pix_x1_reg <= x_scroll;
            pix_y1_reg <= y;
		end
	end

	assign offsetX = pix_x1_reg[3:0];
	assign offsetY = pix_y1_reg[3:0];
	assign mem_index = ({1'b0,tile[7:4],offsetY} < 256 && {1'b0,tile[3:0],offsetX} < 256)? 
						({tile[7:4],offsetY} * 256 + {9'b0_0000_0000,tile[3:0],offsetX}) : 0 ; 	
	
	// tile ready 1 clk delay from x,y
	map_rom map_rom1(.clk(clk),.x_scroll(x_scroll[10:4]),.y(y),.tile(tile));

	
	always @(posedge clk) begin	
		if(reset)begin
			color <= 0;
		end
		else begin
			color <= (tile == 0)? 6'h3F : mem[mem_index];
		end
	end

endmodule