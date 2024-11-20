`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.04.2021 19:58:02
// Design Name: 
// Module Name: game_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module game_top(
    input clk,
    input rst,
    input [2:0] sw,
    input [4:0] btn,
    output [3:0] pix_r,
    output [3:0] pix_g,
    output [3:0] pix_b,
    output hsync,
    output vsync
    );

//internal wires
wire pixclk;
wire [3:0] draw_r;
wire [3:0] draw_g;
wire [3:0] draw_b;
wire [10:0] curr_x;
wire [10:0] curr_y;

//wires for the block
reg [20:0] clk_div;
reg game_clk;
reg [10:0] blkpos_x;
reg [10:0] blkpos_y;

//clock generator
    clk_wiz_0 inst
    (
        // Clock out ports
        .clk_out1(pixclk),
        // Clock in ports
        .clk_in1(clk)
    );

//game clock generation
always@(posedge clk) begin
    if(!rst) begin
        clk_div <= 0;
        game_clk <= 0;
    end else begin
        if (clk_div == 21'd1666666 ) begin
            clk_div <= 0;
            game_clk <= !game_clk;
        end else begin
            clk_div <= clk_div + 1;
        end
    end
end

//block movement
always@(posedge game_clk) begin
    if(btn[0]) begin
        blkpos_x <= 11'd10;
        blkpos_y <= 11'd10;
    end else begin
        case(btn[4:1])
            4'b0010: begin//left
                if(blkpos_x > 11'd10) begin
                   blkpos_x <= blkpos_x - 4;
                end
            end
            4'b0100: begin//right
                if(blkpos_x < (11'd1430-11'd50)) begin
                   blkpos_x <= blkpos_x + 4;
                end
            end
            
            4'b1000: begin//up
                if(blkpos_y < (11'd890-11'd50)) begin
                   blkpos_y <= blkpos_y + 4;
                end
            end
            4'b0001: begin//down
                if(blkpos_y > 11'd10) begin
                   blkpos_y <= blkpos_y - 4;
                end
            end
            default: begin
                blkpos_x <= blkpos_x;
                blkpos_y <= blkpos_y; 
            end
        endcase
    end
end
    
             
drawcon drawcon_inst(
    .clk(pixclk),
    .rst(rst),
    
    .blkpos_x(blkpos_x),
    .blkpos_y(blkpos_y),
    .draw_r(draw_r),
    .draw_g(draw_g),
    .draw_b(draw_b),
    .curr_x(curr_x),
    .curr_y(curr_y),
    
    .btn(btn)
);

vga vga_inst(
    .clk(pixclk),
    .rst(rst),
    .draw_r(draw_r),
    .draw_g(draw_g),
    .draw_b(draw_b),
    .pix_r(pix_r),
    .pix_g(pix_g),
    .pix_b(pix_b),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .hsync(hsync),
    .vsync(vsync)
);

endmodule

