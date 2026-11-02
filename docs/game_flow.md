# SHATTERGRID 0.7 — technical foundation and game feel

## Actual repository audit

Starting revision: `fc6cd3b` (0.6). All six previous native suites passed before
changes: **2,906 runtime checks**. No broken baseline dependency was discovered.

| Area | Starting state / disposition |
| --- | --- |
| Project/main scene | WORKING: F5 builder; separate main match and F6 capture lab |
| Board/tiles/coordinates | WORKING: 64 beveled tiles, logical occupancy, native physics picking and tile-top placement |
| Character definitions | WORKING foundation: six Resource definitions with separate identity/category/model/behavior data |
| Loadouts/reflected deployment | WORKING: independent snapshots, validated pairs around Core column, one Core, configurable Special |
| Collection | WORKING/TEMPORARY: all current characters available; in-memory locked/hidden availability, no progression/save evaluation |
| Movement | WORKING/TEMPORARY: exactly one square in eight directions; 0.24-second eased movement |
| Selection/legal moves | WORKING but feedback PARTIAL: outline and legal borders, no hover or rejection explanation |
| Abilities/statuses | WORKING: Blood Step/Terror with per-piece owner-turn deadlines; readability PARTIAL |
| Hex | MISSING; Witch's Wither is cinematic presentation, not a Hex mechanic |
| Turns/action locks | WORKING: phase-driven locks; selected state implicit, no turn-transition feedback |
| Captures/cinematics | WORKING/TEMPORARY: six native behavior Resources, authoritative shatter, camera restore before effect/turn |
| Destruction | WORKING/TEMPORARY: bounded rigid chunks/dust with timed cleanup |
| Cinematic camera | WORKING: bounds fit, two-side visibility checks and height clearance; exhausted-search fallback needed hardening |
| Strategic camera | WORKING: fixed full-board view; deliberately retained |
| Core victory/restart | WORKING: deferred victory after camera, safe cancellation/reload; no atmospheric pause |
| Builder/environment | WORKING/TEMPORARY: two-player selector/preview; independent medieval scenery/fog/braziers |
| Match UI | PARTIAL/TEMPORARY: turn, selected name/status and victory; no complete piece panel, threats or developer overlay |
| Hover/threat/debug tools | MISSING; added in 0.7 |

No new characters, final names/lore, abilities, progression or balance rules were
introduced. The six definitions, loadouts, board dimensions, world and stone
materials retain their existing identity. Temporary movement and art remain
temporary. Hex and active/manual ability targeting remain absent.

## Current game and action flow

```text
ARMY SETUP → confirm loadout snapshots → deploy/validate both armies
→ TURN_IDLE ↔ PIECE_SELECTED
→ MOVING or CAPTURE_CINEMATIC
→ RESOLVING_ACTION
→ next player's TURN_IDLE
  or, after Core destruction: short pause → VICTORY
→ REMATCH or RETURN TO ARMY SETUP
```

Army setup is a separate scene. Within a match, GameManager's existing Phase
enum remains authoritative: READY, MOVING, CAPTURING, RESOLVING, GAME_OVER and
RESTARTING. READY with a selected instance is PIECE_SELECTED; otherwise TURN_IDLE.
`action_state_name()` exposes this distinction without another state machine.
No empty ABILITY_TARGETING state was added for abilities that do not exist.

`can_accept_input()` is true **only in READY**. Movement, capture, resolution,
victory and reload cannot accept board actions. `is_moving` is a derived
compatibility query, not a second lock. The director's active flag describes its
own timeline; it cannot unlock GameManager. Starting a capture also requires
the CAPTURING phase, the active attacker's army and an opposing victim.

Selection is cancelled by Esc, right click, a second click on the same statue,
an invalid destination or a click outside the board. Friendly clicks switch
selection. Invalid actions explain the reason without consuming a turn.

## Preview and interaction contracts

MovementResolver remains the one rule source: character behavior + active status
modifiers + bounds/occupancy validation. Selecting computes the legal preview;
hover uses that cache. Clicking revalidates against the same resolver and also
requires the destination to have been displayed. External state changes fail
closed and refresh the preview instead of allowing an unseen destination.
Status changes refresh a selected statue's preview immediately.

Interaction physics raycasts run when pointer position, selection, action state,
status/tactical revision or viewport size changes. Stationary idle input does
not recalculate moves or repeat raycasts. GUI regions clear world hover. Capture
hover never starts a cinematic; only a confirmed click can do so.

| Visual | Meaning |
| --- | --- |
| Plain stone | No active interaction |
| Muted short corner marks | Selectable hover / unavailable tile in grey |
| Full pale-brass pedestal outline | Selected statue and its tile |
| Brass destination border | Legal empty move |
| Rust border and X | Legal enemy capture |
| Small brass + | Destination supplied by an active status movement modifier |
| Rust Core corner marks + warning text | Core can currently be captured by an enemy |
| B / T pedestal text | Blood Step / Terrified; a dot denotes a pending owner-turn status |

Status glyphs use definition metadata, not new icon assets. They are small,
collision-free and readable over the pedestal. The information panel includes
name, category, player, actual movement summary, ability name/description and
current/pending status details. Movement/ability/status Resources own that text.
There are no separate per-character description switches in UI.

One versus two small pedestal cuts distinguish Ash/Slate beyond material color.
The turn panel also names Player I/II, army and pedestal mark. A 0.48-second
opacity transition communicates a new turn while leaving input responsive.
Contextual notifications are short, deduplicated and bounded to three queued
messages. Core warnings persist instead of duplicating notification text.

## Turn, capture, victory and restart

Ordinary movement still commits logical occupancy before its deterministic
0.24-second eased visual tween. Input remains locked until its completion.
The completion enters RESOLVING; owner-turn statuses expire, the player changes
once, tactical feedback refreshes, and input unlocks. Repeated completion/advance
callbacks cannot end another turn.

Capture flow remains:

```text
confirmed legal capture → cinematic lock → anticipation/impact
→ shatter (occupancy changes) → attacker settles → exact camera restoration
→ RESOLVING → capture ability/status application → Core victory check
→ next turn, or 0.30-second atmospheric pause → solemn victory presentation
```

During the victory pause, the camera is already strategic and all board input
remains locked. No check/checkmate rule was added: Core threat warnings simply
test the ordinary capture destinations of enemies, including Terror restrictions.
Players may ignore the warning and move another statue normally.

R and REMATCH reload the match from the confirmed loadout snapshots. ARMY LOADOUT
and RETURN TO ARMY SETUP use the same cancellation path and open the builder.
Movement/victory tweens and the cinematic are cancelled before scene change.
Fresh Piece/BoardState/UI instances reset positions, occupancy, statuses, winner,
input queues, notifications, fragments, particles and camera state. There are no
once-per-match or Hex states to reset in this repository.

## Camera and desktop behavior

The static strategic composition remains intentional: selection should not move
the board underneath the pointer. No micro focus drift or continuous camera motion
was added. Existing cinematic side tests, full-statue fitting and restoration
remain in place. Camera height is constrained to at least 3, including shake.
If the closer search exhausts its attempts, it uses a proven fitted pose or a
safe visible strategic pose instead of an unfitted last trial.

Decorative world geometry remains below the cinematic clearance and has no
gameplay collision. The new panel is bounded and scrollable for unusually long
data. Native window minimum is 960×640; desktop tests include 1280×720, 1024×768
and 1920×1080. They check every tile center remains framed and outside the piece
panel, plus large-statue capture fitting at all corners in three directions.
No graphics settings or mobile layout were introduced.

## Debug controls and invariants

- F3: debug-build-only overlay, hidden by default. FPS, state, player, selected
  piece/coordinate, hovered coordinate, piece/effect counts, cinematic/camera
  mode, nodes/draw calls and legal-calculation/raycast counters. Updates at 4 Hz
  while visible, with processing stopped while hidden. Set `enabled = false` on
  the separate DebugOverlay node to disable it; release builds create no panel.
- R: restart even during capture/resolution. Space: existing debug fast-forward
  for an active capture. Esc/right click: deselect. F6 capture lab: 1–6, C, Enter.
- `GameManager.debug_validate_state(false)`: inspect occupancy/position/selection
  issues without logging. Debug builds validate once at completed actions;
  duplicate startup occupancy and capture corruption report errors. Nothing logs
  every frame. Repeated capture/turn/victory callbacks are guarded by phase.

The overlay is independent of production UI and never changes game rules.

## Performance baseline

Run an optional three-second idle sample:

```sh
godot --path . --script res://scripts/debug/performance_probe.gd
# Headless is useful for structural counts, not rendered FPS:
godot --headless --path . --script res://scripts/debug/performance_probe.gd
```

The probe reports window/device, wall-clock rendered FPS when graphical, node
counts, active scripted processes, bodies/lights, effects, draw calls and idle
calculation/raycast deltas. Measurements are hardware/window specific.

Headless baseline: 1,083 match descendant nodes, two script process nodes (the
existing flames), one script physics node (interaction), 81 gameplay/picking
bodies, four existing lights, zero effects, zero repeated idle legal calculations
and zero repeated idle pick rays over three seconds. The warmed interaction test
also checks 20 idle physics frames with zero recalculation, then repeated
selection/clear cycles without accumulating target markings.

No leaking debris/particles or duplicated scenery was found. Existing bounded
destruction cleanup tests still run. New decorative markers cast no shadows and
add no collision/lights. Legal highlighting is event-driven, target symbols are
released on clear, and hover meshes are reused. No visual-quality reduction,
premature material optimization or environment rebuild was needed.

Graphical cloud sample at 960×666: **6.23 FPS**, 758 draw calls, same node/body/light
counts and zero idle recalculations/rays over 3.048 seconds. This uses Mesa
llvmpipe CPU rendering, not a discrete GPU; it is a reproducible observation, not
a Windows performance target or a hardware regression comparison. Draw-call cost
from the existing primitive/lighting presentation remains a future profiling item.

## Files and validation

Created: `materials/hover_hint.tres`, `materials/selected_hint.tres`,
`scripts/debug/debug_overlay.gd`, `scripts/debug/performance_probe.gd`,
`tests/feel_smoke.gd`, generated script UIDs and this development document.

Modified: GameManager, board interaction, battlefield hints, Piece presentation,
status definition/state and the two status Resources; movement summary/counter;
the two ability scripts (text metadata only); turn UI; capture/camera guards;
capture-lab presentation; session window minimum; main scene, version and README.
Character definitions, roster, formation/loadout data, models, actual ability
rules, environment and gameplay board dimensions remain unchanged.

Run all seven suites:

```sh
godot --headless --editor --path . --import
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/character_smoke.gd
godot --headless --path . --script res://tests/capture_smoke.gd
godot --headless --path . --script res://tests/world_smoke.gd
godot --headless --path . --script res://tests/army_smoke.gd
godot --headless --path . --script res://tests/feel_smoke.gd
```

Executed with Godot **4.6.3**:

- Headless: battlefield 328, interaction 116, characters 1,302, captures 461,
  world 248, army 451, feel 487: **3,393 checks, zero failures**.
- OpenGL Compatibility: feel 487, captures 461, army 451, interaction 116,
  world 416: **1,931 checks, zero failures**. Resizing tests exercised the three
  desktop sizes above and corner shots with large statues.
- Rendered idle, capture hover, status/threat information and F3 overlay images
  were inspected. The selected panel shows all current single-status details;
  longer combinations remain scrollable. Cinematic/return/victory/restart and
  cleanup were executed, not merely inspected statically.
- Editor import completed without script/resource errors. Static validation
  found 224 resource references and no missing files. Whitespace checks passed.
- The headless and graphical three-second performance probes both completed.

The software X11 driver reports unsupported VSync. Windows/Godot 4.7 smoothness,
native window behavior and final visual judgment remain local manual checks.

## Exact manual tests / limitations

1. F5 → confirm both loadouts → START MATCH. Hover your statues without clicking;
   short corner marks should appear. Select one: a full pale outline and complete
   information panel appear. Click again, Esc or right click to cancel.
2. Inspect brass empty moves, rust/X captures and the legend. Hover a legal enemy:
   CAPTURE must appear, with no camera motion until clicked. Try an unmarked
   enemy/tile; expect an explanation, no action and no turn loss.
3. Move for each player. The statue slides briefly, clicks during animation do
   nothing, and the turn panel transitions once. Compare warm/slate stone, one/two
   pedestal cuts and the textual army identity.
4. In the F6 capture lab, play 1–6 and C Core-victim scenarios. Check actors,
   impacts, corners and camera return. Use Space to accelerate, not skip events.
5. Executioner captures: verify B on that statue and the next-owner-turn status.
   Select it next turn: bonus + destinations appear. Base movement already
   includes diagonals; Blood Step does not add another action. Check expiry even
   if another allied piece acts.
6. Wyrm captures: adjacent enemies show T. On their turn, empty moves remain legal
   and captures disappear. Status text explains why. The Core remains immune.
7. Bring an enemy next to a Core: its rust warning appears only if a capture is
   legal. Ignore it and move another statue: no check/checkmate restriction.
8. Capture a Core: cinematic and camera return finish, then a brief pause, then
   PLAYER VICTORIOUS / REMATCH / RETURN TO ARMY SETUP. Try both return routes and
   R during movement, early/late capture and the victory pause. Expect fresh
   armies/statuses/effects/input with unchanged confirmed loadouts.
9. F3 on/off: inspect state/hover/player/camera/effect counts. Hide it; gameplay
   should be unchanged. Repeat captures and wait for fragments/particles to clear.
10. Resize to the common desktop sizes above. Check panel scroll, all edge tiles,
    pointer hover after resize, no clipped UI and the local GPU frame rate.

Known limitations: provisional one-square rules, models, effects and soundless
captures; six current characters; development builder and collection without
persistence; no Hex or manual active ability targeting. The notification/marker
art is temporary. Cloud rendering uses software OpenGL, not the user's Windows
GPU. Local Windows/Godot 4.7 appearance/smoothness require manual review.
Version 0.8 was not started.
