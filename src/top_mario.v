`timescale 1ns / 1ps


module tt_um_vga_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
	);

	// VGA signals
	wire hsync;
	wire vsync;
	wire [1:0] R;
	wire [1:0] G;
	wire [1:0] B;
	wire video_active;
	wire [9:0] pix_x;
	wire [9:0] pix_y;
	wire endframe;

		// TinyVGA PMOD
	assign uo_out  = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

	// Unused outputs assigned to 0.
	assign uio_out = 0;
	assign uio_oe  = 0;

	// Suppress unused signals warning
	wire _unused_ok = &{ena, ui_in[7:2], uio_in};

	hvsync_generator vga_sync_gen (
	  .clk(clk),
	  .reset(~rst_n),
	  .hsync(hsync),
	  .vsync(vsync),
	  .display_on(video_active),
	  .hpos(pix_x),
	  .vpos(pix_y)
	);

	assign endframe = ((pix_x == 0) & (pix_y == 480));

	// wire color
	wire [10:0] x_scroll;
	wire [11:0] bg_color;
	wire [5:0] mario_color;
	wire [5:0] sprites_color;
	reg [5:0] final_color;

	wire debug_sprite_fin;

	// dangerous code for ASIC, only init reg using reset
	// mario reg
	reg [9:0] scrollOffset = 0;
	reg [2:0] mario_state = 3'b000;		// 0 idle, 1 walk, 2 jump, flip bit[2] 0-left, 1-right
	reg [2:0] mario_anim = 0;			// running cycle 0,1  available only for 1 walk
	reg [10:0] mario_posX = 320;		// top left 
	reg [9:0] mario_posY = 352;

	// vRAM, topRAM, top, sprite_renderer
	wire [23:0] vRAM_dat_out, RAM_dat_out;
	reg [23:0] vRAM_dat_in = 0;
	reg [23:0] RAM_dat_in = 0;
	wire [5:0] vRAM_radd;
	reg [5:0] vRAM_wadd = 0;
	reg [5:0] RAM_radd = 0;
	reg [5:0] RAM_wadd = 0;
	reg vRAM_we = 0;
	reg RAM_we = 0;
	reg [23:0] sprite_data = 0;

	reg [7:0] state = 0;
	reg debug_state = 0;


	assign x_scroll = x + scrollOffset;
	
	bg_renderer bg_renderer1(.clk(clk),.reset(~rst_n),.x_scroll(x_scroll),.y(y),.color(bg_color));

	mario_renderer mario1(.clk(clk),.reset(~rst_n),.state(mario_state),.anim(mario_anim[2]),.posX(mario_posX),.posY(mario_posY),.x_scroll(x_scroll),.y(y),.color(mario_color));

	RAM topRAM(.clk(clk),.dat_in(RAM_dat_in),.wr_adr(RAM_wadd),.wr_en(RAM_we),.dat_out(RAM_dat_out),.rd_adr(RAM_radd));
	
	RAM2 #(.DATA_SIZE(24), .ADDR_SIZE(6)) vRAM(.clk(clk),.dat_in(vRAM_dat_in),.wr_adr(vRAM_wadd),.wr_en(vRAM_we),.dat_out(vRAM_dat_out),.rd_adr(vRAM_radd));
	
	//sprite_renderer sprite_renderer1(.clk(clk),.x_scroll_offset(scrollOffset),.x(x),.y(y),.sprite_data(vRAM_dat_out),.idx(vRAM_radd),.color(sprites_color),.debug_fin(debug_sprite_fin));

	
	
	// done all these for each frame
	always @(posedge clk) begin
		case (state)
			0: begin
				if (endframe) begin
					state <= 8'b1000_0000; 
				end 
			end
			// Transfer topRAM -> vRAM
			8'b1000_0000: begin
				RAM_radd <= 0;
				vRAM_wadd <= 0;
				vRAM_we <= 0;
				state <= 8'b1000_0001;
			end
			8'b1000_0001: begin
				state <= 8'b1000_0010;
			end
			8'b1000_0010: begin
				if (RAM_radd < 63) begin
					sprite_data <= RAM_dat_out;
					state <= 8'b1000_0011;
				end else begin
					state <= 0;
				end
			end
			8'b1000_0011: begin
				vRAM_we <= 1;
				vRAM_dat_in <= sprite_data;
				state <= 8'b1000_0100;
			end
			8'b1000_0100: begin
				vRAM_we <= 1;
				state <= 8'b1000_0101;
			end
			8'b1000_0101: begin
				vRAM_we <= 0;
				RAM_radd <= RAM_radd + 1;
				vRAM_wadd <= vRAM_wadd + 1;
				state <= 8'b1000_0001;
			end
			default: begin
				
			end
		endcase
	end	

	// handle key input, do once per frame, update mario pos, anim
	always @(posedge vsync) begin
		if(ui_in[0])begin
			if (mario_posX > 1) begin
				mario_posX <= mario_posX - 2;
				mario_state[2] <= 0;			// flip
				mario_state[1:0] <= 2'b01;		// walk
				mario_anim <= mario_anim + 1;	// loop animate overflow
			end
		end else if(ui_in[1])begin
			if (mario_posX < 638) begin
				mario_posX <= mario_posX + 2;
				mario_state[2] <= 1;
				mario_state[1:0] <= 2'b01;		// walk
				mario_anim <= mario_anim + 1;
			end
		end else begin
			mario_state[1:0] <= 2'b00;			// idle
		end
	end	

	// blend mario color (alpha (3F)) + coins color + bg color
	always @(*) begin
		if (mario_color == 6'h3F) begin
			if (sprites_color == 6'h3F) begin
				final_color = bg_color;
			end else begin
				final_color = bg_color;//sprites_color;
			end
		end else begin
			final_color = mario_color;
		end

	end

	assign R = (video_active)? final_color[5:4]:0;
	assign G = (video_active)? final_color[3:2]:0;
	assign B = (video_active)? final_color[1:0]:0;


endmodule