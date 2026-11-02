# SHATTERGRID · 0.10

[Master Game Vision](docs/MASTER_GAME_VISION.md) is the user’s guiding product
and creative direction. Read it before future design or architectural work;
planned features are implemented only when requested.

A local two-player Godot 4 tactical prototype. Version 0.10 implements the requested
character rules, shield protection, optional Witch rescue, ranged Hunter shot,
Werewolf day/night forms, Dragon flight and the Random-category Elf.

Read [the current roster rules, exact timing and manual tests](docs/roster_rules.md).
The [0.9 GLB/PBR pipeline](docs/asset_pipeline.md) remains available for real asset
integration. Models, capture animation and destruction remain prototypes; there
are still no real recordings, final rigs or imported production textures/models.
Historical version reports describe their original versions, not current rules.

## Open and play

Import `project.godot` in your **Godot 4** editor, then press **F5 / Play**.
The repository retains your Godot 4.7 project metadata and animation compatibility
setting. Runtime validation here uses Godot **4.6.3** and Compatibility rendering.
F5 opens `scenes/ui/army_builder.tscn`. Choose/confirm each player's Core, Guard,
Hunt, Power and Special, then click **START MATCH**. Guard, Hunt and Power choices
spawn twice, reflected around the Core column. Power offers Werewolf or Dragon. Special/Wildcard offers Witch or Elf.
The preview shows both players' actual coordinates; highlighted cells share a
single choice. Focus a selector to see the name, title and gameplay description.
F6 on `scenes/main.tscn` directly runs the last confirmed loadouts, or defaults in
a new process.

If using GitHub Desktop: select this repository and `main`, click **Fetch origin**
and then **Pull origin** when offered. Choose **Repository → Show in Explorer**
to locate `project.godot` for import into Godot.

## Controls and temporary rules

- Player 1 (weathered ash stone) starts. Player 2 controls the darker
  slate statues. Both armies draw from the same seven available prototype characters. Both players
  use the same mouse locally.
- Hover an active-player statue for short pedestal corner marks. Left-click it
  to select it. The information panel shows role, movement, ability and statuses. A muted brass
  outline around its architectural base marks the selection. Clicking another
  friendly statue changes selection.
- Brass tile borders mark empty destinations; rust borders and an X mark legal
  captures. Hover a legal enemy for CAPTURE feedback; only a click starts it.
  A + marks status-derived destinations; grey indicates unavailable tiles.
- B/F markers show Blood Step/Terror Flight on individual pedestals. One/two pedestal
  cuts and textual Player I/II identity supplement the two stone palettes.
- A threatened Core gains rust corners and a textual warning. This is tactical
  information only: it imposes no check/checkmate or forced response rule.
- Base movement is one tile: Warden orthogonally; Hunter and human Werewolf
  forward/backward; Witch and Elf forward/left/right; Dragon, night Werewolf and
  Core in all eight directions. Forward reverses for Player 2. Friendly tiles block.
- Select Hunter, Dragon with available flight, or Elf and use the ability button
  (or **A**) to preview targets. Click a marked target; A again cancels ability mode.
- The first capture against each Warden breaks his shield and spends the attacker’s
  turn. A living Witch can optionally save one allied statue, including herself or
  Core. Her player chooses SAVE STATUE or ALLOW CAPTURE in the rescue dialog.
- Start in daylight. After **five turns for each player**, night begins; after five
  more each, daylight returns. The label counts rounds until the next change.
- Click a marked tile, or the enemy on it, to move. The statue slides briefly to
  the tile. Occupancy commits immediately and input is locked during the tween;
  the turn changes only after the movement completes.
- A capture starts a short cinematic. Gameplay input stays locked through the
  camera return, then abilities resolve and the turn changes. Destroying the
  opposing Core ends the match only after its cinematic completes.
- Click an invalid destination or outside the board to clear selection.
  **Esc**, **right-click** or clicking the selected statue again also cancel. Cancelling does not consume a turn.

The restrained label at the top shows `PLAYER 1 TURN` or `PLAYER 2 TURN` and the
army identity. A brief opacity transition communicates a turn change without
locking gameplay. Invalid moves receive a contextual explanation.
There are no free-camera controls. **R** restarts a match, including during a
capture; **REMATCH** restarts after the solemn victory pause, keeping confirmed loadouts.
**ARMY LOADOUT** returns to the builder during a match/capture;
**RETURN TO LOADOUT** does the same after victory. Choices survive scene changes
within one run, but are not saved when the application closes. In a debug/editor run, **Space**
fast-forwards an active capture while still executing every impact and resolution
event. There is no permanent skip button in the match UI.

## Prototype characters

These are replaceable stone prototypes, not final character art or roster balance.
Werewolf has distinct simple human/beast silhouettes. Elf reuses the lean Hunter
prototype with ear markers; Dragon reuses the existing winged creature study.
No production model, texture or final skeletal animation was generated.

| Character | Category | Ability |
| --- | --- | --- |
| Core | Core | Destroying it ends the match; old Terror immunity retained |
| Warden | Guard | First capture breaks shield instead of destroying him |
| Hunter | Hunter (`hunt`) | Once-per-statue bow shot at exact range two; stays put |
| Werewolf | Power | Night transformation; night kills earn next-turn two-tile Blood Step |
| Dragon | Power | Capture earns optional next-turn flight; flight costs next army turn |
| Witch | Special | Once-per-match optional rescue while alive, including herself/Core |
| Elf | Random (working category name) | Once-per-match adjacent allied non-Core swap |

The Power selection deploys twice by the Law of Reflection. The single
Special/Wildcard slot accepts Witch or Elf without changing either character's
category. Each army still has eight statues. Executioner/Wyrm are no longer
selectable; their original scene/resource files remain for compatibility and
historical presentation regression tests. [Full rules](docs/roster_rules.md).

## Architecture

- `scripts/board/board_state.gd`: logical dimensions, coordinates and occupancy,
  independent of meshes and physics. It supports rectangular boards; visuals
  use the matching exported `board_dimensions` on the battlefield node.
- `scripts/board/battlefield.gd`: deterministic masonry, native picking surfaces,
  coordinate-to-position conversion and separate move-hint geometry. Original
  stone materials are never overwritten by selection or movement highlighting.
- `scripts/pieces/character_definition.gd`: typed shared Resource containing the
  unique character ID, title, deployment category, gameplay description,
  unlock metadata and existing model/movement/capture/ability/material references.
  Seven active definitions live in `resources/characters/`; legacy definitions remain available to old fixtures. `archetype_id` is a presentation
  family, not the unique character key.
- `scripts/pieces/piece.gd`: per-instance ID, owning army, coordinate and optional
  name/movement overrides. `get_display_name()` and `get_movement_behavior()`
  resolve shared archetype data without character branches in GameManager.
- `scripts/pieces/placeholder_visual.gd`: reusable visual adapter at the legacy
  path. Model corrections, reflected art variants, simple production proxies,
  authored/named team surfaces and optional animation integration are isolated
  from Piece/board transforms. Models and simple inherited form scenes are editable under
  `scenes/pieces/characters/`. Native compound picking follows primitive parts,
  including weapons and low bodies. Production wrappers use authored simple
  Shape3D proxies or one bounds box, never detailed rendered-mesh collision.
- `scripts/movement/adjacent_movement.gd`: isolated eight-direction prototype
  rule. Future characters can supply another Resource implementing
  `get_destinations(origin, army, board)`. GameManager filters its destinations
  against board bounds and friendly occupancy.
- `scripts/game/game_manager.gd`: authoritative selection, validation and explicit
  READY / MOVING / CAPTURING / RESOLVING / GAME_OVER / RESTARTING plus
  DECIDING / DEFENDING phases for optional rescues and prevented captures. Board occupancy
  changes at the shatter event; statuses, victory and turn resolution wait for
  camera restoration. The obsolete instant-removal helper has been retired.
- `scripts/interaction/board_interaction.gd`: mouse/keyboard input and physics
  picking, evaluated during the physics step. Tile bodies use layer 1 and piece
  bodies use layer 2; queries include both.
- `scripts/ui/turn_display.gd`: turn identity/transition, bounded piece information,
  contextual capture/rejection/status feedback and persistent Core warnings.
- `scripts/debug/debug_overlay.gd`: F3 diagnostics in debug builds, separate from
  production UI; hidden and not processing by default.
- `scripts/debug/performance_probe.gd`: optional three-second idle baseline.
- `scripts/army/` and `resources/armies/`: catalog, formation/slot definitions,
  loadout choices, collection availability and pure validated deployment plans.
  `MatchSession` carries snapshots between scenes; `ArmyDeployment` spawns before
  GameManager registers occupancy. The board never reads progression/UI state.
- `scenes/ui/army_builder.tscn` and `scripts/ui/army_builder.gd`: development-only
  presentation of two independent loadouts, text details and formation previews.
- `scenes/main.tscn`: match composition, an empty Pieces container, deployment,
  lighting, camera, controllers and minimal UI. No hand-placed character roster.
- `scenes/world/` and `scripts/world/`: replaceable presentation-only arena shell,
  lower settlement, landmarks and two braziers. World objects have no gameplay
  collision or rule dependencies; repeated distant forms use MultiMesh.
- `materials/`, `environments/`: native procedural stone, hint colors and sky/fog.
- `scripts/audio/`, `resources/audio/`, `default_bus_layout.tres`: centralized
  bounded playback, optional stream entries, profiles, scope cleanup, layered
  ambience/music and user/mix gain separation. Media folders should be added
  only when real sound files are supplied.
- `scripts/visuals/`, `scenes/assets/`, `resources/visuals/`: wrapper templates,
  animation/event adapter, validation and PBR configuration. No fake GLB/maps.
- `assets/`, `effects/`: reserved for future original models and effects.

The battlefield builds its meshes on load, including in the editor with `@tool`.
Generated children are not serialized. Reopen the scene after changing generation
code; do not hand-edit generated children. Random wear uses a fixed seed.
Formation Resources supply startup coordinates; deployment resolves definitions
from loadout IDs and positions pieces using the battlefield. BoardState then owns
occupancy and updates each piece's `grid_coordinate` on a move.

To introduce a later statue, duplicate a character definition, assign its model
scene, movement, capture/ability references and deployment category. Register it
in `resources/armies/prototype_catalog.tres`; eligible builder slots discover it
without editing controllers. See the design document for the exact steps. Leave `team_materials` empty to preserve a future model's authored materials.
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
for future motion and cinematic execution. A valid wrapper-local AnimationPlayer
capture with an impact method track uses the authored adapter on the director's
clock; missing/unsafe clips retain the existing procedural fallback.
`CharacterDefinition.audio_profile`
now selects a replaceable event/layer profile. Actual AudioStreams are assigned
only through the audio library; optional missing streams skip safely.

## Cinematic captures

| Attacker | Prototype sequence |
| --- | --- |
| Warden — The Bastion | Weighted withdrawal, grounded shield drive, recoil and heavy collapse |
| Hunter / Elf — The Final Hunt | Quick precise pass, silent beat, delayed cracking and destruction |
| Hunter bow — The Last Arrow | Stationary shot, short prototype arrow, target fracture |
| Werewolf human — The Bastion | Short physical charge, recoil and stone impact |
| Witch — Wither | Stationary tilt, victim tremble, dark crack marks, contraction and inward collapse |
| Dragon / Werewolf beast — Maul | Low crouch, sudden animal lunge, sideways maul and fracture |
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
- `cue_emitted(event, attacker, victim)`: precise audio/VFX hooks for anticipation,
  motion, impact, crack, debris, attacker settle and Core destruction. MatchAudio
  consumes them without guessed timers or gameplay authority. Only two chunks
  can report real platform contacts; falling into the void has no landing event.
  The prototype remains silent until real streams are assigned.

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

- **Blood Step:** a successful Werewolf night capture adds exact two-tile moves
  along all eight directions on its owner's next turn. Intermediate tiles must be
  clear. No extra action or stacking; expires even if another ally acts. An earned
  bonus survives dawn until its promised turn ends.
- **Terror Flight:** a successful Dragon capture offers flight on its owner's next
  turn. Using it reaches any empty tile and makes the army skip its following turn.
  Declining flight expires the offer without a penalty. The old Terror debuff and
  one-square diagonal bonus remain only in historical regression fixtures.

`resources/abilities/` selects the two post-capture effects from character data.
They are applied after camera return, then Core victory is checked, then the
turn advances. A winning capture holds a short locked pause after camera return, then presents
victory instead of handing over another turn. The existing selected-piece panel displays active status names.

## Quick cinematic lab (optional)

To see every capture without advancing armies across the board:

1. Open `scenes/debug/capture_lab.tscn` in the Godot editor.
2. Press **F6** to run only that scene. F5 opens the army builder.
3. Press **1–7** for Warden, Hunter, Werewolf, Witch, Dragon, Core and Elf.
4. Press **Enter** to replay, **C** to toggle a Core victim, or **Space** to
   fast-forward. **R** leaves the lab and starts a normal fresh match.

This developer scene isolates capture presentation: shields/rescue are already
spent and it bypasses movement eligibility for its fixed preview setup. It is
never inserted into the normal match or its UI.

## Validation

Run from the repository root:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/character_smoke.gd
godot --headless --path . --script res://tests/capture_smoke.gd
godot --headless --path . --script res://tests/world_smoke.gd
godot --headless --path . --script res://tests/army_smoke.gd
godot --headless --path . --script res://tests/feel_smoke.gd
godot --headless --path . --script res://tests/audio_smoke.gd
godot --headless --path . --script res://tests/asset_smoke.gd
godot --headless --path . --script res://tests/roster_smoke.gd
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
entire world and verifies gameplay still works. `army_smoke.gd` checks mirrored
planning, rejected configurations, independent collection/loadout state, future
character/Core definitions and real builder → match → restart/return/victory
transitions. The character suite explicitly includes the optional Wyrm in its
model fixture. `feel_smoke.gd` checks hover, preview/action equality, live status
updates, nonbinding Core warnings, repeated callback guards, three desktop sizes,
corner camera fitting, debug toggling, idle counters and victory pause ordering.
`audio_smoke.gd` checks missing references, native routing, volume/mute conversion,
variation/voice limits, owned loops, rare categories, music/ducking restoration,
exact impact hooks, actual platform/void contacts and scope replacement. Native
stream fixtures exist only in test RAM; no audio samples/files are generated.
`asset_smoke.gd` verifies model/environment replacements preserve gameplay,
proxy/material isolation, pair variants, PBR channels and actual method-track
impact timing/cancellation using existing scenes and RAM-only clip fixtures.
`roster_smoke.gd` tests the seven current characters, protection choices, bow,
night boundaries, two-tile Blood Step, flight/army skips, Elf swaps and reset. Older
presentation/input suites explicitly load `tests/legacy_fixture.gd` to keep their
controlled historical rules; these are not the live roster. All ten scripts report
executed checks and return nonzero on failure.

Validation uses Godot 4.6.3 in the cloud, headless and with OpenGL Compatibility
rendering. See the asset-pipeline report for 0.9 validation;
the visual report records the earlier 0.5 checks. Testing on the local
Windows/Godot 4.7 GPU remains a manual
review of smoothness and appearance, not a claimed cloud result.

Headless checks do not demonstrate rendered appearance. Follow the
[current manual roster checklist](docs/roster_rules.md#manual-checks-in-godot) for
both armies, ability buttons, rescue choices, night transformations, flight costs
and cancellation/restart. Check strategic readability and frame rate on your GPU.

Development controls: **F3** toggles FPS/state/player/selection/hover/camera and
performance counters, including audio allocation, missing references, music,
cinematic mix and bus gains. **F4** requests the configured `ui.confirm` cue;
without a stream it records `missing`. These are debug-build-only controls and
can be disabled on DebugOverlay. **F7** adds selected-asset ID/path, correction,
animation/material/team information and nonfatal integration warnings.
Run `godot --path . --script res://scripts/debug/performance_probe.gd` for a
reproducible idle sample. See the game-flow report for interpretation and the full
manual checklist, including hover/status/Core warnings and desktop resizing.

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
Multiplayer, AI, final menus/progression, final characters and advanced combat remain out of scope.

Rapporto v0.9: [audit, file, workflow e verifiche](docs/v09_report.md).

Current character-rule implementation and limitations: [roster report](docs/roster_rules.md).
