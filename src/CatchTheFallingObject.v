/*
 * Copyright (c) 2024 Uri Shaked
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_vga_example(
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
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};

  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;

  // Suppress unused signals warning
  wire _unused_ok = &{ena, uio_in};

 
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );

    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;

    localparam PLAYER_W = 60;
    localparam PLAYER_H = 15;
    localparam PLAYER_Y = 445;

    localparam OBJECT_SIZE = 16;

    reg [9:0] player_x;
    reg [9:0] object_x;
    reg [9:0] object_y;

    reg [4:0] score;
    reg [1:0] lives;

    reg game_over;
    reg game_win;

    reg [19:0] game_timer;
    reg [19:0] fall_timer;
    reg [23:0] random_counter;
  
   wire player_pixel =
        (pix_x >= player_x) &&
        (pix_x < player_x + PLAYER_W) &&
        (pix_y >= PLAYER_Y) &&
        (pix_y < PLAYER_Y + PLAYER_H);

     wire object_pixel =
        (pix_x >= object_x) &&
        (pix_x < object_x + OBJECT_SIZE) &&
        (pix_y >= object_y) &&
        (pix_y < object_y + OBJECT_SIZE);

     wire collision =
        (object_y + OBJECT_SIZE >= PLAYER_Y) &&
        (object_y <= PLAYER_Y + PLAYER_H) &&
        (object_x + OBJECT_SIZE >= player_x) &&
        (object_x <= player_x + PLAYER_W);

    wire left_button  = ui_in[0];
    wire right_button = ui_in[1];

     assign R = !video_active ? 2'b00 :
               game_win       ? 2'b00 :
               game_over      ? 2'b11 :
               player_pixel   ? 2'b00 :
               object_pixel   ? 2'b11 :
                                2'b00;
    assign G = !video_active ? 2'b00 :
               game_win       ? 2'b11 :
               game_over      ? 2'b00 :
               player_pixel   ? 2'b11 :
               object_pixel   ? 2'b11 :
                                2'b00;
    assign B = !video_active ? 2'b00 :
               game_win       ? 2'b00 :
               game_over      ? 2'b00 :
               player_pixel   ? 2'b11 :
               object_pixel   ? 2'b00 :
                                2'b00;

  
   always @(posedge vsync or negedge rst_n) begin
        if (!rst_n) begin
            player_x      <= 290;
            object_x      <= 200;
            object_y      <= 0;

            score         <= 0;
            lives         <= 3;

            game_over     <= 0;
            game_win      <= 0;

            game_timer    <= 0;
            fall_timer    <= 0;
            random_counter <= 0;
        end
        else begin
          random_counter <= random_counter + 1;

    //movement
    if (!game_over && !game_win) begin

                if (left_button && player_x > 0)
                    player_x <= player_x - 8;

                if (right_button && player_x < SCREEN_W - PLAYER_W)
                    player_x <= player_x + 8;
  	//falling speed
    game_timer <= game_timer + 1;

                if (game_timer >= 1) begin
                    game_timer <= 0;
                    fall_timer <= fall_timer + 1;
                end

                if (fall_timer >= 2) begin
                    fall_timer <= 0;
                    object_y <= object_y + 5;
                end
    // Catch object
                if (collision) begin
                    if (score < 20)
                        score <= score + 1;

                    object_y <= 0;
                    object_x <= random_counter % 600;
                end
     // Missed object
                else if (object_y >= SCREEN_H - OBJECT_SIZE) begin

                    if (lives > 0)
                        lives <= lives - 1;

                    object_y <= 0;
                    object_x <= random_counter % 600;

                end

      // Win condition
                if (score >= 19 && collision)
                    game_win <= 1;

                // Lose condition
                if (lives == 1 &&
                    object_y >= SCREEN_H - OBJECT_SIZE &&
                    !collision)
                    game_over <= 1;

            end
        end
    end

endmodule
