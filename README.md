# Project Deathless Dusk

I built this as a Verilog FPGA zombie survival game for the ES2E3 Digital Systems Design assignment at Warwick.

The project runs on a Nexys A7-style FPGA board and outputs the game through VGA. I wanted it to be more than a basic sprite demo, so I added enemies, weapons, waves, collision, UI, health, sound/noise logic and animated sprites.

## Features

- 1440 x 900 VGA output
- player movement using board buttons
- animated player and zombie sprites
- COE-based sprite and background ROMs
- map collision using a ROM-backed collision grid
- multiple weapons selected with switches
- bullet movement, spread, range and hit detection
- zombie detection based on player noise
- wave progression with increasing zombie count
- health, weapon, sound, wave and end-screen UI
- game win/game over states
- waveform and gameplay testing

## Gameplay

The game is a top-down zombie survival game.

The player has to survive waves of zombies. Each wave increases the number of active zombies. Zombies detect the player based on a noise value, so sprinting and using louder weapons makes the player easier to find.

The weapons have different trade-offs:

| Weapon | Idea |
|---|---|
| Assault rifle | balanced range, spread, sound and fire rate |
| Pistol | lower sound and better control |
| Shotgun | high spread, high sound and short range |
| Knife | silent option |

## Main files

```text
game_top.v
drawcon.v
vga.v
zombie.v
clk_conv.v
random_number.v
bullet_logic.v
*.coe sprite/background/UI memory files
```

Some Vivado IP blocks are also needed, especially the clock wizard and block memory ROMs.

## Module overview

### `game_top.v`

This is the top-level module. It connects the VGA controller, drawing logic, player movement, collision memory and pixel clock together.

It also handles the player's position, direction, button input and the pipelined collision check. I used a small state machine so the collision address could be calculated, waited on, then read before movement was applied.

### `vga.v`

This generates the VGA timing.

It creates:

- horizontal and vertical counters
- `hsync`
- `vsync`
- current pixel coordinates
- RGB output during the active display area

### `drawcon.v`

This is the main rendering and game-state module.

It handles:

- player sprite drawing
- background drawing
- zombie rendering
- bullet rendering
- weapon UI
- health UI
- sound UI
- wave UI
- title and end screens
- score/wave progression
- game over and win states

The module uses block memory outputs for the background, sprites and UI, then decides which pixel should be shown at the current VGA coordinate.

### `zombie.v`

This handles zombie behaviour.

Each zombie tracks its own position, direction, animation state, hit count and attack state. The zombie compares its simplified position against the player's simplified position. If the squared distance is inside the current sound radius, it detects the player and moves towards them.

Zombie bullet collision is also checked here. When a zombie is hit enough times, it resets and increments the score count.

### `clk_conv.v`

This creates slower clocks for animation/game timing.

### `random_number.v`

This is an LFSR-based pseudo-random number generator. It was intended for randomised zombie behaviour or spawn variation.

## Sprite and memory workflow

I made the sprites and maps in Piskel, exported the pixel data, then converted it into Vivado `.coe` files using MATLAB.

The design uses ROMs for:

- player sprites
- zombie sprites
- background
- weapon UI
- health UI
- sound UI
- wave UI
- title/end screens

The player and zombie sprites use calculated ROM addresses so they can be animated and rotated/flipped depending on direction.

## Collision

The map is simplified into grid coordinates. The player's pixel position is converted into a simpler map position, then a collision ROM is checked before movement is applied.

I split this into address, wait, read and update stages because the memory output was not available in the same cycle.

## Noise and zombie detection

Noise is part of the gameplay.

The sound state increases when the player moves, sprints or shoots. Louder actions increase the zombie detection radius. The zombies compare their squared distance to this radius and start tracking the player when they detect them.

## Testing

I tested the project using waveform simulation and gameplay testing.

The main things I tested were:

- VGA timing
- sprite rendering
- player movement
- collision checks
- zombie detection radius
- zombie tracking
- bullet behaviour
- weapon differences
- wave progression
- game over/win states

## Issues I would improve

This was a coursework project, so there are still things I would clean up:

- replace wide bullet coordinate buses with a cleaner memory/shared structure
- improve zombie collision with the map
- remove old debug `$display` statements
- make clocking cleaner by using clock-enable pulses instead of generated clocks
- add more assertions to the testbenches
- package the Vivado project with clearer IP recreation steps
- tidy the ROM/IP names so the project is easier to rebuild

## What I learned

This project helped me improve at:

- Verilog module design
- VGA timing
- FPGA block memory
- sprite rendering
- COE file generation
- collision handling
- multi-clock debugging
- hardware game logic
- waveform testing
- working around FPGA resource and timing limits

## Build notes

This repository is not just plain Verilog. To rebuild it in Vivado, the generated IP blocks and `.coe` memory files need to be included.

At minimum, the project needs:

- clock wizard IP
- block memory generator IPs
- all sprite/background/UI `.coe` files
- board constraint file for the Nexys A7
- VGA, button, switch and clock pin mappings

## AI disclosure

This README was drafted with AI assistance from my original report and recovered Verilog files.
