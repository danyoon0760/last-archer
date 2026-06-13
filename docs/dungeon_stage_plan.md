# Dungeon Stage Plan

## Core direction

The dungeon is no longer a pure endless wave arena.

Each dungeon stage is a long horizontal encounter map:

- Player starts on the left.
- Three enemy packs are placed across the stage.
- Each pack stays inactive at first.
- When the player hits one enemy in a pack, that whole pack wakes up and attacks.
- Clearing all three packs wins the stage.

This creates a ranged marksman rhythm: scout, poke, kite, clear, move forward, repeat.

## Recommended total scope

For a solo prototype, build about 10 stages total, split across 3 large themes.

Do not make 10 stages per theme at first. That would become 30 stages and is too large before the combat loop is proven.

Recommended split:

1. Theme 1: Cave / Beginner Labyrinth - Stages 1 to 3
2. Theme 2: Ruined Underground Road - Stages 4 to 6
3. Theme 3: Deep Abyss / Ancient Core - Stages 7 to 10

## Per-stage structure

Each stage has exactly three encounter packs.

Stage start
-> Pack 1
-> short breathing space
-> Pack 2
-> short breathing space
-> Pack 3
-> victory / chest / return-or-descend decision

## Encounter pack behavior

Enemies in a pack should be configured like this:

- start_inactive = true
- encounter_id = wave_1, wave_2, or wave_3

If the player hits any enemy in wave_1, every enemy with encounter_id wave_1 activates.
Enemies in wave_2 and wave_3 stay inactive until directly hit.

## Why this structure fits the game

This is better than spawning enemies directly on top of the player because:

- The player can choose when to start each fight.
- The archer fantasy feels stronger because the player initiates with a shot.
- The map layout matters more.
- Kiting lanes, pillars, corners, and retreat paths become meaningful.
- The stage has a clear start and end.

## Anti-cheese rules to add later

The player should not be able to hit a pack once and run forever.

Add these later if needed:

- leash_radius: enemies return to spawn if pulled too far.
- pack gate: after activating a pack, temporary fog/walls prevent skipping.
- reward lock: next pack reward/chest only opens after current pack is dead.
- ranged enemies in later stages to punish infinite backpedaling.

## Stage theme plan

### Theme 1: Cave / Beginner Labyrinth

Purpose: teach movement, shooting, and pack activation.

Stage 1:
- Pack 1: 3 slimes
- Pack 2: 4 slimes
- Pack 3: 4 slimes + 1 heavy slime

Stage 2:
- Pack 1: 3 slimes + 1 rat
- Pack 2: 4 slimes + 2 rats
- Pack 3: 2 heavy slimes + 3 slimes

Stage 3:
- Pack 1: rats pressure the player
- Pack 2: mixed slime wall
- Pack 3: mini-boss slime pack

### Theme 2: Ruined Underground Road

Purpose: add obstacles and kiting decisions.

Stage 4:
- Wider arena sections
- Pillars in the center
- Packs placed behind ruins

Stage 5:
- More fast enemies
- Narrow choke areas
- First dangerous ranged enemy later

Stage 6:
- Mini-boss stage
- Pack 3 is a reinforced group

### Theme 3: Deep Abyss / Ancient Core

Purpose: make the player commit to deeper runs.

Stage 7:
- More enemy variety
- Harder pack formations

Stage 8:
- Split paths and awkward kiting angles

Stage 9:
- High-pressure enemy packs
- Punishes bad E usage

Stage 10:
- Final prototype stage
- Three packs plus boss/chest encounter

## Blockout rules

Use ugly rectangles first.

For each stage, place only:

- main path
- walls
- obstacles
- three enemy pack areas
- player spawn
- victory chest / exit

Do not draw final art until stage movement feels good.

## Immediate implementation target

Create one test stage first:

- One long horizontal dungeon lane.
- Three red enemy packs.
- Each pack uses start_inactive and encounter_id.
- Player starts on the left.
- Clearing all enemies means stage clear.

Only after this feels good, make stages 2 to 10.
