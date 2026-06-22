# Project Deathless Dusk

I built this as a Verilog FPGA game for the ES2E3 Digital Systems Design assignment at Warwick.

The aim was to make a small hardware-based zombie survival game rather than a simple VGA demo. The design uses VGA output, sprite ROMs, game-state logic, collision checks, weapon logic, zombie movement and microphone input.

The GitHub version currently contains the VGA/player-rendering part of the project:

```text
drawcon.v
game_top.v
vga.v
Correct_Sprite_Frames/
```

## What I built

- VGA display output at 1440 x 900
- COE-based sprite storage using Vivado block memory
- animated player sprites
- button-based player movement
- background and UI rendering logic
- zombie detection and movement logic
- bullet and weapon behaviour
- wave progression and scoring
- microphone-based noise detection
- waveform and gameplay testing

## Game idea

The game is a top-down zombie survival game.

The player progresses through five waves. Each wave increases the difficulty by adding zombies or increasing zombie health. The player can choose between four weapons:

- assault rifle - balanced range, spread, sound and fire rate
- pistol - longer range, lower sound and lower spread
- shotgun - high spread, high sound and short range
- knife - no sound and no spread

Noise is part of the game logic. Sprinting or using louder weapons increases the zombie detection radius. This made the game less about only shooting and more about balancing movement, weapon choice and positioning.

## Main modules

### `vga.v`

Generates the VGA timing signals and current pixel coordinates.

It handles:

- horizontal and vertical counters
- active display region
- `hsync` and `vsync`
- RGB output during visible pixels

### `drawcon.v`

Handles sprite and background drawing.

It checks the current VGA pixel position, calculates the sprite ROM address and outputs the correct 12-bit RGB value. Sprite frames are stored in block memory using `.coe` files.

### `game_top.v`

Connects the main modules together.

It handles:

- clock generation
- player position
- button input
- linking the VGA controller to the drawing logic

## Sprite and memory work

I made the sprites and maps in Piskel, then converted exported C-style pixel data into Vivado `.coe` files using MATLAB.

The design uses block memory ROMs for sprite frames. Different sprites are selected through address calculation and animation counters. Some sprites are scaled or flipped depending on direction.

## Zombie logic

The zombie logic compares simplified player and zombie coordinates. A sound level is converted into a detection radius, then compared against the squared distance between the zombie and player.

The zombies do not instantly turn towards the player. Their detection logic runs on a slower clock, which makes them overshoot slightly and makes the movement feel less robotic.

## Bullet and weapon logic

Bullet behaviour depends on the selected weapon.

The system calculates:

- starting position from the player sprite and facing direction
- bullet velocity
- spread
- range
- sound output
- active bullets on screen

Up to 10 bullets can be active at once. Their coordinates are passed into the drawing and collision logic.

## Microphone input

I used the Nexys A7 microphone to add sound-based interaction.

The microphone logic samples the PDM signal and stores the highest value over a short time window. This value is used as a rough noise level for gameplay.

## Testing

I tested the design using both simulation waveforms and gameplay testing.

The main waveform tests covered:

- zombie detection radius
- zombie tracking behaviour
- weapon firing behaviour
- bullet spread and range
- edge cases found during testing

A few bugs were found through testing and kept where they made the game more interesting, such as a shotgun-to-knife switch interaction.

## Known issues

The project worked, but there are things I would improve:

- replace some wide bullet-to-zombie signal passing with RAM or a cleaner shared structure
- improve zombie collision with the map
- add more automated assertions to the testbenches
- clean up some clock/reset logic
- package the Vivado project more cleanly
- include the full project code, not just the VGA/player-rendering snapshot

## What I learned

This project gave me much stronger experience with:

- Verilog module design
- VGA timing
- FPGA block memory
- COE file generation
- sprite rendering
- hardware game logic
- multi-clock debugging
- testbench waveform analysis
- designing around FPGA resource limits

## AI disclosure

This README was drafted with AI assistance from my original project report and code.
