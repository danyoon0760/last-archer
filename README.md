# Last Archer

A small Godot 4 top-down archer action RPG prototype.

Current prototype features:

- Right-click movement
- Left-click bow shooting
- Enemy dummies with HP bars
- Enemies chase the player and deal melee damage
- Player HP bar
- E key dodge roll / dash
- R key restart after death
- Room / town / dungeon map switching with 1 / 2 / 3 keys
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
- 1: load room map
- 2: load town map
- 3: load dungeon map

## Fast blockout workflow

Use this before making real art.

1. Open `scenes/RoomMap.tscn`, `scenes/TownMap.tscn`, or `scenes/DungeonMap.tscn`.
2. Drag `scenes/BlockoutRect.tscn` from the FileSystem panel into the 2D viewport.
3. Move it with the mouse.
4. Duplicate it with Ctrl+D.
5. Resize it by changing `size` in the Inspector, or by scaling the node in the 2D viewport.
6. Keep `solid` on when it should block the player. Turn `solid` off when it is only a visual guide.

Recommended first-pass layout order:

1. Room: bed, desk, computer area, exit.
2. Town: player house, shop, guild/quest board, dungeon gate, main road.
3. Dungeon: arena boundary, pillars, choke points, boss area, reward chest area.

Do not polish art during blockout. Use ugly large rectangles until the movement and combat space feels correct.
