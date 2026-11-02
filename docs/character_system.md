# SHATTERGRID character system — version 0.6

## Law of Reflection

> The Grid does not summon armies. It reflects them.

Most statues around a Core must manifest as reflected pairs. Whether this is a
religious ritual, sacrifice, balance, imprisonment or an ancient limitation is
unknown. This working lore is not a definitive explanation or final marketing text.

Unlocking a statue adds strategic options, not a higher level of the same unit.
Starter characters should remain useful. Future alternatives should offer
different movement geometry, abilities, risks, synergies and counters. There are
no numeric rarity tiers, character levels or automatic power upgrades in this
foundation.

## Audit of the actual starting repository

Starting revision: `adb56c2` (0.5). Before changing code, all five existing native
Godot suites completed **2,455 checks with zero failures**.

| System | Actual state before 0.6 |
| --- | --- |
| Board generation | 64 worn beveled tiles, foundation/rim and independent decorative world |
| Coordinates | Logical BoardState, per-tile metadata, per-piece coordinate and occupancy |
| Piece architecture | Shared CharacterDefinition, per-instance ID/army/statuses and replaceable visual scene |
| Archetypes | Core, Warden, Hunter, Executioner, Witch and Wyrm |
| Movement | Temporary exactly-one-square movement in all eight directions for every character |
| Selection | Physics picking, base outline, empty/attack hints, cancel and input locks |
| Turns | Local alternating players; move/capture/return completes before advancing |
| Captures | Occupancy resolves at shatter; later effects/victory wait for camera restoration |
| Cinematics/camera | Six Resource-selected capture behaviors, fitted side camera and exact strategic restore |
| Destruction | Bounded rigid stone fragments, CPU dust and timed cleanup |
| Core victory | Core destruction ends the match after cinematic completion |
| Restart | R, victory button and cancellation during early/late capture |
| Hex | **Absent**; Witch's Wither is capture presentation, not a gameplay Hex |
| Blood Step | Per-Executioner next-owner-turn diagonal bonus, refresh and expiry |
| Terror | Adjacent enemies cannot capture through their next turn; Core immunity |
| Status effects | Shared modifier definitions and independent per-piece owner-turn deadlines |
| Environment | Separate gothic shell, lower settlement/chapel, fog, stone palettes, two braziers |
| UI | Turn/selection/status panel, victory/restart and a separate cinematic debug lab |
| Army setup/collection | Sixteen manually authored scene instances; no builder, slots, loadouts or unlock state |

No broken baseline dependency required repair. Hex remains absent. No movement,
ability, cinematic, camera, destruction, victory or environment behavior was
rewritten. Initial army composition now follows the reflected formation below.

## Character definition and registry

`scripts/pieces/character_definition.gd` remains the shared native Resource. It now
separates three concepts:

- `character_id`: unique stable collection/loadout key, such as `warden`.
- `deployment_category`: one of `core`, `guard`, `hunt`, `power`, `special`.
- `archetype_id`: retained visual/cinematic family for existing debug tools.
  Multiple future characters may share it; gameplay does not dispatch on it.

Existing display name/lore, model scene, team materials, movement behavior,
capture behavior, post-capture effect, Core objective flag and status immunities
remain on the same Resources. New title and short gameplay description provide
the text preview. `unlocked_by_default`, `unlock_condition_id` and
`hidden_until_unlocked` provide small progression hooks.

Model nodes may already contain authored animations. Capture Resources implement
`append(timeline, context)`; ability Resources implement
`apply(attacker, board, completed_turns)`. These references stay independent of
deployment/UI. No empty portrait/audio/VFX assets or speculative subsystems were
created. Team palettes can still be empty to preserve authored model materials.

`prototype_catalog.tres` explicitly registers the six definitions. It validates
nonempty unique IDs, categories, Core flags and required model/movement data.
There is no roster table in GameManager, BoardState or CaptureDirector.
The catalog can contain several Core definitions; a deployed army must choose one.

## Loadouts, slots and deployment

`ArmyLoadout` stores a dictionary of **slot ID → character ID**. It does not store
nodes, models or a choice for each individual statue. This supports several
future slots of one category without adding more fixed loadout fields.

`FormationDefinition` stores board dimensions and Resource slot definitions.
Each slot has an ID, category, left coordinate, explicit reflected coordinate,
paired flag and optional allowed-character IDs. Singles use only the first
coordinate. Opponent coordinates reflect rows using formation dimensions.

The first 8×8 formation is authored for Player 1 at row 7:

| Slot | Character choice | Columns | Members |
| --- | --- | --- | --- |
| Core | Core / The Veiled Sovereign | 3 | 1 |
| Guard | Warden | 0 and 6 | 2 |
| Hunt | Hunter | 1 and 5 | 2 |
| Power | Executioner | 2 and 4 | 2 |
| Special | Witch or Wyrm | 7 | 1 |

Player 2 uses row 0. Paired coordinates reflect about the Core's column, **3**,
not the midpoint between board columns 3 and 4. The single Special deliberately
uses the extra outside position on an even-width board. This configurable
exception is not a permanent final formation. Changing Core/paired coordinates,
adding rows or turning Special into a pair requires formation/loadout data, not
new spawning branches. A paired Special is covered by validation tests.

`ArmyRules.plan_match` is independent of nodes, rendering and UI. It validates
both loadouts, collection availability, category/Core restrictions, slot/character
IDs, pair reflection, one Core per army, bounds and intra/inter-army overlaps.
Invalid input returns errors and **no partial deployment plan**. Unknown loadout
keys are rejected, so stale slot names do not silently deploy a different army.

`MatchSession` is a small autoload carrying copied confirmed loadouts across
scene changes. The builder edits independent copies. Invalid confirmation leaves
the last valid snapshots intact. Restart reads the same snapshots. In a new
process, opening the match directly uses the default loadout.

`ArmyDeployment` runs before GameManager registers occupancy. It validates the
entire plan and instantiates the shared Piece scene in one generic loop. Members
share character data but have unique piece IDs, coordinates, selection state and
StatusState objects. Slot/member provenance is recorded on the instance.
GameManager then owns ordinary play. BoardState knows nothing about collection,
catalog or builder controls. Removing the visual world remains safe.

## Migration and prototype interface

The existing six `.tres` definitions retain their model, movement, capture,
ability, palette and immunity references. Core maps to Core, Warden to Guard,
Hunter to Hunt, Executioner to Power, and Witch/Wyrm to Special. Names/models and
silhouettes remain unchanged.

The old row was Warden, Hunter, Executioner, Core, Witch, Wyrm, Hunter, Warden.
The new row is Warden, Hunter, Executioner, Core, Executioner, Hunter, Warden,
Special. There are still 16 pieces and both opposing edge rows. Witch and Wyrm
are alternative choices instead of both being mandatory in every army. This
changes deployment composition, not their movement or abilities. The character
model test explicitly includes all six, including the optional Wyrm.

F5 opens the restrained development builder. Each player chooses independently
from the same collection. Core/Guard/Hunt/Power currently have one choice;
Special has two. Visible locked entries are disabled; hidden locked definitions
are omitted. Focus/select a category to see name, title, role, description and
both affected preview cells. Start confirms both loadouts before entering play.

R and PLAY AGAIN restart a fresh match with confirmed loadouts. ARMY LOADOUT
returns during ordinary play or a capture; RETURN TO LOADOUT is also available
after victory. Both routes cancel movement/capture and discard the old scene.
Choices survive scene changes but are not written to disk. The optional F6
capture lab still starts a match directly and can demonstrate all six captures.

## Collection and progression limits

`CharacterCollection` stores explicit unlocked IDs and honors definition defaults.
All six prototype characters are unlocked by default. A future definition may
carry a condition ID for progression, mastery, challenge, discovery or narrative
systems. This version evaluates none of those conditions. Hidden definitions do
not have to appear as numbered locked placeholders. Unlocking adds availability,
never stats. No currency, XP, shops, saves or progression rewards were added.

## Add one future character

1. Create one CharacterDefinition `.tres` with a new stable `character_id`, name,
   title, gameplay description and an existing deployment category. Reuse a
   presentation family if appropriate; do not reuse another character's ID.
2. Assign a real model scene and movement Resource. Reuse existing resources or
   supply a behavior implementing `get_destinations(origin, army, board)`.
3. Assign a capture Resource and optional post-capture effect; declare Core flag
   and immunities when relevant. Reusing a cinematic behavior needs no director
   changes. Supply a new behavior Resource only for genuinely different motion.
4. Assign team materials, or leave the palette empty for authored materials. Put
   actual animation nodes in the model; do not create fake asset references.
5. Register the definition in `prototype_catalog.tres`. Set unlocked-by-default
   for testing or associate an unlock condition ID. Reveal it by adding its ID
   to the in-memory collection when testing a locked/hidden definition.
6. An unrestricted compatible slot automatically lists it. For a deliberately
   restricted slot, add the ID to its allow-list. Choose it once in the builder:
   both paired instances receive the definition. A new Core uses the same route
   but must remain the sole deployed Core.
7. Run the six suites below and test the actual model/picking/capture framing.
   Do not edit GameManager, BoardState, the turn flow or CaptureDirector merely
   to register a character. A genuinely new mechanic may need its own reusable
   behavior/status implementation; registration alone cannot invent that mechanic.

## Files and validation

Created: `scripts/army/` (catalog, collection, slots, formation, loadout, rules,
session and deployment), `resources/armies/` (catalog, formation, default loadout),
`scenes/ui/army_builder.tscn`, `scripts/ui/army_builder.gd`,
`tests/army_smoke.gd`, corresponding script UIDs and this focused design document.

Modified: six existing character Resources, CharacterDefinition, Piece,
GameManager (deployment failure guard and safe return route), turn-display UI,
`scenes/main.tscn`, `project.godot`, README, battlefield and character smoke tests.
Capture, status, movement, world scripts, model scenes and stone materials remain
unchanged. Main no longer serializes sixteen individual character instances.

Run from the repository root:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/character_smoke.gd
godot --headless --path . --script res://tests/capture_smoke.gd
godot --headless --path . --script res://tests/world_smoke.gd
godot --headless --path . --script res://tests/army_smoke.gd
```

The army suite includes future sidegrade/Core test definitions created only in
memory, different movement without controller edits, invalid data, locked/hidden
availability, snapshot isolation and actual scene transitions. The fixture
definitions are not added to the game's roster or represented by fake assets.

Runtime validation used Godot **4.6.3**:

- Final headless suites: battlefield 328, interaction 116, characters 1,302,
  captures 461, world 248, army 451: **2,906 checks, zero failures**.
- OpenGL Compatibility at 960×666 on Mesa llvmpipe: army 451, captures 461,
  world 416; zero failures. The world adds 168 render-buffer comparisons.
- The actual builder, Special popup and deployed match were rendered and
  inspected. Popup selection and a simulated mouse click on START MATCH launched
  sixteen pieces with independent player choices.
- Native editor import completed without script/resource errors. Static path
  validation found 213 resource references and no missing files; whitespace
  checks passed.

The software display driver reports unsupported VSync. Windows/Godot 4.7 GPU
appearance, smoothness and native popup behavior still need local manual review;
cloud tests do not establish those hardware properties.

## Exact manual review in Godot

1. Close Godot before pulling main. Reopen `project.godot`, press F5: the builder
   appears before any match. Both players have five category selectors.
2. Focus Guard or Power. Both reflected cells should highlight around the Core;
   each choice is marked PAIR ×2. Inspect name/title/category/description.
3. Choose Witch for Player 1 and Wyrm for Player 2. START MATCH should deploy
   eight statues per side, one Core each, two identical choices per paired slot
   and the selected Special in the outside position. The medieval world remains.
4. Select edge statues, cancel, try a friendly occupied destination, then move for
   each player. One-square movement and turn alternation should match 0.5.
5. Press R: 16 fresh statues, cleared statuses/effects and the same loadouts.
   Use ARMY LOADOUT, change only one side, start again and check that side changes.
6. Return to the builder during a capture, then start again. There should be no
   duplicate armies, old debris, drifting camera or locked input.
7. Open `scenes/debug/capture_lab.tscn`, press F6 and 1–6. Use Enter to replay,
   C for a Core victim and Space for fast-forward. Both actors should remain
   visible; Core victory must appear after camera return.
8. Use PLAY AGAIN after victory, then repeat and use RETURN TO LOADOUT instead.
   Both flows should preserve choices and create fresh state without duplicates.
9. Check Blood Step and Terror in the lab. Blood Step is next-owner-turn only and
   per Executioner; the base prototype already includes diagonals. Terrified
   enemies may move to empty tiles but cannot capture; Cores remain immune.
10. Check popup keyboard/mouse operation, scroll/readability at your window size,
    board picking and GPU smoothness on Windows/Godot 4.7. These local hardware
    properties are not established by cloud headless tests.

Known limits: a development text/grid interface, six placeholder models, no final
portraits, no new playable characters, no persistence/unlock evaluation, no Core
passives, no AI/online play and no final balance. Hex remains absent. The formation
is a prototype; Special is explicitly configurable. Version 0.7 was not started.
