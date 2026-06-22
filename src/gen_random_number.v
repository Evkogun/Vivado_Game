`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08.12.2024 15:10:24
// Design Name: 
// Module Name: random_number
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

// Generates a pseudo random 8 bit number

module random_number(
    input wire clk,           // Clock signal
    input wire rst,           // Reset signal
    input wire [7:0] seed,    // Seed input
    output reg [7:0] lfsr     // LFSR output
);
    wire feedback;

    // Feedback taps for x^8 + x^6 + x^5 + x + 1
    assign feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr <= seed; // Load the seed during reset
        end else begin
            lfsr <= {lfsr[6:0], feedback}; // Shift left and insert feedback
        end 
    end

endmodule
