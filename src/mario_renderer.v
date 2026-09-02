`timescale 1ns / 1ps

// 128 x 32, 4 tile 
module mario_renderer(
	input wire clk, 
	input wire reset,
	// tile data form top
	input wire [2:0] state,    		// [1:0] 0 idle, 1-2 walk, 3 jump : flip bit[2] 0-left, 1-right
	input wire anim,				// running cycle 0,1  available only for 1 walk
	input wire [10:0] posX,			// top left 1280 double 640 screen size
	input wire [9:0] posY,			// top left 
	// x,y vga
	input wire [10:0] x_scroll,
	input wire [9:0] y,
	// output
	output reg [5:0] color
	);

	localparam WIDTH = 32;

	wire [5:0] mario_color;
	reg xy_in_sprite;
	wire [10:0] offsetX;			// only use [4:0] to mario_rom
	wire [9:0] offsetY;				// only use [4:0] to mario_rom
	wire [1:0] tile;


	assign offsetX = (state[2]) ? 31 - (x_scroll - posX) : x_scroll - posX;        // (state[2])? for flipped sprite
	assign offsetY = y - posY;
	assign tile = (state[1:0] == 3)? 3 : (state[1:0] == 0) ? 0 : 1 + anim;


	// tile: 0 idle, 1-2 walk, 3 jump
	mario_rom mario_rom1(.clk(clk),.tile(tile),.offsetX(offsetX[4:0]),.offsetY(offsetY[4:0]),.color(mario_color));

	// should have reset signal to reset every reg!
	always @(posedge clk)begin
		if(reset)begin
			xy_in_sprite <= 0;
			color <= 0;
		end
		else begin
			xy_in_sprite <= ((x_scroll >= posX) && (x_scroll < (posX + WIDTH)) && (y >= posY) && (y < (posY + WIDTH)));
			color <= (xy_in_sprite)?mario_color:6'h3F;
		end	
	end

endmodule