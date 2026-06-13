# Last Archer

A small Godot 4 top-down archer action RPG prototype.

The playable loop now starts from town. The old room map is no longer part of the runtime loop; the room/backstory will be handled as an intro cutscene later.

Current prototype features:

- Right-click movement
- Left-click bow shooting
- Enemy dummies with HP bars
- Enemies chase the player and deal melee damage
- Player HP bar
- E key dodge roll / dash
- R key restart after death
- Town / dungeon map switching
- Long left-to-right dungeon road blockout
- Three inactive enemy packs per stage
- Stage clear reward multiplier and continue/return choice
- Rough inventory/equipment/augment overlay
- Placeholder intro cutscene scene
- Rough blockout rectangle scene for fast map layout work

## How to open

1. Clone this repository.
2. Open the folder in Godot 4.6 or newer.
3. Run `scenes/Main.tscn` or press Play.

## Current controls

- Right Mouse Button: move to cursor position
- Left Mouse Button: shoot arrow toward cursor
- A + Right Mouse Button: attack move
- S: stop
- H: hold position
- Q: temporary attack speed buff
- W: spread shot
- E: dodge roll / dash toward cursor
- R: ultimate shot / restart after death
- 1: load town map
- 2: load dungeon map
- T: open/close temporary town UI
- I or Tab: open/close inventory overlay

## Runtime structure

The current runtime loop is:

Town
-> prepare / temporary town UI
-> enter dungeon
-> clear three enemy packs
-> choose continue or return to town

Continuing directly increases the next reward multiplier. Returning to town resets the streak and allows preparation.

The intro room is no longer a playable map in the main loop. Use `scenes/IntroCutscene.tscn` later for the bedroom / League rage / isekai transfer opening.

## Fast blockout workflow

Use this before making real art.

1. Open `scenes/TownMap.tscn` or `scenes/DungeonMap.tscn`.
2. Drag `scenes/BlockoutRect.tscn` from the FileSystem panel into the 2D viewport.
3. Move it with the mouse.
4. Duplicate it with Ctrl+D.
5. Resize it by changing `size` in the Inspector, or by scaling the node in the 2D viewport.
6. Keep `solid` on when it should block the player. Turn `solid` off when it is only a visual guide.

Recommended first-pass layout order:

1. Town: player house/inn, shop, restaurant, alchemy room, journal/archive, dungeon gate, main road.
2. Dungeon: long road, upper/lower walls, three enemy pack areas, pillars, choke points, boss area, reward chest area.

Do not polish art during blockout. Use ugly large rectangles until the movement and combat space feels correct.
