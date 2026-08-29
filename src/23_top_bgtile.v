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
  
	
	wire [7:0] tile;
	wire [5:0] color;
	reg [9:0] scrollOffset;
	wire [10:0] x_scroll;

	assign x_scroll = pix_x + scrollOffset;
	map_rom map_rom1(.clk(clk),.x_scroll(x_scroll[10:4]),.y(pix_y),.tile(tile));
	bg_rom bg_rom1(.clk(clk),.tile(tile),.offsetX(pix_x1_reg[3:0]),.offsetY(pix_y1_reg[3:0]),.color(color));

	// delayed pixel count
    reg [9:0] pix_x1_reg;
    reg [9:0] pix_x2_reg;
	always @(posedge clk) begin
		if(!rst_n)begin
			scrollOffset <= 0;
			pix_x1_reg <= 0;
            pix_y1_reg <= 0;
		end
		else begin
			pix_x1_reg <= x_scroll;
            pix_y1_reg <= pix_y;
		end
	end

	// handle input for scrolling, do oncex4 per frame
	always @(posedge vsync) begin
		if(ui_in[0])begin
			if (scrollOffset > 0) begin
				scrollOffset <= scrollOffset - 2;
			end
		end
		if(ui_in[1])begin
			if (scrollOffset < 638) begin
				scrollOffset <= scrollOffset + 2;
			end
		end
	end	

	assign R = (video_active)? color[5:4]:0;
	assign G = (video_active)? color[3:2]:0;
	assign B = (video_active)? color[1:0]:0;

endmodule