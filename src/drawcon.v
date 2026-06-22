`timescale 1ns / 1ps

module drawcon(
    input clk,
    input rst,
    input [1:0] sw,
    input [10:0] blkpos_x,
    input [9:0] blkpos_y,
    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b,
    input [10:0] curr_x,
    input [10:0] curr_y,
    
    input [1:0] dir,
    input move_animation_true,
    input shoot_true,
    input game_clk,
    input [5:0] player_loc_simple_x, // map divided into 16 * 16 squares 26*46
    input [4:0] player_loc_simple_y,
    output reg [2:0] display_wave
//    input [2:0] player_health
    
    );   

    reg [3:0] bg_r;
    reg [3:0] bg_g;
    reg [3:0] bg_b;
    
    reg [3:0] blk_r;
    reg [3:0] blk_g;
    reg [3:0] blk_b;
    reg [3:0] sprite_counter;
    reg [1:0] sprite_direction;
    reg [2:0] sprite_animation_stage;
    
    reg [3:0] blt_r;
    reg [3:0] blt_g;
    reg [3:0] blt_b;
    
    reg [3:0] print_r;
    reg [3:0] print_g;
    reg [3:0] print_b;
    
//    wire detected1, detected2, detected3;
//    wire zombie_attack_1, zombie_attack_2, zombie_attack_3;
    parameter BLK_SIZE_X = 33, BLK_SIZE_Y = 20;
    parameter AREA = 660;
    parameter PIXEL_SCALE = 1; 
    parameter BULLET_SIZE = 4;
    parameter NUM_ZOMBIES = 8;
    
    parameter GAME_OVER_SIZE_X = 36; // New width
    parameter GAME_OVER_SIZE_Y = 22; // New height
    parameter GAME_OVER_PIXEL_SCALE = 10; // Scale factor
    parameter GAME_OVER_X_START = (1440 - GAME_OVER_SIZE_X * GAME_OVER_PIXEL_SCALE) / 2; // 1440-36*10 = 1440-360 = 1080/2 = 540
    parameter GAME_OVER_Y_START = (900 - GAME_OVER_SIZE_Y * GAME_OVER_PIXEL_SCALE) / 2; // 900-22*10 = 900-220 = 680/2 = 340
    parameter GAME_OVER_AREA = GAME_OVER_SIZE_X * GAME_OVER_SIZE_Y;
    
    parameter WAVE_SIZE_X = 16; // New width
    parameter WAVE_SIZE_Y = 16; // New height
    parameter WAVE_PIXEL_SCALE = 10; // Scale factor
    parameter WAVE_X_START = (1440 - WAVE_SIZE_X * WAVE_PIXEL_SCALE) / 2;
    parameter WAVE_Y_START = (900 - WAVE_SIZE_Y * WAVE_PIXEL_SCALE) / 2;
    parameter WAVE_AREA = WAVE_SIZE_X * WAVE_SIZE_Y;
    
    parameter TITLE_SIZE_X = 48; // New width
    parameter TITLE_SIZE_Y = 21; // New height
    parameter TITLE_PIXEL_SCALE = 2; // Scale factor
    parameter TITLE_X_START = (1440 - TITLE_SIZE_X * TITLE_PIXEL_SCALE)/2 ; // 1344/2 = [672 768]
    parameter TITLE_Y_START = (900 - TITLE_SIZE_Y * TITLE_PIXEL_SCALE) - 15; // 868 - 15 = [853 895]
    parameter TITLE_AREA = TITLE_SIZE_X * TITLE_SIZE_Y;
    
    parameter SKULL_SIZE_X = 15; // New width
    parameter SKULL_SIZE_Y = 14; // New height
    parameter SKULL_PIXEL_SCALE = 2; // Scale factor
    parameter SKULL_X_START = (1440 - SKULL_SIZE_X * SKULL_PIXEL_SCALE) - 100 ; // [1310 1340]
    parameter SKULL_Y_START = (900 - SKULL_SIZE_Y * SKULL_PIXEL_SCALE) - 5; // [867 895]
    parameter SKULL_AREA = SKULL_SIZE_X * SKULL_SIZE_Y;
    
    parameter ID_SIZE_X = 40; // New width
    parameter ID_SIZE_Y = 14; // New height
    parameter ID_PIXEL_SCALE = 2; // Scale factor
    parameter ID_X_START = (1440 - ID_SIZE_X * ID_PIXEL_SCALE)/2 + 98 ; // [778 858]
    parameter ID_Y_START = (900 - ID_SIZE_Y * ID_PIXEL_SCALE) - 5; // [867 895]
    parameter ID_AREA = ID_SIZE_X * ID_SIZE_Y;
    
    parameter OUTPUT_SIZE_X = 7; // New width
    parameter OUTPUT_SIZE_Y = 11; // New height
    parameter OUTPUT_PIXEL_SCALE = 2; // Scale factor
    parameter OUTPUT_X_START = (1440 - OUTPUT_SIZE_X * OUTPUT_PIXEL_SCALE) - 5 ; // [1344 1440]
    parameter OUTPUT_Y_START = (900 - OUTPUT_SIZE_Y * OUTPUT_PIXEL_SCALE) - 5; // 858 - 5 = 853
    parameter OUTPUT_AREA = OUTPUT_SIZE_X * OUTPUT_SIZE_Y;

    wire zombie_attack [0:NUM_ZOMBIES-1]; //array done
    reg zombie_attack_total;
    reg [3:0] active_zombies;
    
    
    wire detected [0:NUM_ZOMBIES-1]; //array done
    // Random Number Generator Instances for Zombies
    wire [7:0] random_x [0:NUM_ZOMBIES-1]; // Random outputs for zombies
    wire [7:0] random_y [0:NUM_ZOMBIES-1];
    reg [10:0] zombie_start_x [0:NUM_ZOMBIES-1];  // Store X positions of zombies
    reg [9:0] zombie_start_y [0:NUM_ZOMBIES-1];  // Store Y positions of zombies\

    wire [3:0] hit_timer [0:NUM_ZOMBIES-1]; //array done
    reg [12:0] addr;
    wire [11:0] rom_pixel;


    // Pipeline registers for sprite ROM output
    reg [12:0] addr_reg;
    reg [11:0] rom_pixel_reg;
    
    reg [10:0] bullet_x_arr [0:9];
    reg [9:0] bullet_y_arr [0:9];
    wire [109:0] bullet_x;
    wire [99:0] bullet_y;
    
    // Score to calculate the number of zombies that have been killed
    reg [3:0] score;
    reg [4:0] score_count [0:NUM_ZOMBIES-1];
    wire [4:0] score_count_wire [0:NUM_ZOMBIES-1];
    parameter SCORE = 9;
    
    wire [11:0] rom_pixel_background;
    // Pipeline registers for background ROM output
    reg [18:0] bg_addr_reg;
    reg [11:0] rom_pixel_background_reg;

    
    reg [11:0] ui_addr_reg;
    reg [11:0] rom_pixel_ui_reg;
    wire [11:0] rom_pixel_ui;
    
    reg [12:0] health_ui_addr_reg;
    reg [11:0] rom_pixel_health_ui_reg;
    wire [11:0] rom_pixel_health_ui;
    reg [2:0] health_state;
    reg [6:0] health_timer; // Makes the health bar wait for 5 seconds before updating
    reg game_over; // Prevents player input when this flag is raised
    reg game_win;
    
    reg [12:0] sound_ui_addr_reg;
    reg [11:0] rom_pixel_sound_ui_reg;
    wire [11:0] rom_pixel_sound_ui;
    reg [2:0] sound_state;
    reg [2:0] sound_state_buffer;
    reg sound_stage_buffer;
    reg injure_player;

    parameter STATE_CALCULATE = 0;
    parameter STATE_UPDATE = 1;
    
    reg [11:0] rom_pixel_zombie_ui_reg [0:NUM_ZOMBIES-1]; //array
    wire [12:0] zombie_computed_reg [0:NUM_ZOMBIES-1]; // Outputs from zombies
    wire [11:0] rom_pixel_zombie_ui [0:NUM_ZOMBIES-1];

//    reg [$clog2(NUM_ZOMBIES)-1:0] active_zombie;  // Counter for cycling through zombies
//    reg [11:0] active_rom_pixel;                 // Holds the ROM output for the active zombie
    wire [12:0] zombie_computed_addr;

    wire shoot_flag;
    
    reg [11:0] wave_ui_addr_reg;
    reg [11:0] rom_pixel_wave_ui_reg;
    wire [11:0] rom_pixel_wave_ui;
    reg [3:0] wave_state;
    reg [3:0] wave_counter; // Keeps track of the current wave
    reg [3:0] wave_end_state;
//    reg [2:0] display_wave;
    reg [31:0] wave_timer; // Timer to count clock cyles
    
    // Title animation
    reg [12:0] title_ui_addr_reg;
    reg [11:0] rom_pixel_title_ui_reg;
    wire [11:0] rom_pixel_title_ui;
    
    // Skull animation
    reg [12:0] skull_ui_addr_reg;
    reg [11:0] rom_pixel_skull_ui_reg;
    wire [11:0] rom_pixel_skull_ui;
    
//     Student id animation
    reg [12:0] id_ui_addr_reg;
    reg [11:0] rom_pixel_id_ui_reg;
    wire [11:0] rom_pixel_id_ui;
    
//     Output animation
    reg [12:0] output_ui_addr_reg;
    reg [11:0] rom_pixel_output_ui_reg;
    wire [11:0] rom_pixel_output_ui;
//    reg [3:0] output_stage;
    
    parameter SPRTCLK_FREQ = 11; // Approximate frequency of sprtclk in Hz
    parameter ONE_MINUTE_CYCLES = 60 * SPRTCLK_FREQ; // Number of sprtclk cycles for 1 minute
    
    
    reg [12:0] end_screen_ui_addr_reg;
    reg [11:0] rom_pixel_end_screen_ui_reg;
    wire [11:0] rom_pixel_end_screen_ui;
    reg [3:0] end_screen_state;
    
    reg [12:0] animation_counter; // Counter for slowing down updates
    parameter ANIMATION_DELAY = 5; // Adjust this value for desired delay
       
    wire sprtclk;
    wire new_clk;
    
    reg game_over_counter;
    reg game_anim_dir;
    
    integer i;
    genvar j;
    genvar k;
    genvar m;
    

    // Compute sprite address combinationally
    reg [12:0] computed_addr;
    always @* begin
        computed_addr = 0;
        // Determine address based on sprite direction and position
        if (sprite_direction == 2'd1 || sprite_direction == 2'd3) begin
            if (blkpos_x <= curr_x && curr_x <= blkpos_x + BLK_SIZE_X * PIXEL_SCALE - 1 &&
                blkpos_y <= curr_y && curr_y <= blkpos_y + BLK_SIZE_Y * PIXEL_SCALE - 1) begin
                    
                case (sprite_direction)
                    2'd1: 
                        computed_addr = sprite_animation_stage * AREA 
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE);
                    2'd3: 
                        computed_addr = sprite_animation_stage * AREA 
                                        + (AREA - 1) 
                                        - (((curr_y - blkpos_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE));
                    default:
                        computed_addr = sprite_animation_stage * AREA 
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE) * BLK_SIZE_X 
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE);
                endcase
            end
        end else if (sprite_direction == 2'd0 || sprite_direction == 2'd2) begin
            if (blkpos_x <= curr_x && curr_x <= blkpos_x + BLK_SIZE_Y * PIXEL_SCALE - 1 &&
                blkpos_y <= curr_y && curr_y <= blkpos_y + BLK_SIZE_X * PIXEL_SCALE - 1) begin
                    
                case (sprite_direction)
                    2'd0: 
                        computed_addr = sprite_animation_stage * AREA
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE);
                    2'd2: 
                        computed_addr = sprite_animation_stage * AREA
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((BLK_SIZE_X - 1 - (curr_y - blkpos_y)/PIXEL_SCALE));
                    default:
                        computed_addr = sprite_animation_stage * AREA
                                        + ((curr_x - blkpos_x)/PIXEL_SCALE) * BLK_SIZE_X
                                        + ((curr_y - blkpos_y)/PIXEL_SCALE);
                endcase
            end
        end
    end
    
    // Compute background address combinationally
    reg [18:0] computed_bg_addr;
    always @* begin
        if (curr_x < 1440 && curr_y < 890 && curr_y >= 10) begin
            computed_bg_addr = (((curr_y / 2) > 4) ? (curr_y / 2 - 5) : 0) * 720 + (curr_x / 2);
        end else begin
            computed_bg_addr = 0;
        end
    end
    
    // Pipeline stage: Register addresses and ROM outputs
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            addr <= 0;
            addr_reg <= 0;
            rom_pixel_reg <= 0;
            
            bg_addr_reg <= 0;
            rom_pixel_background_reg <= 0;
            for (i = 0; i < NUM_ZOMBIES; i = i + 1) begin
                rom_pixel_zombie_ui_reg[i] <= 12'b0;
            end
        end else begin
            // Update addresses
            addr <= computed_addr;
            addr_reg <= addr;
            
            bg_addr_reg <= computed_bg_addr;
            
            // On the next cycle after setting addr_reg, rom_pixel is valid
            rom_pixel_reg <= rom_pixel;
            rom_pixel_background_reg <= rom_pixel_background;

//            rom_pixel_zombie_ui_reg[active_zombie] <= active_rom_pixel; // Stores the active ROM pixel output onto the appropriate register
            for (i = 0; i < NUM_ZOMBIES; i = i + 1) begin
                rom_pixel_zombie_ui_reg[i] <= rom_pixel_zombie_ui[i];
            end
        end
    end    
    

    always @(posedge clk or negedge rst) begin
        if(!rst || display_wave) begin
            blk_r <= 4'b0000;
            blk_g <= 4'b0000;
            blk_b <= 4'b0000;
            bg_r <= 4'b0000;
            bg_g <= 4'b0000;
            bg_b <= 4'b0000;
            zombie_attack_total <= 0;
            active_zombies <= 4;
        end else begin
            // Use rom_pixel_reg for sprite colors (delayed by one cycle)
            case (wave_counter)
                0: active_zombies <= 4; // Wave 1
                1: active_zombies <= 6; // Wave 2
                2: active_zombies <= 8; // Wave 3
                default: active_zombies <= 4; // Safety default
            endcase
           

            blk_r <= rom_pixel_reg[11:8];
            blk_g <= rom_pixel_reg[7:4];
            blk_b <= rom_pixel_reg[3:0];
            
            for (i = 0; i < active_zombies; i = i + 1) begin
                if (rom_pixel_zombie_ui_reg[i] != 0) begin
                    blk_r <= (hit_timer[i] > 0) ? 4'h8 : rom_pixel_zombie_ui_reg[i][11:8];
                    blk_g <= rom_pixel_zombie_ui_reg[i][7:4];
                    blk_b <= rom_pixel_zombie_ui_reg[i][3:0];
                end
            end 
            
            if (rom_pixel_reg == 0) begin
                if (rom_pixel_ui_reg != 0) begin // Doesn't matter if black is overidden as background colour is black
                    blk_r <= rom_pixel_ui_reg[11:8]; // Gun ui
                    blk_g <= rom_pixel_ui_reg[7:4];
                    blk_b <= rom_pixel_ui_reg[3:0];
                end else if (rom_pixel_health_ui_reg != 0) begin
                    blk_r <= rom_pixel_health_ui_reg[11:8];
                    blk_g <= rom_pixel_health_ui_reg[7:4];
                    blk_b <= rom_pixel_health_ui_reg[3:0];
                end else if (rom_pixel_sound_ui_reg != 0) begin
                    blk_r <= rom_pixel_sound_ui_reg[11:8];
                    blk_g <= rom_pixel_sound_ui_reg[7:4];
                    blk_b <= rom_pixel_sound_ui_reg[3:0];
                end 
            end

            
            // Bullets
            blt_r = 4'b0000;
            blt_g = 4'b0000;
            blt_b = 4'b0000;
            for (i = 0; i < 10; i = i + 1) begin
                if(bullet_x_arr[i] != 0) begin
                    if (bullet_x_arr[i] <= curr_x && curr_x < bullet_x_arr[i] + BULLET_SIZE &&
                        bullet_y_arr[i] <= curr_y && curr_y < bullet_y_arr[i] + BULLET_SIZE) begin
                        blt_r = 4'b1111; // Bullet color 
                        blt_g = 4'b0001;
                        blt_b = 4'b0001;
                    end 
                end
            end
            
            if(game_over || display_wave || game_win) begin // game_win was here
                bg_r <= rom_pixel_background_reg[11:8] >> 2;
                bg_g <= rom_pixel_background_reg[7:4] >> 2;
                bg_b <= rom_pixel_background_reg[3:0] >> 2;
            end else begin
                // Background from rom_pixel_background_reg
                bg_r <= rom_pixel_background_reg[11:8];
                bg_g <= rom_pixel_background_reg[7:4];
                bg_b <= rom_pixel_background_reg[3:0];
            end
            

        end
    end
    
    always @* begin
        if (curr_x >= 8 && curr_x < 40 && curr_y >= 873 && curr_y < 895) begin
            // Calculate the offset within the 32x22 UI
            ui_addr_reg = 704 * sw + ((curr_y - 873) * 32) + (curr_x - 8); // Adjust x-coordinate to start at 0
        end else begin
            ui_addr_reg = 0;  // Outside the UI area
        end
    end
    
    // Health animation
    always @* begin
        if (curr_x >= 48 && curr_x < 48 + 64 && curr_y >= 879 && curr_y < 879 + 16) begin
            // Calculate the offset within the 64x16 UI
            health_ui_addr_reg = 1024 * health_state + ((curr_y - 879) * 64) + (curr_x - 48); // Adjust x and y coordinates accordingly
        end else begin
            health_ui_addr_reg = 0;  // Outside the UI area 
            // This lets other sprites overwrite this file when it's null
        end
    end
    
    // Sound state
    always @* begin
        if (curr_x >= 128 && curr_x < 128 + 64 && curr_y >= 879 && curr_y < 879 + 16) begin
            // Calculate the offset within the 64x16 UI
            sound_ui_addr_reg = 1024 * sound_state + ((curr_y - 879) * 64) + (curr_x - 128); // Adjust x and y coordinates accordingly
        end else begin
            sound_ui_addr_reg = 0;  // Outside the UI area 
            // This lets other sprites overwrite this file when it's null
        end
    end
    
    // Waves
    always @* begin
       if (curr_x >= WAVE_X_START && curr_x < WAVE_X_START + WAVE_SIZE_X * WAVE_PIXEL_SCALE 
            && curr_y >= WAVE_Y_START && curr_y < WAVE_Y_START + WAVE_SIZE_Y * WAVE_PIXEL_SCALE) begin     
            // Calculate the offset within the 64x16 UI
            wave_ui_addr_reg = wave_state * WAVE_AREA
                                 + ((curr_y - WAVE_Y_START) / WAVE_PIXEL_SCALE) * WAVE_SIZE_X
                                 + ((curr_x - WAVE_X_START) / WAVE_PIXEL_SCALE);
        end else begin
            wave_ui_addr_reg = 0;  // Outside the UI area 
            // This lets other sprites overwrite this file when it's null
        end
    end
    
    // End screen UI
    always @* begin
        if (curr_x >= GAME_OVER_X_START && curr_x < GAME_OVER_X_START + GAME_OVER_SIZE_X * GAME_OVER_PIXEL_SCALE 
        && curr_y >= GAME_OVER_Y_START && curr_y < GAME_OVER_Y_START + GAME_OVER_SIZE_Y * GAME_OVER_PIXEL_SCALE) begin
            end_screen_ui_addr_reg = end_screen_state * GAME_OVER_AREA
                                 + ((curr_y - GAME_OVER_Y_START) / GAME_OVER_PIXEL_SCALE) * GAME_OVER_SIZE_X
                                 + ((curr_x - GAME_OVER_X_START) / GAME_OVER_PIXEL_SCALE);
        end else begin
            end_screen_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
    // Title 
    always @* begin
        if (curr_x >= TITLE_X_START && curr_x < TITLE_X_START + 48 * TITLE_PIXEL_SCALE 
        && curr_y >= TITLE_Y_START && curr_y < TITLE_Y_START + 21 * TITLE_PIXEL_SCALE) begin
            title_ui_addr_reg = TITLE_AREA
                                 + ((curr_y - TITLE_Y_START) / TITLE_PIXEL_SCALE) * TITLE_SIZE_X
                                 + ((curr_x - TITLE_X_START) / TITLE_PIXEL_SCALE);
        end else begin
            title_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
    // Skull
    always @* begin
        if (curr_x >= SKULL_X_START && curr_x < SKULL_X_START + 15 * SKULL_PIXEL_SCALE 
        && curr_y >= SKULL_Y_START && curr_y < SKULL_Y_START + 14 * SKULL_PIXEL_SCALE) begin
            skull_ui_addr_reg = SKULL_AREA
                                 + ((curr_y - SKULL_Y_START) / SKULL_PIXEL_SCALE) * SKULL_SIZE_X
                                 + ((curr_x - SKULL_X_START) / SKULL_PIXEL_SCALE);
        end else begin
            skull_ui_addr_reg = 0;  // Outside the UI area 
        end
    end
    
//   Student ID
    always @* begin
        if (curr_x >= ID_X_START && curr_x < ID_X_START + 40 * ID_PIXEL_SCALE 
        && curr_y >= ID_Y_START && curr_y < ID_Y_START + 14 * ID_PIXEL_SCALE) begin
            id_ui_addr_reg = ID_AREA
                                 + ((curr_y - ID_Y_START) / ID_PIXEL_SCALE) * ID_SIZE_X
                                 + ((curr_x - ID_X_START) / ID_PIXEL_SCALE);
        end else begin
            id_ui_addr_reg = 0;  // Outside the UI area 
        end
    end

//    Output
    always @* begin
        if (curr_x >= OUTPUT_X_START && curr_x < OUTPUT_X_START + 7 * OUTPUT_PIXEL_SCALE 
        && curr_y >= OUTPUT_Y_START && curr_y < OUTPUT_Y_START + 11 * OUTPUT_PIXEL_SCALE) begin
            output_ui_addr_reg = end_screen_state * OUTPUT_AREA
                                 + ((curr_y - OUTPUT_Y_START) / OUTPUT_PIXEL_SCALE) * OUTPUT_SIZE_X
                                 + ((curr_x - OUTPUT_X_START) / OUTPUT_PIXEL_SCALE);
        end else begin
            output_ui_addr_reg = 0;  // Outside the UI area 
        end
    end

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            // Reset other values
            rom_pixel_ui_reg <= 12'b0;
            rom_pixel_health_ui_reg <= 12'b0;
            rom_pixel_sound_ui_reg <= 12'b0;
            rom_pixel_wave_ui_reg <= 12'b0;
            rom_pixel_end_screen_ui_reg <= 12'b0;
            rom_pixel_skull_ui_reg <= 12'b0;
            rom_pixel_id_ui_reg <= 12'b0;
            rom_pixel_output_ui_reg <= 12'b0;
            rom_pixel_title_ui_reg <= 12'b0;
        end else begin
            // Update UI pixel data
            rom_pixel_ui_reg <= rom_pixel_ui;
            rom_pixel_health_ui_reg <= rom_pixel_health_ui;
            rom_pixel_sound_ui_reg <= rom_pixel_sound_ui;
            rom_pixel_wave_ui_reg <= rom_pixel_wave_ui;
            rom_pixel_end_screen_ui_reg <= rom_pixel_end_screen_ui;
            rom_pixel_skull_ui_reg <= rom_pixel_skull_ui;
            rom_pixel_id_ui_reg <= rom_pixel_id_ui;
            rom_pixel_output_ui_reg <= rom_pixel_output_ui;
            rom_pixel_title_ui_reg <= rom_pixel_title_ui;
        end
    end

    // Final pixel selection
    always @* begin // && !game_win
        if (rom_pixel_background == 12'h321 && !game_over && !display_wave && !game_win) begin // Checks if background is a tree trunk, if it is it overwrites the sprite
            print_r = rom_pixel_background[11:8];
            print_g = rom_pixel_background[7:4];
            print_b = rom_pixel_background[3:0];
        end else if (blt_r != 0) begin // red is the colour to show bullets exist
            print_r = blt_r;
            print_g = blt_g;
            print_b = blt_b;  
        end else if (blk_b != 0 || blk_g != 0 || blk_r != 0) begin // blue is the non null colour
            print_r = blk_r;
            print_g = blk_g;
            print_b = blk_b;
        end else if (rom_pixel_end_screen_ui_reg != 0 && (game_over || game_win)) begin // game_win was here
            print_r <= rom_pixel_end_screen_ui_reg[11:8];
            print_g <= rom_pixel_end_screen_ui_reg[7:4];
            print_b <= rom_pixel_end_screen_ui_reg[3:0];
        end else if (rom_pixel_wave_ui_reg != 0 && display_wave) begin
            print_r <= rom_pixel_wave_ui_reg[11:8];
            print_g <= rom_pixel_wave_ui_reg[7:4];
            print_b <= rom_pixel_wave_ui_reg[3:0];
        end else if (rom_pixel_title_ui_reg != 0) begin
            print_r <= rom_pixel_title_ui_reg[11:8];
            print_g <= rom_pixel_title_ui_reg[7:4];
            print_b <= rom_pixel_title_ui_reg[3:0];
        end else if (rom_pixel_skull_ui_reg != 0) begin
            print_r <= rom_pixel_skull_ui_reg[11:8];
            print_g <= rom_pixel_skull_ui_reg[7:4];
            print_b <= rom_pixel_skull_ui_reg[3:0];
        end else if (rom_pixel_output_ui_reg != 0) begin
            print_r <= rom_pixel_output_ui_reg[11:8];
            print_g <= rom_pixel_output_ui_reg[7:4];
            print_b <= rom_pixel_output_ui_reg[3:0];
        end else if (rom_pixel_id_ui_reg != 0) begin
            print_r <= rom_pixel_id_ui_reg[11:8];
            print_g <= rom_pixel_id_ui_reg[7:4];
            print_b <= rom_pixel_id_ui_reg[3:0];              
        end else begin
            print_r = 0;
            print_g = 0;
            print_b = 0;
        end 
        
    end
    

    always @* begin
        if (injure_player && health_timer[1]) begin
            sprite_animation_stage = 8;
        end else if (injure_player && !health_timer[1]) begin
            sprite_animation_stage = 9;
        end if (move_animation_true) begin // VERY IMPORTANT, INJURED SPRITE FRAMES ARE 8 AND 9, PLEASE INCLUDE
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
        if (shoot_true && shoot_flag && !move_animation_true) begin
            sprite_animation_stage = 7;
        end else if (shoot_true) begin
            sprite_animation_stage = 0;
        end
    end
    
    always @* begin
        for (i = 0; i < 10; i = i + 1) begin
            bullet_x_arr[i] = bullet_x[11*i +: 11];
            bullet_y_arr[i] = bullet_y[10*i +: 10];
        end
    end
    
    // Noise calculations
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            sound_state_buffer <= 0;
            sound_state <= 0;

        end else begin
            case (sound_stage_buffer) 
                STATE_CALCULATE: begin
                    if (move_animation_true && shoot_true) begin
                        sound_state_buffer <= sound_state_buffer + 2; // Sprinting adds 1
                    end else if (move_animation_true) begin
                        sound_state_buffer <= sound_state_buffer + 1; // Moving adds 1
                    end else if (shoot_true) begin
                        case (sw)
                            2'd0: begin
                                sound_state_buffer <= sound_state_buffer + 2; // Assult rifle is 2
                            end
                            2'd1: begin
                                sound_state_buffer <= sound_state_buffer + 1; // Pistol is 1
                            end
                            2'd2: begin
                                sound_state_buffer <= sound_state_buffer + 3; // Shotgun is 0
                            end
                            2'd3: begin
                                sound_state_buffer <= sound_state_buffer; // Knife adds no noise
                            end
                        endcase
                    end

                    sound_stage_buffer <= STATE_UPDATE;
                end 
                STATE_UPDATE: begin
                    sound_state <= sound_state_buffer;
                    sound_state_buffer <= 0;
                    sound_stage_buffer <= STATE_CALCULATE;
                end
            endcase
        end
    end
    
        
    always @(posedge sprtclk or negedge rst) begin
        if (!rst) begin
            sprite_direction <= 2'b00;  // Reset value
            health_state <= 0;
            health_timer <= 0;
            injure_player <= 0;
            wave_counter <= 0; // Start with the first wave
            wave_state <= 0;
            wave_end_state <= 4;
//            wave_timer <= 0; 
            display_wave <= 1; // Show wave animation from the start
            end_screen_state <= 3;
            game_over <= 0;
            game_win <= 0;
            animation_counter <= 0;
            score <= 0;
            game_over_counter <= 0;
            for (i = 0; i < NUM_ZOMBIES; i=i+1) begin
                score_count[i] <= 5'b0;
            end
            
        end else begin
            for (i = 0; i < NUM_ZOMBIES; i=i+1) begin
                score_count[i] <= score_count_wire[i];
            end
        
            score <= 0;
            for (i = 0; i < NUM_ZOMBIES; i=i+1) begin
                score <= (game_over) ? 0:score + score_count[i];
            end
//            if (wave_timer >= ONE_MINUTE_CYCLES - 1) begin
//                wave_timer <= 0; //Reset the timer after 1 minute
//                if (wave_counter < 2) begin
//                    wave_counter <= (game_over) ? 0:wave_counter + 1; // Move to the next wave
//                    display_wave <= (game_over) ? 0:1;
//                end else begin
//                    end_screen_state <= 0;
//                    game_win <= 1;
//                end
//            end else if (!display_wave) begin
//                wave_timer <= wave_timer + 1; // Increment the timer only when the wave animation is not being displayed

//            end
            
            if (score >= SCORE) begin
                score <= 0;
                if (wave_counter < 2) begin
                    wave_counter <= (game_over) ? 0:wave_counter + 1; // Move to the next wave
                    display_wave <= (game_over) ? 0:1;
                end else begin
                    end_screen_state <= 0;
                    game_win <= 1;
                end
            end

            // Wave and end screen updates
            case(wave_counter)
                0: wave_end_state = 3;
                1: wave_end_state = 9;
                2: wave_end_state = 13;
                default: wave_end_state = 4;
            endcase
            if (display_wave) begin                
                if (wave_state >= wave_end_state) begin
                    wave_state <= 0;
                    display_wave <= 0;
                end else begin
                    if(animation_counter >= ANIMATION_DELAY) begin
                        animation_counter <= 0;
                        wave_state <= wave_state + 1;
                    end else begin
                        animation_counter <= animation_counter + 1;
                    end
                end
            end 
            
            if (game_over_counter > 4) begin
                // For displaying game_over or game_win
                if (game_over) begin
                    if (end_screen_state == 5 || end_screen_state == 3) begin
                        game_anim_dir <= ~game_anim_dir;
                    end
                    if (game_anim_dir) begin
                        end_screen_state <= end_screen_state + 1;
                    end else begin
                        end_screen_state <= end_screen_state - 1;
                    end
                    
                end else if (game_win) begin
                    if (end_screen_state == 0 || end_screen_state == 2) begin
                        game_anim_dir <= ~game_anim_dir;
                    end
                    if (game_anim_dir) begin
                        end_screen_state <= end_screen_state + 1;
                    end else begin
                        end_screen_state <= end_screen_state - 1;
                    end

                end
                game_over_counter <= 0; 
            end else begin
                game_over_counter <= game_over_counter + 1; 
            end


            
            // ----------------------//
            
            sprite_direction <= dir;
            // TEMPORARY TO SHOW HEALTH ANIMATION WORKS
            if (health_state == 5) begin
                game_over <= (game_win) ? 0:1;
//                health_state <= 0;
            end
            else begin
                for(i = 0; i < active_zombies; i = i + 1) begin
                    if(zombie_attack[i]) begin
                        injure_player <= 1;
                        if(health_timer == 0) begin
                            health_state <= health_state + 1;
                            health_timer <= 25; // Reset timer for 5 seconds
                        end
                    end
                end
            end
            if (display_wave) begin
                health_state <= 0;
                health_timer <= 0;
            end
            
            if (health_timer > 0) begin
                health_timer <= health_timer - 1;
                injure_player <= 0;
            end 
        end
        
        
        if (!rst || !move_animation_true || game_over || display_wave || game_win) begin
            sprite_counter <= 0;  // Reset the sprite counter on reset or no movement
        end else if (sprite_counter == 4'd11) begin
            sprite_counter <= 0;
        end else begin
            sprite_counter <= sprite_counter + 1;  // Increment the counter
        end
    end
    
    // Assign random positions (scaled to the map range) for zombies
    
    always @* begin
        zombie_start_x[0] <= 11'd740;
        zombie_start_y[0] <= 11'd85;
        zombie_start_x[1] <= 11'd630;
        zombie_start_y[1] <= 11'd80;
        zombie_start_x[2] <= 11'd660;
        zombie_start_y[2] <= 11'd90;
        zombie_start_x[3] <= 11'd740;
        zombie_start_y[3] <= 11'd80;
        zombie_start_x[4] <= 11'd700;
        zombie_start_y[4] <= 11'd100;
        zombie_start_x[5] <= 11'd800;
        zombie_start_y[5] <= 11'd120;
        zombie_start_x[6] <= 11'd550;
        zombie_start_y[6] <= 11'd100;
        zombie_start_x[7] <= 11'd830;
        zombie_start_y[7] <= 11'd80;
        
        
//        if (!rst || display_wave) begin
//            for(i = 0; i < NUM_ZOMBIES; i = i + 1) begin
//                if(i < NUM_ZOMBIES / 2) begin
//                    zombie_start_x[i] <= 11'd630 + (11'd30 * i); //630
//                    zombie_start_y[i] <= 10'd80;
//                end else begin
//                    zombie_start_x[i] <= 11'd700; // 800
//                    zombie_start_y[i] <= 10'd80 + (11'd30 * i);
//                end
//            end

//        end else begin
//            for(i = 0; i < NUM_ZOMBIES; i = i + 1) begin
//                if(i < NUM_ZOMBIES / 2) begin
//                    zombie_start_x[i] <= 11'd600 + (11'd30 * i);
//                    zombie_start_y[i] <= 10'd80;
//                end else begin
//                    zombie_start_x[i] <= 11'd700; // before it was 730
//                    zombie_start_y[i] <= 10'd80 + (11'd30 * i); // before it was 100
//                end
//            end                                          
//        end
    end
      
         
    assign draw_r = (print_r != 4'b0000) ? print_r : bg_r;
    assign draw_g = (print_g != 4'b0000) ? print_g : bg_g;
    assign draw_b = (print_b != 4'b0000) ? print_b : bg_b;
    

    bullet_logic bullet_logic_inst
    (
        .rst(rst),
        .sw(sw),
        .blkpos_x(blkpos_x),
        .blkpos_y(blkpos_y),
        .game_clk(game_clk),
        .shoot_true(shoot_true),
        .sprite_direction(sprite_direction),
        .bullet_x(bullet_x),
        .bullet_y(bullet_y),
        .shoot_flag(shoot_flag),
        .move_animation_true(move_animation_true)
    );
    
    clk_conv clk_conv_inst
    (
        .clk(clk),
        .rst(rst),
        .sprtclk(sprtclk),
        .new_clk(new_clk)
    );
    
    Background_Final Background (
        .clka(clk),
        .addra(bg_addr_reg),
        .douta(rom_pixel_background)
    );
    
    Soldier_Frames Soldier_Frames (
        .clka(clk),
        .addra(addr_reg),
        .douta(rom_pixel)
    );
    
    Weapons_UI Weapons_UI (
        .clka(clk),
        .addra(ui_addr_reg),
        .douta(rom_pixel_ui)
    );
    
    Health_UI Health_UI (
        .clka(clk),
        .addra(health_ui_addr_reg),
        .douta(rom_pixel_health_ui)
    );
    
    Sound_UI Sound_UI (
        .clka(clk),
        .addra(sound_ui_addr_reg),
        .douta(rom_pixel_sound_ui)
    );
    
    Wave_UI Wave_UI (
        .clka(clk),
        .addra(wave_ui_addr_reg),
        .douta(rom_pixel_wave_ui)
    );
    
    Title Title (
        .clka(clk),
        .addra(title_ui_addr_reg),
        .douta(rom_pixel_title_ui)
    );
    
    studentid studentid (
        .clka(clk),
        .addra(id_ui_addr_reg),
        .douta(rom_pixel_id_ui)
    );
    
    skull skull (
        .clka(clk),
        .addra(skull_ui_addr_reg),
        .douta(rom_pixel_skull_ui)
    );
    
    output_1 output_1 (
        .clka(clk),
        .addra(output_ui_addr_reg),
        .douta(rom_pixel_output_ui)
    );
    
    
    
    YOUWIN_plus_GAMEOVER YOUWIN_plus_GAMEOVER (
        .clka(clk),
        .addra(end_screen_ui_addr_reg),
        .douta(rom_pixel_end_screen_ui)
    );
    
    // Random Number Generator Instances - To be removed
    generate
        for (j = 0; j < NUM_ZOMBIES; j = j + 1) begin : gen_random_number_instances
            random_number rand_x_inst(
                .clk(clk), 
                .rst(rst), 
                .seed(8'hAB + j*2),  // Adjust seed to vary for each instance
                .lfsr(random_x[j])
            );
            
            random_number rand_y_inst(
                .clk(clk), 
                .rst(rst), 
                .seed(8'hCD + j*2),  // Adjust seed to vary for each instance
                .lfsr(random_y[j])
            );
        end
    endgenerate

    generate
        for (k = 0; k < NUM_ZOMBIES; k = k + 1) begin : zombie_instances
            zombie zombie_inst (
                .clk(clk),
                .rst(rst),
                .game_clk(game_clk),
                .bullet_x(bullet_x),
                .bullet_y(bullet_y),
                .player_loc_simple_x(player_loc_simple_x),
                .player_loc_simple_y(player_loc_simple_y),
                .detected(detected[k]),
                .curr_x(curr_x),
                .curr_y(curr_y),
//                .rom_pixel_zombie_ui(rom_pixel_zombie_ui),
                .zombie_computed_reg(zombie_computed_reg[k]),
                .sprtclk(sprtclk),
                .sound_state(sound_state),
                .START_X(zombie_start_x[k]),
                .START_Y(zombie_start_y[k]),
                .hit_timer(hit_timer[k]),
                .zombie_attack(zombie_attack[k]),
                .display_wave(display_wave),
                .score_count(score_count_wire[k])
            );
        end
    endgenerate
    
    generate
        for (j = 0; j < NUM_ZOMBIES; j = j + 2) begin : zombie_render
            Zombie_Animations Zombie_Animations_inst (
                .clka(clk),
                .addra(zombie_computed_reg[j]),
                .douta(rom_pixel_zombie_ui[j]),  // Store ROM output for each zombie
                .clkb(clk),
                .addrb(zombie_computed_reg[j+1]),
                .doutb(rom_pixel_zombie_ui[j+1])
            );
         end
    endgenerate
    


endmodule
