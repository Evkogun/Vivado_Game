`timescale 1ns / 1ps

 

module drawcon(
    input clk,
    input rst,
    input [10:0] blkpos_x,
    input [9:0] blkpos_y,
    input [3:0] sw_r,
    input [3:0] sw_g,
    input [3:0] sw_b,
    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b,
    input [10:0] curr_x,
    input [9:0] curr_y,
    
    input [4:0] btn
    );   

    reg [3:0] bg_r;
    reg [3:0] bg_g;
    reg [3:0] bg_b;
    reg [3:0] blk_r;
    reg [3:0] blk_g;
    reg [3:0] blk_b;
    reg [3:0] sprite_counter;
    
    reg [26:0] counterclk;
    reg sprtclk;
    
    parameter BLK_SIZE_X = 33, BLK_SIZE_Y = 20;
    reg [13:0] addr;
    reg [11:0] rom_pixel;
    wire [11:0] rom_pixel_0, rom_pixel_1, rom_pixel_2, rom_pixel_3;
    wire [11:0] rom_pixel_4, rom_pixel_5, rom_pixel_6, rom_pixel_7;
    wire [11:0] rom_pixel_8, rom_pixel_9, rom_pixel_10, rom_pixel_11;
 
    always @(posedge clk)

    begin
        // Temp testing if-else
//        if (sprite_counter < 4'd6)
//            rom_pixel <= rom_pixel_0;
//        else
//            rom_pixel <= 12'b111111111111;

        if (!rst)
        begin
            blk_r <= 4'b0000;
            blk_g <= 4'b0000;
            blk_b <= 4'b0000;
            addr <= 0;
        end
        else
        begin
            if (blkpos_x <= curr_x && curr_x <= blkpos_x+BLK_SIZE_X-1 && blkpos_y <= curr_y && curr_y <= blkpos_y+BLK_SIZE_Y-1)
            begin
                blk_r <= rom_pixel[11:8];
                blk_g <= rom_pixel[7:4];
                blk_b <= rom_pixel[3:0];
                if ((curr_x == blkpos_x) && (curr_y == blkpos_y))
                    addr <= 0;
                else
                    addr <= addr + 1;
            end
            else
            begin
                blk_r <= 4'b0000;
                blk_g <= 4'b0000;
                blk_b <= 4'b0000;
            end
        end
    end

 
    always @*
    begin
        if (curr_x < 11'd10 || curr_x > 11'd1429 || curr_y < 11'd10 || curr_y > 11'd889)
        begin
            bg_r <= 4'b1111;
            bg_g <= 4'b1111;
            bg_b <= 4'b1111;
        end
        else
        begin
            bg_r <= sw_r;
            bg_g <= sw_g;
            bg_b <= sw_b;
        end
    end
    
    always @(posedge sprtclk or negedge rst)
    begin
        if (!rst)
            sprite_counter <= 0;  // Reset the sprite counter on reset
        else if (sprite_counter == 4'd11)
            sprite_counter <= 0;
        else
            sprite_counter <= sprite_counter + 1;  // Increment the counter
    end
    
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            counterclk <= 27'd0;
            sprtclk <= 0;      
        end else begin
            if (counterclk >= 27'd25555555) begin
                counterclk <= 27'd0;
                sprtclk <= ~sprtclk;  // Toggle sprtclk every 50 million cycles
            end else begin
                counterclk <= counterclk + 1;
            end
        end
    end

    
   
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            rom_pixel <= rom_pixel_0;
        end
        else begin
        case (sprite_counter)
            4'd0: rom_pixel <= rom_pixel_0;
            4'd1: rom_pixel <= rom_pixel_1;
            4'd2: rom_pixel <= rom_pixel_2;
            4'd3: rom_pixel <= rom_pixel_3;
            4'd4: rom_pixel <= rom_pixel_2;
            4'd5: rom_pixel <= rom_pixel_1;
            4'd6: rom_pixel <= rom_pixel_0;
            4'd7: rom_pixel <= rom_pixel_4;
            4'd8: rom_pixel <= rom_pixel_5;
            4'd9: rom_pixel <= rom_pixel_6;
            4'd10: rom_pixel <= rom_pixel_5;
            4'd11: rom_pixel <= rom_pixel_4;
            default: rom_pixel <= rom_pixel_0;
        endcase
        end
    end
                   
    assign draw_r = (blk_r != 4'b0000) ? blk_r : bg_r;
    assign draw_g = (blk_g != 4'b0000) ? blk_g : bg_g;
    assign draw_b = (blk_b != 4'b0000) ? blk_b : bg_b;
      
    blk_mem_gen_0 Idle
    (
    .clka(clk),
    .addra(addr),
    .douta(rom_pixel_0)
    );
    
    blk_mem_gen_1 LeftWalk1
    (
    .clka(clk),
    .addra(addr),
    .douta(rom_pixel_1)
    );
    
    blk_mem_gen_2 LeftWalk2 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel_2)
    );

    blk_mem_gen_3 LeftWalk3 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel_3)
    );

    blk_mem_gen_4 RightWalk1 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel_4)
    );

    blk_mem_gen_5 RightWalk2 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel_5)
    );

    blk_mem_gen_6 RightWalk3 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel_6)
    );
    
//        clock_div_sprite clock_div_sprite_inst
//    (
//        .clk(clk),       
//        .reset(rst),   
//        .clk_out(sprtclk)
//    );

endmodule