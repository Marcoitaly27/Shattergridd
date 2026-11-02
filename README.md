# SHATTERGRID · 0.2

A local two-player battlefield prototype for Godot 4. The suspended stone
platform, 64 worn tiles, 16 primitive statues, fog, lighting and fixed camera
from 0.1 are preserved. Version 0.2 adds selection, adjacent movement, alternating
turns and temporary captures. No external assets, plugins or packages are used.

## Open and play

Import `project.godot` in **Godot 4.3 or later**, then press **F5 / Play**.
Validated with Godot **4.6.3** using the Compatibility renderer.
The configured main scene is `scenes/main.tscn`; F6 also runs that scene directly.

If using GitHub Desktop: select this repository and `main`, click **Fetch origin**
and then **Pull origin** when offered. Choose **Repository → Show in Explorer**
to locate `project.godot` for import into Godot.

## Controls and temporary rules

- Player 1 (ash statues with square crowns) starts. Player 2 controls the darker
  slate statues with pointed hoods. Both players use the same mouse locally.
- Left-click a statue belonging to the active player to select it. A muted brass
  ring marks the selection. Clicking another friendly statue changes selection.
- Brass tile borders mark empty destinations; rust borders mark potential attacks.
- Every placeholder temporarily moves **exactly one square in any of eight
  directions**, including diagonals. This is a prototype rule, not a final roster
  or final movement system. Friendly occupied tiles are blocked.
- Click a marked tile, or the enemy on it, to move. The statue slides briefly to
  the tile. Occupancy commits immediately and input is locked during the tween;
  the turn changes only after the movement completes.
- A temporary capture simply removes the opposing placeholder. There is no
  cinematic combat, destruction, victory detection or end-of-game system yet.
- Click an invalid destination or outside the board to clear selection.
  **Esc** or **right-click** also cancel. Cancelling does not consume a turn.

The restrained label at the top shows `PLAYER 1 TURN` or `PLAYER 2 TURN`.
There are no camera controls. Stop and replay the scene to reset the match.

## Architecture

- `scripts/board/board_state.gd`: logical dimensions, coordinates and occupancy,
  independent of meshes and physics. It supports rectangular boards; visuals
  use the matching exported `board_dimensions` on the battlefield node.
- `scripts/board/battlefield.gd`: deterministic masonry, native picking surfaces,
  coordinate-to-position conversion and separate move-hint geometry. Original
  stone materials are never overwritten by selection or movement highlighting.
- `scripts/pieces/piece.gd`: unique ID, display name, owning army, coordinate,
  replaceable movement resource, configurable picking bounds and presentation
  hooks. `placeholder_visual.gd` owns only the temporary primitive appearance.
- `scripts/movement/adjacent_movement.gd`: isolated eight-direction prototype
  rule. Future characters can supply another Resource implementing
  `get_destinations(origin, army, board)`. GameManager filters its destinations
  against board bounds and friendly occupancy.
- `scripts/game/game_manager.gd`: selection, validation, move lock and local
  turn flow. `temporary_capture.gd` isolates placeholder removal for later combat.
- `scripts/interaction/board_interaction.gd`: mouse/keyboard input and physics
  picking, evaluated during the physics step. Tile bodies use layer 1 and piece
  bodies use layer 2; queries include both.
- `scripts/ui/turn_display.gd`: turn and selection text, driven by game signals.
- `scenes/main.tscn`: composition, 16 initially placed pieces, lighting, camera,
  controllers and minimal UI. Board and piece scenes remain separate.
- `materials/`, `environments/`: native procedural stone, hint colors and sky/fog.
- `assets/`, `effects/`: reserved for future original models, audio and effects.

The battlefield builds its meshes on load, including in the editor with `@tool`.
Generated children are not serialized. Reopen the scene after changing generation
code; do not hand-edit generated children. Random wear uses a fixed seed.
Initial coordinates in the main scene are authoritative at startup, after which
BoardState owns occupancy and updates each piece's `grid_coordinate` on a move.

To introduce a later statue, duplicate/inherit the piece scene and replace its
`Visuals` child with the model scene. Preserve the root's identity and state.
The piece root does not depend on primitive node paths or replace imported model
materials. A visual may optionally implement `set_army(int)`. Adjust the root's
`picking_height` and `picking_radius` for the new model; its own animations,
character effects and audio can live below `Visuals`. Final combat, destruction,
special abilities and movement types are intentionally not implemented here.

## Validation

Run from the repository root:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --quit-after 10
```

`battlefield_smoke.gd` retains the 0.1 checks: scene resources, all 64 tile
coordinates, 16 unique starting pieces, placement, silhouettes, perspective
framing, fog and key lighting. `interaction_smoke.gd` exercises a rectangular
logical board, all eight neighboring directions, occupancy rejection, actual
physics rays, mouse/key input routing, selection changes/cancellation, movement
resource replacement, tween completion, alternating turns and temporary capture.
It uses a nearby-enemy fixture to test capture without playing every intervening
turn. Both scripts return nonzero when a check fails.

Headless checks do not demonstrate rendered appearance. In a graphical Play
session, verify the full board remains visible, selected pieces and both hint
colors are readable, tiles near the edges can be clicked, statues slide smoothly,
and the turn label updates after every successful move. For a capture test,
advance opposing statues until they are neighbors and click the rust-marked
opponent. Its placeholder should disappear and the turn should change once.

On a cloud machine with a read-only home directory, first use writable paths:

```sh
export XDG_CACHE_HOME=/workspace/.cache
export XDG_CONFIG_HOME=/workspace/.config
export XDG_DATA_HOME=/workspace/.local/share
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
```

A graphical session requires a display. Editor-local socket permissions may also
be required in sandboxed environments. Rendering can vary slightly by GPU.
Multiplayer, AI, menus, final characters and advanced combat remain out of scope.
