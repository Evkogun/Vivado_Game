`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.12.2024 13:52:09
// Design Name: 
// Module Name: bullet_logic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Logic to handle bullet movement and initialization.
//
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module bullet_logic(
    input rst,
    input [1:0] sw,
    input [10:0] blkpos_x,       // Block position X (initial bullet position)
    input [9:0] blkpos_y,        // Block position Y (initial bullet position)
    input game_clk,
    input shoot_true,            // Signal indicating a shot has been fired
    input [1:0] sprite_direction, // Direction of the sprite

    output reg [109:0] bullet_x,  // Bullet positions (X-coordinates) as a 110-bit wire
    output reg [99:0] bullet_y,   // Bullet positions (Y-coordinates) as a 100-bit wire
    output reg shoot_flag,
    
    input move_animation_true
);

    wire [7:0] randomiser;

    // Internal arrays for storing bullet positions and velocities
    reg [10:0] bullet_x_array [0:9];  // Array for X positions of the 10 bullets
    reg [9:0] bullet_y_array [0:9];   // Array for Y positions of the 10 bullets
    reg active_flag [0:9];
    reg signed [9:0] bullet_velocity_x [0:9]; // Velocity in the X direction
    reg signed [9:0] bullet_velocity_y [0:9]; // Velocity in the Y direction
    reg loop;
    integer i; // Loop variable
    
    reg [3:0] next_bullet; // Points to the next bullet to activate
    reg signed [11:0] bullet_x_array_signed [0:9];
    reg signed [10:0] bullet_y_array_signed [0:9];
    reg [3:0] counter;
    reg [7:0] seed_input;
    reg [2:0] spread;
    reg [3:0] for_loop_ender;
    reg [3:0] shotgun_bullet_counter;
    reg [3:0] bullet_lifetime [0:9];

    
    parameter PIXEL_SCALE = 1;
    parameter SHOTGUN_LIFETIME = 3;
    
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            // Reset all bullets and velocities
            for (i = 0; i < 10; i = i + 1) begin
                bullet_x_array_signed[i] <= 11'd0;
                bullet_y_array_signed[i] <= 10'd0;
                active_flag[i] <= 0;
                bullet_velocity_x[i] <= 6'd0;
                bullet_velocity_y[i] <= 6'd0;
                
            end
            next_bullet <= 4'd0; // Reset pointer
            shotgun_bullet_counter <= 0;
            shoot_flag <= 0;
        end else begin
            // Bullet movement logic
            for (i = 0; i < 10; i = i + 1) begin
                if (active_flag[i]) begin
                    // Update position based on velocity
                    bullet_x_array_signed[i] <= bullet_x_array_signed[i] + bullet_velocity_x[i];
                    bullet_y_array_signed[i] <= bullet_y_array_signed[i] + bullet_velocity_y[i];
                    
                    if ((bullet_x_array_signed[i] > 850 && bullet_y_array_signed[i] < 215) || 
                        (bullet_x_array_signed[i] > 521 && bullet_y_array_signed[i] < 310) ||
                        (bullet_x_array_signed[i] > 618 && bullet_y_array_signed[i] < 406)) begin
                        
                        active_flag[i] <= 0;
                    end
                    
                    if (sw == 2'd2) begin
                        bullet_lifetime[i] <= bullet_lifetime[i] + 1;
                        if (active_flag[i]) begin
                            if (bullet_lifetime[i] >= SHOTGUN_LIFETIME || 
                                bullet_x_array_signed[i] > 11'd1429 || bullet_y_array_signed[i] > 10'd889 || 
                                bullet_x_array_signed[i] < 10'd0 || bullet_y_array_signed[i] < 10'd0) begin
                                active_flag[i] <= 0;
                            end
                        end
                    end
    
                    // Deactivate bullet if it moves off-screen
                    if (bullet_x_array_signed[i] > 11'd1429 || bullet_y_array_signed[i] > 10'd889 || bullet_x_array_signed[i] < 10'd0 || bullet_y_array_signed[i] < 10'd0) begin
                        active_flag[i] <= 0; // Bullet is off-screen, deactivate it
                    end
                end
            end
            case (sw)
                2'd1: begin
                    spread <= 2;
                    if (!shoot_true) begin
                        shoot_flag <= 1;
                    end
                end
                2'd2: begin
                    spread <= 4;
                    if (!shoot_true) begin
                        shoot_flag <= 1;
                    end
                    if (counter == 20) begin
                        counter <= 0;
                        shoot_flag <= 1;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                2'd3: begin
                    spread <= 1;
                    if (counter == 30) begin  // faster rifle
                        counter <= 0;
                        shoot_flag <= 1;
                    end else begin
                        counter <= counter + 1;
                    end
                end
                default: begin
                    spread <= 2;
                    if (counter == 5) begin
                        counter <= 0;
                        shoot_flag <= 1;
                    end else begin
                        counter <= counter + 1;
                    end
                end
            endcase

            
            if (shoot_true && !active_flag[next_bullet] && !move_animation_true) begin // When sprite is moving it is used as a speed boost 
                
                if (shoot_flag) begin
                    if (sw == 2'd2) begin // Shotgun selected
                        // Initialize the next bullet
                        bullet_x_array_signed[next_bullet] <= blkpos_x;
                        bullet_y_array_signed[next_bullet] <= blkpos_y;
                        active_flag[next_bullet] <= 1;
                        bullet_lifetime[next_bullet] <= 0; // Reset lifetime for shotgun bullets
        
                        // Assign velocity based on `shotgun_bullet_counter`
                        case (sprite_direction)
                            2'd0: begin // Up
                                bullet_x_array_signed[next_bullet] <= blkpos_x + 6 * PIXEL_SCALE;
                                bullet_y_array_signed[next_bullet] <= blkpos_y + 33 * PIXEL_SCALE;
                                bullet_velocity_x[next_bullet] <= (shotgun_bullet_counter - 2) * 10; // Left (-10), Straight (0), Right (+10)
                                bullet_velocity_y[next_bullet] <= 10'd40; // Consistent upward velocity
                            end
                            2'd1: begin // Right
                                bullet_y_array_signed[next_bullet] <= blkpos_y + 5 * PIXEL_SCALE;
                                bullet_x_array_signed[next_bullet] <= blkpos_x + 33 * PIXEL_SCALE;
                                bullet_velocity_x[next_bullet] <= 10'd40; // Consistent rightward velocity
                                bullet_velocity_y[next_bullet] <= (shotgun_bullet_counter - 2) * 10; // Left (-10), Straight (0), Right (+10)
                            end
                            2'd2: begin // Down
                                bullet_x_array_signed[next_bullet] <= blkpos_x + 7 * PIXEL_SCALE;
                                bullet_velocity_x[next_bullet] <= (shotgun_bullet_counter - 2) * 10; // Left (-10), Straight (0), Right (+10)
                                bullet_velocity_y[next_bullet] <= -10'd40; // Consistent downward velocity
                            end
                            2'd3: begin // Left
                                bullet_y_array_signed[next_bullet] <= blkpos_y + 13 * PIXEL_SCALE;
                                bullet_velocity_x[next_bullet] <= -10'd40; // Consistent leftward velocity
                                bullet_velocity_y[next_bullet] <= (shotgun_bullet_counter - 2) * 10; // Left (-10), Straight (0), Right (+10)
                            end
                        endcase
        
                        // Move pointer to the next bullet slot
                        next_bullet <= (next_bullet + 4'd1) % 4'd10;
                        shotgun_bullet_counter <= shotgun_bullet_counter + 1;
//                             Reset after 3 bullets are fired
                        if (shotgun_bullet_counter == 3) begin
                            shotgun_bullet_counter <= 0; // Reset counter
                            shoot_flag <= 0; // Reset shoot flag
                        end
                    end 
                    else begin                        
                        // Other weapons
                        for (i = 0; i < for_loop_ender; i = i + 1) begin
                        
                        // Initialize the next bullet
                            bullet_x_array_signed[next_bullet] <= blkpos_x;
                            bullet_y_array_signed[next_bullet] <= blkpos_y;
                            active_flag[next_bullet] <= 1;
                            seed_input = (bullet_x_array [next_bullet - 1] * next_bullet + 23 * (i + 1)) % 255; // i stuff was included to randomise between individual shotgun bullets
                
                            // Set velocity based on sprite direction
                            case (sprite_direction)
                                2'd0: begin // Up
                                    bullet_x_array_signed[next_bullet] <= blkpos_x + 6 * PIXEL_SCALE;
                                    bullet_y_array_signed[next_bullet] <= blkpos_y + 33 * PIXEL_SCALE;
                                    bullet_velocity_x[next_bullet] <= randomiser % (7 * spread / 2) - (3 * spread / 2);
                                    bullet_velocity_y[next_bullet] <= 10'd40;
                                end
                                2'd1: begin // Right
                                    bullet_y_array_signed[next_bullet] <= blkpos_y + 5 * PIXEL_SCALE;
                                    bullet_x_array_signed[next_bullet] <= blkpos_x + 33 * PIXEL_SCALE;
                                    bullet_velocity_x[next_bullet] <= 10'd40;
                                    bullet_velocity_y[next_bullet] <= randomiser % (7 * spread / 2) - (3 * spread / 2);
                                end
                                2'd2: begin // Down
                                    bullet_x_array_signed[next_bullet] <= blkpos_x + 7 * PIXEL_SCALE;
                                    bullet_velocity_x[next_bullet] <= randomiser % (7 * spread / 2) - (3 * spread / 2);
                                    bullet_velocity_y[next_bullet] <= - 10'd40;
                                end
                                2'd3: begin // Left
                                    bullet_y_array_signed[next_bullet] <= blkpos_y + 13 * PIXEL_SCALE;
                                    bullet_velocity_x[next_bullet] <= - 10'd40;
                                    bullet_velocity_y[next_bullet] <= randomiser % (7 * spread / 2) - (3 * spread / 2);
                                end
                            endcase
                
                            // Move pointer to the next bullet slot
                            next_bullet <= (next_bullet + 4'd1) % 4'd10;
                            shoot_flag <= 0;
                        end
                    end
                end
            end
        end
    end

    always @* begin
        if (sw == 2'd2) begin
            for_loop_ender = 5;
        end
        else begin
            for_loop_ender = 1;
        end
    end
    
    // Update bullet output registers
    always @* begin
        bullet_x = 110'd0;
        bullet_y = 100'd0;
        for (i = 0; i < 10; i = i + 1) begin
            if (active_flag[i]) begin
                bullet_x_array[i] = bullet_x_array_signed[i];
                bullet_y_array[i] = bullet_y_array_signed[i];
                bullet_x[11*i +: 11] = bullet_x_array[i];
                bullet_y[10*i +: 10] = bullet_y_array[i];
            end else begin
                bullet_x[11*i +: 11] = 11'd0;
                bullet_y[10*i +: 10] = 10'd0;
            end
        end
    end
     
    
    random_number random_number_bullet_inst(
        .clk(game_clk),
        .rst(rst),
        .seed(seed_input),
        .lfsr(randomiser)
    );

endmodule
