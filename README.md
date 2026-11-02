# SHATTERGRID · 0.5

A local two-player battlefield prototype for Godot 4. The suspended stone
platform, 64 worn tiles, 16 primitive statues, fog, lighting and fixed camera
from 0.1 are preserved. Version 0.5 adds an independent medieval world: hanging
gothic foundations, a ruined lower settlement, chapel, fog and two ritual fires.
The six cinematic captures, Blood Step, Terror, Core victory and restart from 0.4
remain in place. No external assets, plugins or packages are used.

See [the 0.5 audit and visual report](docs/version_0_5.md) for actual feature state,
world composition, files, performance budgets and the manual review checklist.
Hex is not implemented; this visual pass does not invent new gameplay rules.

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
- A capture starts a short cinematic. Gameplay input stays locked through the
  camera return, then abilities resolve and the turn changes. Destroying the
  opposing Core ends the match only after its cinematic completes.
- Click an invalid destination or outside the board to clear selection.
  **Esc** or **right-click** also cancel. Cancelling does not consume a turn.

The restrained label at the top shows `PLAYER 1 TURN` or `PLAYER 2 TURN`.
There are no free-camera controls. **R** restarts a match, including during a
capture; **PLAY AGAIN** restarts after victory. In a debug/editor run, **Space**
fast-forwards an active capture while still executing every impact and resolution
event. There is no permanent skip button in the match UI.

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
Movement retains the provisional eight-direction rule from 0.2. Character models,
attack animation and destruction remain prototypes. There is no Hex ability or
final character movement roster.

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
- `scripts/game/game_manager.gd`: authoritative selection, validation and explicit
  READY / MOVING / CAPTURING / GAME_OVER / RESTARTING phases. Board occupancy
  changes at the shatter event; statuses, victory and turn resolution wait for
  camera restoration. The obsolete instant-removal helper has been retired.
- `scripts/interaction/board_interaction.gd`: mouse/keyboard input and physics
  picking, evaluated during the physics step. Tile bodies use layer 1 and piece
  bodies use layer 2; queries include both.
- `scripts/ui/turn_display.gd`: turn and selection text, driven by game signals.
- `scenes/main.tscn`: composition, 16 initially placed pieces, lighting, camera,
  controllers and minimal UI. Board and piece scenes remain separate.
- `scenes/world/` and `scripts/world/`: replaceable presentation-only arena shell,
  lower settlement, landmarks and two braziers. World objects have no gameplay
  collision or rule dependencies; repeated distant forms use MultiMesh.
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
and the character-owned `capture_behavior` Resource are the replacement points
for future motion and cinematic execution. No empty ability, animation or audio
systems have been added just to reserve future fields.

## Cinematic captures

| Attacker | Prototype sequence |
| --- | --- |
| Warden — The Bastion | Weighted withdrawal, grounded shield drive, recoil and heavy collapse |
| Hunter — The Final Hunt | Quick precise pass, silent beat, delayed cracking and destruction |
| Executioner — The Sentence | Threatening axe wind-up, downward chop, local hit pause and heavy debris |
| Witch — Wither | Stationary tilt, victim tremble, dark crack marks, contraction and inward collapse |
| Wyrm — Maul | Low crouch, sudden animal lunge, sideways maul and fracture |
| Core — The Unseen | Almost stationary shrine, invisible push/compression and quiet collapse |

Normal captures target roughly **1.7–2.0 seconds**, with a short additional hold
when the victim is a Core. One director-owned Tween contains the complete
sequence. Its monotonic presentation clock avoids stretching cinematic duration
when Godot caps frame delta on a slow renderer. It never changes
`Engine.time_scale`; hit pauses are local timeline holds of 0.06–0.10 seconds.
Critical holds are real presentation boundaries, so a slow frame cannot consume
the Hunter's silent beat and the delayed fracture in a single draw.

The camera saves its exact strategic transform, FOV, projection, near/far planes,
size, offsets, aspect mode and current state. A direction-relative side angle,
statue bounds and a small deterministic variation determine the closer framing.
The camera stays above the platform; the complete pair is fitted automatically.
It tests both side angles and raises the view when another statue obstructs the
confrontation, without a per-tile camera table.
Shake offsets are applied from a stable base pose, then cleared on exact restore.

At fracture, the original victim is hidden and removed from occupancy. It is
freed after the presentation completes. Destruction uses **7–8 native rigid-body
stone chunks**, or **12 for the Core**, with strong gravity, low bounce, tile
and platform-slab collisions. Debris uses collision layer 4 and cannot intercept
board picking.
Chunks may fall off the floating board; there is no distant invisible floor.
Muted CPU dust uses 16 particles, or 24 for a Core. The complete effect deletes
itself after 2.4 seconds, including its physics bodies and particles.

Responsibilities and extension points:

- `scripts/capture/capture_director.gd`: completion, lock interval and a single
  cancellable timeline; no ability or turn rules.
- `scripts/capture/camera_director.gd`: reusable fitted poses, blend, shake and
  exact state restoration.
- `scripts/capture/capture_context.gd`: per-capture snapshots, motion targets,
  fracture cues and cleanup; no attacker-victim combination tables.
- `scripts/capture/behaviors/` and `resources/captures/`: six independently
  replaceable character behaviors. `CharacterDefinition.capture_behavior`
  selects one; GameManager has no archetype-specific animation branches.
- `scripts/effects/stone_destruction.gd`: bounded temporary destruction and dust.
- `cue_emitted(event, attacker, victim)`: future spatial-audio/VFX hooks such as
  anticipation, weapon swing, stone impact, crack, debris, Wither, Wyrm impact
  and Core destruction. The prototype is intentionally silent; no audio is
  downloaded or represented by fake asset files.

Future authored AnimationPlayer clips can replace the behavior Resource's
`append(timeline, context)` implementation. Use timeline callbacks or authored
markers for impact/fracture, retain the completion contract, and reset authored
poses on recovery. Rigged models and AnimationTree are not required now. The
prototype axe uses a small native pivot, not a skeleton. Victims provide their
bounds, palette and reaction; six attacker styles work across victim types.
Models face local -Z; put imported orientation corrections inside Model so the
Visuals root can face the attack direction consistently. Audio listeners should
copy positions/IDs if retaining data after completion, since the victim is freed.

## Capture-triggered statuses

Statuses live independently on each piece. Their deadlines use **completed turns
of that piece's owner**, never seconds or animation duration. Shared status
Resources contain modifiers; `status_state.gd` stores per-piece start/expiry.
`movement_resolver.gd` composes and validates the resulting destinations.

- **Blood Step:** a successful Executioner capture grants four one-square
  diagonal options on its owner's next turn. It adds no extra action. Empty and
  enemy destinations are allowed, friendly destinations are blocked. It expires
  at the end of that owner turn even if another piece is played. A new capture
  refreshes the specific Executioner's bonus for the following turn; it does not
  stack. Since the current provisional base rule already includes diagonals,
  the union introduces no duplicate destinations. The runtime test also uses an
  orthogonal base rule to verify the additional options actually work.
- **Terror:** after a Wyrm capture, enemies on all eight adjacent tiles around
  its final tile become Terrified until the end of their owner's next turn.
  They retain empty legal moves but cannot capture. The destroyed victim is no
  longer in occupancy; allies and the Wyrm are excluded. Core definitions declare
  immunity. Reapplication refreshes one status rather than stacking copies.

`resources/abilities/` selects the two post-capture effects from character data.
They are applied after camera return, then Core victory is checked, then the
turn advances. A winning capture ends the match instead of handing over another
turn. The existing selected-piece panel displays active status names.

## Quick cinematic lab (optional)

To see every capture without advancing armies across the board:

1. Open `scenes/debug/capture_lab.tscn` in the Godot editor.
2. Press **F6** to run only that scene. F5 still runs the normal match.
3. Press **1–6** for Warden, Hunter, Executioner, Witch, Wyrm and Core.
4. Press **Enter** to replay, **C** to toggle a Core victim, or **Space** to
   fast-forward. **R** leaves the lab and starts a normal fresh match.

This separate developer scene contains nearby opponents for Terror checks and a
Core immune to it. It is never inserted into the normal match or its UI.

## Validation

Run from the repository root:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/character_smoke.gd
godot --headless --path . --script res://tests/capture_smoke.gd
godot --headless --path . --script res://tests/world_smoke.gd
godot --headless --path . --quit-after 10
```

`battlefield_smoke.gd` retains the 0.1 checks: scene resources, all 64 tile
coordinates, 16 unique starting pieces, placement, character models and team
materials, perspective framing, fog and key lighting. `interaction_smoke.gd` exercises a rectangular
logical board, all eight neighboring directions, occupancy rejection, actual
physics rays, mouse/key input routing, selection changes/cancellation, movement
resource replacement, tween completion, alternating turns and cinematic capture.
It uses a nearby-enemy fixture to test capture without playing every intervening
turn. `character_smoke.gd` checks all six model resources, per-tile footprints,
actual geometry framing, team palettes, data resolution, live model replacement
and preservation of authored materials. `capture_smoke.gd` runs every archetype's
actual timeline and verifies lock/event order, duration, impact-time occupancy,
framing including corners, exact camera/pose restoration, cleanup, both abilities,
Core victory ordering, repeated captures, fast-forward, restart during both early
and late capture phases, and the victory restart button. The new `world_smoke.gd`
checks collision-free scenery, shared-instance budgets,
vertical placement, cinematic clearance, native fog and picking, then removes the
entire world and verifies gameplay still works. All five scripts report executed
checks and return nonzero on failure.

Validation uses Godot 4.6.3 in the cloud, headless and with OpenGL Compatibility
rendering. See the visual report for the 0.5 checks; the earlier capture report
and scripts remain available for gameplay regressions. Testing on the local
Windows/Godot 4.7 GPU remains a manual
review of smoothness and appearance, not a claimed cloud result.

Headless checks do not demonstrate rendered appearance. In a graphical Play
session, verify the full board remains visible, selected pieces and both hint
colors are readable, tiles near the edges can be clicked, statues slide smoothly,
and the turn label updates after every successful move. Confirm you can identify
Core, Warden, Hunter, Executioner, Witch and Wyrm by their shape at the normal
camera distance; the selected character's name appears in the existing turn
panel. For a capture test,
advance opposing statues until they are neighbors and click the rust-marked
opponent. The cinematic should play before the turn changes once.

Manual review checklist:

- F5: ordinary moves, friendly blocking, both players and selection cancellation.
- Lab: all six identities, both actors visible, restrained shake/dust, no clipping.
- Hunter: destruction is delayed after the fast strike. Witch/Core: no physical
  charge before the victim collapses. Executioner: visible wind-up and axe chop.
- Core victim: destruction shot and camera return finish before victory appears.
- Wyrm: select an adjacent affected enemy on its next turn; empty moves remain
  available, enemy capture highlights do not. The nearby Core stays immune.
- Executioner: observe Blood Step on its next turn and its expiry after that turn.
  The default eight-direction rule already permits those diagonal destinations.
- Repeated captures: no lingering debris, camera drift or permanently locked input.
- R during a capture, R after a capture, and PLAY AGAIN after victory all reset
  pieces, statuses, effects, winner and camera.

Known limitations: primitive bodies are not fractured versions of the real mesh;
crack marks are temporary geometry; there is no final sound, rigged animation or
advanced destruction. The lab and runtime tests are development tools. Smoothness
at full resolution still depends on the local GPU, especially with the cloud
software renderer; the cinematic clock preserves event ordering and intended
short timing without globally accelerating gameplay.

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
