`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.10.2022 17:29:52
// Design Name: 
// Module Name: tb_vga
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Testbench for VGA-based module with faster clock transitions
//              and dynamic button inputs for efficient simulation.
//
// Dependencies: game_top module
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//////////////////////////////////////////////////////////////////////////////////

module tb_vga();

reg clk;
reg rst;
reg [2:0] sw;
reg [4:0] btn;

wire [3:0] pix_r, pix_g, pix_b;  // Pixel outputs
wire hsync, vsync;               // VGA sync signals
wire sprtclk;                    // Sprite clock (debug)
wire clk_out;                    // Debug clock output
wire sound_out;                  // Sound output

initial begin
    clk = 0;
    rst = 0;
    sw  = 3'b000;
    btn = 5'b00000;
    #100 rst = 1;  // Release reset after 100 ns
end

// Clock generation: faster for simulation
always #1 clk = ~clk;  // Toggle every 1 ns => 500 MHz clock for testing purposes

// Button Input Sequence
initial begin
    #200 btn = 5'b00010;  // Left
    #400 btn = 5'b00000;  // Release button
    
    #200 btn = 5'b01000;  // Up
    #400 btn = 5'b00000;  // Release button
    
    #200 btn = 5'b00001;  // Down
    #400 btn = 5'b00000;  // Release button
    
    #200 btn = 5'b10000;  // Bullet
    #400 btn = 5'b00000;  // Release button
    
    #2000;  // Wait before stopping simulation
    $stop;  // Stop the simulation
end

// DUT instantiation
game_top game_top_inst(
    .clk(clk),
    .rst(rst),
    .sw(sw),
    .btn(btn),
    .pix_r(pix_r),
    .pix_g(pix_g),
    .pix_b(pix_b),
    .hsync(hsync),
    .vsync(vsync),
    .sound_out(sound_out)
); 

// Monitor Outputs
initial begin
    $monitor("Time: %t | Button Input: %b | Collision Address: %d | Collision Vision: %b", 
    $time, btn, game_top_inst.collision_addr, game_top_inst.collision_vision);
end

// VCD Dump for waveform analysis
initial begin
    $dumpfile("tb_vga.vcd");   // Dump waveform to file
    $dumpvars(0, tb_vga);      // Monitor all variables in tb_vga
end

endmodule
