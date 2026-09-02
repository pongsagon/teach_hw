`timescale 1ns / 1ps


// issue?
// - why y >= 480 not drive anything
module sprite_renderer(
	input clk, 
	input wire [9:0] x_scroll_offset,
	input wire [9:0] x,
	input wire [9:0] y,
	input wire [23:0] sprite_data,
	output reg [5:0] idx,
	output reg [11:0] color,
	output reg debug_fin		// true for 1 clk: when finish rendering for each line
	);

	localparam TILE_WIDTH = 16;

	parameter IDLE = 3'b000, WAIT_I = 3'b001, FOR_I = 3'b010, CHK_COMP_I = 3'b011, WAIT_C = 3'b100, WRITE_LB = 3'b101, CLEAR = 3'b110;
	reg [2:0] state = 0; 

	(* rom_style = "distributed" *)
	reg [11:0] line_buffer0[639:0];		// double buffer
	(* rom_style = "distributed" *)
	reg [11:0] line_buffer1[639:0];
	reg [9:0] clearX = 0;

	reg [1:0] prescaler = 0;  			// must init to 0, if init to 3 -> the last pixel is off to the next line??
	reg spriteI_state;
	reg [1:0] spriteI_anim;
	reg [10:0] spriteI_posX;
	reg [9:0] spriteI_posY;

	wire sprite_state;
	wire [1:0] sprite_anim;
	wire [10:0] sprite_posX;
	wire [9:0] sprite_posY;

	reg [10:0] lineX;							// line buffer index
	reg [9:0] offsetY; 
	reg [10:0] offsetX;
	reg [10:0] end_offsetX;

	wire [11:0] coin_color;
	wire [11:0] kuribo_color;
	wire [11:0] rom_color;

	reg [2:0] kuribo_anim = 0;			// always animate for kuribo, change to [4:0] for basys3s

	
	coin_rom coin_rom1(.clk(clk),.tile(spriteI_anim),.offsetX(offsetX[3:0]),.offsetY(offsetY[3:0]),.color(coin_color));
	
	kuribo_rom kuribo_rom1(.clk(clk),.tile(kuribo_anim[2]),.offsetX(offsetX[3:0]),.offsetY(offsetY[3:0]),.color(kuribo_color));

	assign sprite_state = sprite_data[23];
	assign sprite_anim = sprite_data[22:21];
	assign sprite_posX = sprite_data[20:10];
	assign sprite_posY = sprite_data[9:0];

	assign rom_color = (idx < 32)? coin_color : kuribo_color;

	always @(posedge clk) begin
		if (y == 0) begin
			kuribo_anim <= kuribo_anim + 1;
		end
	end

	always @(posedge clk) begin	
		if (y < 480) begin
			// read from line buffer and clear buffer
			if (x < 640) begin
				color <= (y[0] == 0)? line_buffer0[x] : line_buffer1[x];
			end

			// render to line buffer
			// 		- time limit 800 x 4 = 3200 clk
			//		- clear line buffer, empty line use 208 pix clk
			// 		- from test: 32 sprite x 16 width = +260 pix clk -> 464 pix clk
			case (state)
				IDLE: begin
					idx <= 0;
					debug_fin <= 0;

					if (x == 0) begin
						clearX <= 0;
						state <= CLEAR;
					end
				end
				CLEAR: begin
		    		if (clearX == 640) begin
		    			state <= FOR_I;
		    		end else begin
		    			if (y[0] == 0) begin
			    			line_buffer1[clearX] <= 12'hFFF;			// white = transparency
			    		end else begin
			    			line_buffer0[clearX] <= 12'hFFF;
			    		end
			    		clearX <= clearX + 1;
		    		end
				end 
				WAIT_I: begin
					state <= FOR_I;
				end
				FOR_I: begin
					if (idx < 63) begin          // for idx = 0 to 62, WATCH OUT for idx overflow to 0 again and not exit the loop
						spriteI_state <= sprite_state;
						spriteI_anim <= sprite_anim;
						spriteI_posX <= sprite_posX;
						spriteI_posY <= sprite_posY;
						state <= CHK_COMP_I;
					end else begin               // finish loop for idx
						state <= IDLE;
						debug_fin <= 1;
					end
				end 
				CHK_COMP_I: begin
					// check
					if ((spriteI_state == 0) && (idx < 32)) begin       // sprite inactive only for coin
						state <= WAIT_I;                 // continue for loop
						idx <= idx + 1;
					end else if ((y < spriteI_posY) || (y >= (spriteI_posY + TILE_WIDTH))) begin        // sprite not in this line
						state <= WAIT_I;
						idx <= idx + 1;
					end else if (({1'b0,x_scroll_offset} >= (spriteI_posX + TILE_WIDTH)) || ((x_scroll_offset + 640) <= spriteI_posX) ) begin        // sprite not in x range
						state <= WAIT_I;
						idx <= idx + 1;
					end else begin
						state <= WAIT_C;
					end

					// compute
					offsetY <= y - spriteI_posY;
					offsetX <= (spriteI_posX < {1'b0,x_scroll_offset})? {1'b0,x_scroll_offset} - spriteI_posX : 0;
					end_offsetX <= ( (x_scroll_offset + 640) < (spriteI_posX + TILE_WIDTH))? (x_scroll_offset + 640) - spriteI_posX : 15;
					lineX <= (spriteI_posX > {1'b0,x_scroll_offset})? spriteI_posX - {1'b0,x_scroll_offset} : 0;

				end
				WAIT_C: begin
					state <= WRITE_LB;
				end 
				WRITE_LB: begin
					if (offsetX < end_offsetX) begin              
						if (y[0] == 0) begin
							if (rom_color != 12'hFFF) begin
			    				line_buffer1[lineX[9:0]] <= rom_color;	
			    			end		
			    		end else begin
			    			if (rom_color != 12'hFFF) begin
			    				line_buffer0[lineX[9:0]] <= rom_color;
			    			end
			    		end
			    		lineX <= lineX + 1;
			    		offsetX <= offsetX + 1;
			    		state <= WAIT_C;
					end else begin
						state <= WAIT_I;
						idx <= idx + 1;          
					end
				end 
				default: begin
					state <= IDLE;
				end
			endcase

		end 
	end

endmodule



dule



