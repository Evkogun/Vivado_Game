module zombie(
        input clk,
        input rst,
        input game_clk,
        input [5:0] player_loc_simple_x,
        input [4:0] player_loc_simple_y,
        output reg detected,
        input [10:0] curr_x,
        input [10:0] curr_y,
        input [109:0] bullet_x, // Checking collision of bullets with the zombie
        input [99:0] bullet_y,
//        output [11:0] rom_pixel_zombie_ui,
        output reg [12:0] zombie_computed_reg,
        input sprtclk,
        input [2:0] sound_state,
        input [10:0] START_X,
        input [9:0] START_Y,
        output reg [3:0] hit_timer,
        output reg zombie_attack,
        input [2:0] display_wave,
        output reg [4:0] score_count
    );
    
    reg [1:0] dir;
    reg [5:0] current_loc_x; // 26 * 45
    reg [4:0] current_loc_y;
    reg [7:0] seed_input;
    reg [5:0] abs_diff_x;
    reg [4:0] abs_diff_y;
    reg [5:0] counter; // game_clk to 1 cps
    reg counter_true;
    reg movetrue;
    reg [10:0] zom_x;
    reg [9:0] zom_y;
    reg [4:0] hit_count; // Counts the number of times the zombie has been hit by a bullet
    reg zombie_reset; 
    reg z_move_animation_true;
    
//    wire [7:0] randomiser;
    
    reg [4:0] circle_radius; // MAKE SURE TO INCREASE [] SIZE  
    reg [8:0] circle_radius_sq;
    reg [12:0] distance_squared; 
//    reg [12:0] zombie_computed_reg;
    reg [3:0] sprite_counter;
    reg [2:0] sprite_animation_stage;
    
    integer i; // Loop variable for bullet collision with zombie
    
//    parameter START_X = 13*6*2; // Start positions of the zombie
//    parameter START_Y = 13*6*2;
    parameter BULLET_RADIUS = 4; // Bullet hitbox size
    parameter BLK_SIZE_X = 24;
    parameter BLK_SIZE_Y = 24;
    parameter PIXEL_SCALE = 1;
    parameter AREA = BLK_SIZE_X * BLK_SIZE_Y;
    parameter ATTACK_RANGE = 2;
    
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            detected <= 0;
            counter <= 0;
            counter_true <= 0;
            zombie_attack <= 0;
          
        end else begin
            if (counter == 30) begin
                counter <= 0;
                counter_true <= 1;
            end else begin
                counter <= counter + 1;
                counter_true <= 0;
            end
            
            if (counter_true) begin
                // Compute the absolute differences
                abs_diff_x = (player_loc_simple_x > current_loc_x) ? 
                             (player_loc_simple_x - current_loc_x) : 
                             (current_loc_x - player_loc_simple_x); // was zom_x before (zom_x represents the pixelated position
                             
                abs_diff_y = (player_loc_simple_y > current_loc_y) ? 
                             (player_loc_simple_y - current_loc_y) : 
                             (current_loc_y - player_loc_simple_y);
                             
                // Compute the distance squared
                distance_squared = abs_diff_x * abs_diff_x + abs_diff_y * abs_diff_y;
                
                seed_input <= (distance_squared * current_loc_x / counter) % 256;
                 
                // Check if the player is within the circle
                if (distance_squared <= circle_radius_sq) begin
                    detected <= 1;
                    movetrue <= 1;
                end else begin
                    detected <= 0;
                    movetrue <= 0;
                end
                
                if (distance_squared <= ATTACK_RANGE) begin // Switches zombie_attack to 1 when the zombie is within close proximity
                    zombie_attack <= 1;
                end else begin
                    zombie_attack <= 0;
                end
                
                // Decide direction based on which axis is further from the player
                if (abs_diff_x >= abs_diff_y) begin
                    if (player_loc_simple_x > current_loc_x) begin
                        dir <= 2'b01; // Move right
                    end else begin
                        dir <= 2'b11; // Move left
                    end
                end else begin
                    if (player_loc_simple_y > current_loc_y) begin
                        dir <= 2'b10; // Move down
                    end else begin
                        dir <= 2'b00; // Move up
                    end
                end
                //end
            end
        end
    end
    
    always @(posedge game_clk or negedge rst) begin
        if (!rst || zombie_reset || display_wave) begin
            zom_x <= START_X;
            zom_y <= START_Y;
            hit_count <= 0;
            zombie_reset <= 0;
            z_move_animation_true <= (zombie_reset) ? z_move_animation_true:0;
            hit_timer <= 0;
            score_count <= (zombie_reset) ? score_count:0;
            
        end else begin
            // Check for bullet collisions
            for (i = 0; i < 10; i = i + 1) begin
                if ((bullet_x[11*i +: 11] >= zom_x - BULLET_RADIUS) && 
                    (bullet_x[11*i +: 11] <= zom_x + BLK_SIZE_X + BULLET_RADIUS) &&
                    (bullet_y[10*i +: 10] >= zom_y - BULLET_RADIUS) && 
                    (bullet_y[10*i +: 10] <= zom_y + BLK_SIZE_Y + BULLET_RADIUS)) begin
                    hit_count <= hit_count + 1; // Increment hit count
                    hit_timer <= 5'd15; // Highlight the zombie for 15 frames 
                    score_count <= (display_wave) ? 0:(score_count + (hit_count == 3));
                    zombie_reset <= (hit_count == 3); // Reset if hit 4 times
                end
            end
            
            
                // Countdown the hit timer
            if (hit_timer > 0) begin
                hit_timer <= hit_timer - 1;
            end
            
            if (movetrue) begin
                case(dir)            
                    2'b00: begin // up
                        if (zom_y > 11'd32) begin
                           zom_y <= zom_y -3;
                           z_move_animation_true <= 1;
                        end
                    end
                    2'b10: begin // down
                        if (zom_y < (11'd900 - 11'd16)) begin
                           zom_y <= zom_y + 3;
                           z_move_animation_true <= 1;
                        end
                    end
                    2'b01: begin // right
                        if (zom_x < 11'd1440) begin
                           zom_x <= zom_x + 3;
                           z_move_animation_true <= 1;
                        end
                    end
                    2'b11: begin // left
                        if (zom_x > 11'd4) begin
                           zom_x <= zom_x - 3;
                           z_move_animation_true <= 1;
                        end
                    end
                    default: begin
                        z_move_animation_true <= 0;
                    end
                endcase
            end
        end
    end
    
    
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            current_loc_x <= 13;
            current_loc_y <= 13;
        end else begin
            current_loc_x <= zom_x / 32;
            current_loc_y <= zom_y / 32;
        end
    end
    
    
    always @* begin
        zombie_computed_reg = 0;
        // Determine address based on sprite direction and position
        if (dir == 2'd0 || dir == 2'd2) begin
            if (zom_x <= curr_x && curr_x <= zom_x + BLK_SIZE_X * PIXEL_SCALE - 1 &&
                zom_y <= curr_y && curr_y <= zom_y + BLK_SIZE_Y * PIXEL_SCALE - 1) begin
                    
                case (dir)
                    2'd2: // Down
                        zombie_computed_reg = sprite_animation_stage * AREA 
                                        + ((curr_y - zom_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - zom_x)/PIXEL_SCALE);
                    2'd0: // Up
                        zombie_computed_reg = sprite_animation_stage * AREA 
                                        + (AREA - 1) 
                                        - (((curr_y - zom_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - zom_x)/PIXEL_SCALE));
                endcase
            end
        end else if (dir == 2'd1 || dir == 2'd3) begin
            if (zom_x <= curr_x && curr_x <= zom_x + BLK_SIZE_Y * PIXEL_SCALE - 1 &&
                zom_y <= curr_y && curr_y <= zom_y + BLK_SIZE_X * PIXEL_SCALE - 1) begin
                    
                case (dir)
                    2'd3: // Left
                        zombie_computed_reg = sprite_animation_stage * AREA + (AREA - 1)
                                        - ((curr_x - zom_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((curr_y - zom_y)/PIXEL_SCALE);
                    2'd1: // Right
                        zombie_computed_reg = sprite_animation_stage * AREA
                                        + ((curr_x - zom_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((BLK_SIZE_X - 1 - (curr_y - zom_y)/PIXEL_SCALE));
                endcase
            end
        end
    end
    
    
    always @* begin
        if (z_move_animation_true) begin // VERY IMPORTATNT, INJURED FRAMES ARE 7 AND 8
            case (sprite_counter)
                4'd0: sprite_animation_stage = 0;
                4'd1: sprite_animation_stage = 1;
                4'd2: sprite_animation_stage = 2;
                4'd3: sprite_animation_stage = 3;
                4'd4: sprite_animation_stage = 2;
                4'd5: sprite_animation_stage = 1;
                4'd6: sprite_animation_stage = 0;
                4'd7: sprite_animation_stage = 4;
                4'd8: sprite_animation_stage = 5;
                4'd9: sprite_animation_stage = 6;
                4'd10: sprite_animation_stage = 5;
                4'd11: sprite_animation_stage = 4;
                default: sprite_animation_stage = 0;
            endcase

        end else begin
            sprite_animation_stage = 0;
        end
    end
    
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            sprite_counter <= 0; 
        end
        else begin
            if (!z_move_animation_true) begin
                sprite_counter <= 0;  // Reset the sprite counter on reset or no movement
            end else if (sprite_counter == 4'd11) begin
                sprite_counter <= 0;
            end else begin
                sprite_counter <= sprite_counter + 1;  // Increment the counter
            end
        end
    end
    
    // Detection rate assignments
    
    always @* begin
        circle_radius <= sound_state * 4;
        circle_radius_sq <= circle_radius * circle_radius;
    end
    
    

    
//    Zombie_Animations Zombie_Animations (
//        .clka(clk),
//        .addra(zombie_computed_reg),
//        .douta(rom_pixel_zombie_ui)
//    );

endmodule
