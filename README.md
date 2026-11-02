# SHATTERGRID · 0.3

A local two-player battlefield prototype for Godot 4. The suspended stone
platform, 64 worn tiles, 16 primitive statues, fog, lighting and fixed camera
from 0.1 are preserved. Version 0.3 adds six distinct character silhouettes and
reusable archetype data on top of the selection, adjacent movement, alternating turns and temporary
captures from 0.2. No external assets, plugins or packages are used.

## Open and play

Import `project.godot` in your **Godot 4** editor, then press **F5 / Play**.
The repository retains your Godot 4.7 project metadata and animation compatibility
setting. Runtime validation here uses Godot **4.6.3** and Compatibility rendering.
The configured main scene is `scenes/main.tscn`; F6 also runs that scene directly.

If using GitHub Desktop: select this repository and `main`, click **Fetch origin**
and then **Pull origin** when offered. Choose **Repository → Show in Explorer**
to locate `project.godot` for import into Godot.

## Controls and temporary rules

- Player 1 (weathered ash stone) starts. Player 2 controls the darker
  slate statues. Both armies use the same six prototype silhouettes. Both players
  use the same mouse locally.
- Left-click a statue belonging to the active player to select it. A muted brass
  outline around its architectural base marks the selection. Clicking another
  friendly statue changes selection.
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

## Prototype characters

These are **recognition and scale studies**, not final character art or final
roster balance. Each model uses 6–10 native primitives, an architectural stone
base and no external assets. The two armies differ by muted stone palette and
face one another; crowns and pointed team hats have been removed.

| Archetype | Dominant temporary silhouette |
| --- | --- |
| Core | Tall symmetrical shrine, open pointed arch, pillars and a bound figure |
| Warden | Broad armored mass and a large offset shield |
| Hunter | Lean forward body with a dominant crossbow shape |
| Executioner | Heavy upper body and a large asymmetric raised axe |
| Witch | Tall narrow robe, restrained arms and a crooked forked branch; no pointed hat or broom |
| Wyrm | Low elongated body, reptilian head, folded wings, horns and a tail |

Each eight-piece army currently demonstrates all six archetypes, with Hunter and
Warden repeated: Warden, Hunter, Executioner, Core, Witch, Wyrm, Hunter, Warden.
This retains the 16-piece, opposite-edge test layout; it is **not a final roster**.
Movement and capture retain the prototype 0.2 rules. There is no Hex ability,
Core victory condition, unique attack rule or character-specific cinematic animation yet.

The fixed camera has been raised slightly to make the taller shrine readable
without blocking empty tile centers. No free-camera controls were introduced.

## Architecture

- `scripts/board/board_state.gd`: logical dimensions, coordinates and occupancy,
  independent of meshes and physics. It supports rectangular boards; visuals
  use the matching exported `board_dimensions` on the battlefield node.
- `scripts/board/battlefield.gd`: deterministic masonry, native picking surfaces,
  coordinate-to-position conversion and separate move-hint geometry. Original
  stone materials are never overwritten by selection or movement highlighting.
- `scripts/pieces/character_definition.gd`: typed shared Resource containing the
  archetype ID, display name, lore, replaceable model scene, movement resource and
  optional team material palette. Six definitions live in `resources/characters/`.
- `scripts/pieces/piece.gd`: per-instance ID, owning army, coordinate and optional
  name/movement overrides. `get_display_name()` and `get_movement_behavior()`
  resolve shared archetype data without character branches in GameManager.
- `scripts/pieces/placeholder_visual.gd`: loads the character model, applies its
  optional team palette, or preserves authored materials when the palette is
  empty. Each of the six models is an independently editable scene under
  `scenes/pieces/characters/`. Native compound picking follows primitive parts,
  including weapons and low bodies, instead of a generic tall cylinder.
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

To introduce a later statue, duplicate a character definition, assign its model
scene and movement resource, and reference it from a piece's `character_definition`.
Leave `team_materials` empty to preserve a future model's authored materials.
The per-instance `piece_id`, army and coordinate remain unchanged when its model
is replaced. The prototype wrapper generates compound picking from each primitive
part; a complex imported model should provide a simpler custom picking setup
through the existing piece presentation hook instead of per-detail collisions.

`Visuals/Model/PickAnchor` identifies a visible point for picking checks and can
later be used as a presentation target. When replacing `Visuals` entirely, its
`set_character`, `set_army`, `create_picking_body` and `get_pick_point` hooks are
optional. The piece retains a simple configurable picking fallback. Model-specific
AnimationPlayers, audio and effects can live under the model. `Piece.animate_to`
and the isolated temporary capture handler are the current replacement points
for future motion and cinematic execution. No empty ability, animation or audio
systems have been added just to reserve future fields.

## Validation

Run from the repository root:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/character_smoke.gd
godot --headless --path . --quit-after 10
```

`battlefield_smoke.gd` retains the 0.1 checks: scene resources, all 64 tile
coordinates, 16 unique starting pieces, placement, character models and team
materials, perspective framing, fog and key lighting. `interaction_smoke.gd` exercises a rectangular
logical board, all eight neighboring directions, occupancy rejection, actual
physics rays, mouse/key input routing, selection changes/cancellation, movement
resource replacement, tween completion, alternating turns and temporary capture.
It uses a nearby-enemy fixture to test capture without playing every intervening
turn. `character_smoke.gd` checks all six model resources, per-tile footprints,
actual geometry framing, team palettes, data resolution, live model replacement
and preservation of authored materials. All three scripts report their executed
check count and return nonzero when a check fails.

Headless checks do not demonstrate rendered appearance. In a graphical Play
session, verify the full board remains visible, selected pieces and both hint
colors are readable, tiles near the edges can be clicked, statues slide smoothly,
and the turn label updates after every successful move. Confirm you can identify
Core, Warden, Hunter, Executioner, Witch and Wyrm by their shape at the normal
camera distance; the selected character's name appears in the existing turn
panel. For a capture test,
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
