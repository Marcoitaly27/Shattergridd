# Version 0.5 — medieval world and visual identity

## Actual repository audit

The starting revision was `0bbcea3` (0.4). Its four native Godot suites completed
2,207 checks before the visual changes. The audit found:

| System | Actual implementation |
| --- | --- |
| Board generation | 64 individually beveled tiles, deterministic wear, rim and stone platform |
| Coordinates/occupancy | Independent logical 8×8 BoardState, per-tile metadata and per-piece coordinate |
| Pieces/archetypes | Six shared definitions, replaceable native model scenes and per-instance identity |
| Movement | Temporary one-square movement in all eight directions, friendly occupancy blocked |
| Selection | Physics picking, piece outline, move/attack hints and cancellation |
| Turns | Alternating local players, explicit busy/capture/game-over phases |
| Captures | Authoritative resolution at the destruction event |
| Cinematics | Six distinct character behaviors, fitted camera, obstruction checks and exact camera restore |
| Destruction | Bounded rigid-body fragments, CPU dust and timed cleanup |
| Core victory | Victory only after destruction and camera restoration |
| Restart | R and victory restart button; active cinematics are cancelled and cleaned |
| Blood Step | Per-Executioner next-owner-turn bonus, refresh/expiry and no extra action |
| Terror | Adjacent enemies cannot capture through their next owner turn; Core immunity |
| Status effects | Per-piece state, owner-turn deadlines and generic movement modifiers |
| Hex | **Not implemented.** Witch's Wither capture is presentation, not a Hex ability |

There were no failing baseline checks to fix. Hex is unrelated to this visual
pass and remains explicitly unimplemented. No movement rules, balance, status
rules, turn flow, capture behavior or victory rules were changed for 0.5.

## Composition

The board remains the foreground focus. Its existing playable surface is
unchanged. A separate `VisualWorld` scene adds:

1. A hanging architectural shell: pointed open ribs, damaged piers, irregular
   foundation teeth and moss in rim joints. It suggests a broken sacred courtyard
   rather than a thin floating slab.
2. Four lower settlement terraces at heights −27 to −43, with cliff fragments
   continuing below −60. Houses, missing roof sections, sealed doors and rubble
   are silhouettes, not final modeled buildings.
3. A ruined chapel/bell tower on the western terrace: the strongest background
   landmark, kept below and away from the arena.
4. An empty abandoned execution frame, with no body or gore; crossed door boards
   suggest plague-era abandonment. A single broken draconic monument supplies a
   restrained mythological cue rather than an animated creature.
5. A lower world dissolving into height fog. There is no giant terrain plane,
   distant catch floor or new area for player exploration.
6. Two small rim braziers. Native flame proxies move gently and their warm local
   light contrasts with the cool cloudy daylight.

Landmarks and lower terrain are deliberately simpler and lower contrast than the
battlefield. The immediate playable area remains clear. All decorative geometry
is below the capture camera's minimum height; distant scenery is much lower.
No decorative physics bodies or collision shapes were added.

## Files and replacement points

New files:

- `scenes/world/medieval_world.tscn` and `scripts/world/world_visuals.gd`: independent
  composition root and module placement.
- `scenes/world/distant_settlement.tscn` and its script: shared house/roof/door,
  rubble and cliff batches.
- `scenes/world/floating_architecture.tscn` and its script: replaceable arena shell.
- `scenes/world/modules/`: chapel, execution frame, draconic relic and brazier.
- `scripts/world/brazier.gd`: restrained flame and light motion.
- `materials/world/`: shared scenery palettes, lightweight architectural stone,
  fire proxy and native procedural roughness map.
- `tests/world_smoke.gd`: presentation budgets, separation, placement and picking.

Modified files:

- `scenes/main.tscn`: one independent world instance and revised key/fill colors.
- `environments/suspended_sanctum.tres`: native overcast sky, fog and ambient light.
- The five existing stone materials: limestone/cold stone contrast, weathered
  statue palettes, matte specular response and shared roughness variation.
- `project.godot`: version 0.5, retaining the user's engine metadata.
- `README.md` and this report.

Game rules never query world nodes. Replacing or deleting `VisualWorld` leaves
selection, movement and turn resolution working. Open a module scene to replace
its placeholder geometry; keep its ground origin and its clearances. An artist
can replace the entire settlement module with professional assets instead of
retaining the procedural batches. Keep distant scenery collision-free and
preserve the two-light budget. Replace the brazier's `Flame` child or its module
when authored fire becomes available. No assets were downloaded or represented
by fake binary files.

## Lighting, fog and materials

The legacy `Moonlight` node now acts as restrained cool overcast daylight, with a
weaker neutral/cool fill. It retains the existing shadow contract for gameplay.
The two new amber OmniLights have no shadows and a 2.8-unit range. They are the
primary orange accents.

The native ProceduralSky replaces the near-black void with cold desaturated
storm colors. Native height fog starts at −20 with density 0.14, hiding lower
cliff bottoms. Distance fog is only 0.0035, so the strategic camera's distance
transmission to the board remains above 85%. Volumetric fog, custom sky shaders,
external sky textures and weather simulation were not introduced.

Both tile types remain related stone, with enough warm/cool value contrast for
the grid. Existing safe tile heights, clipped edges, raycast bodies and occupancy
are unchanged. Stone roughness is 0.98 with a shared native NoiseTexture map in
an 0.84–1.0 range; specular response is restrained. Statues retain every silhouette
and proportion from 0.3/0.4: broad Warden, lean Hunter, asymmetric Executioner,
tall narrow Witch, low Wyrm and monumental Core. Team identity uses warm limestone
versus cooler weathered slate, not pure white and black.

## Performance

The world uses 38 geometry nodes: 11 MultiMesh batches hold 168 shared instances.
Landmarks are small independent modules, and no distant object casts shadows.
The fog-softened settlement/cliff batches use native unshaded materials; detailed
per-pixel stone remains on the board, statues and chapel landmark.
The extra floating shell uses a cheaper vertex-lit albedo-only stone material,
without normal/roughness texture sampling or extra shadow casts. Detailed stone
presentation remains on the battlefield and statues.

Only two local lights and two small animated flame proxies were added. No ambient
particle field, birds, dragon animation, complex moss shader, volumetric fog,
large physics world or procedural asset download was added. Instance transforms
are retained as small CPU placement metadata for headless/editor validation;
the dummy renderer does not expose real MultiMesh transform buffers.

Renderer measurements are environment-specific. The cloud uses Mesa llvmpipe
software rendering, not the user's Windows GPU. Local GPU frame rate and visual
smoothness remain manual checks; the node/draw/collision budgets and placement
checks are independently verified.

## Validation and manual review

Executed with Godot 4.6.3 after the final visual changes:

- Headless: battlefield 328, interaction 116, characters 1,302, captures 461,
  world 248; **2,455 checks, zero failures**.
- OpenGL Compatibility (Mesa llvmpipe, 960×666): world 416 and captures 461,
  zero failures. The extra 168 world checks compare actual rendering buffers.
- Editor import completed without script/resource errors. Static validation
  found 186 resource references and no missing files; whitespace checks passed.
- Rendered images from all six capture scenarios, impact/fracture and Core
  victory were reviewed. Strategic selection was also exercised graphically.

The software display driver reports unsupported VSync; this is a cloud driver
limitation, not a GDScript or resource error. Godot 4.7 and Windows GPU appearance
have not been executed here.

Run the existing four suites and the new world suite from the repository root:

```sh
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --script res://tests/interaction_smoke.gd
godot --headless --path . --script res://tests/character_smoke.gd
godot --headless --path . --script res://tests/capture_smoke.gd
godot --headless --path . --script res://tests/world_smoke.gd
```

The world suite checks no scenery collision, budgets, vertical layers, safe
camera clearance, fog transmission, stone roughness, edge/character picking and
successful gameplay after removing the whole environment. With a renderer it
also compares the actual MultiMesh transforms against the CPU placements.

Manual checks in the user's Godot editor:

1. F5: the full grid, both armies and the hanging foundation are readable; the
   church, ruined settlement and fog establish scale without hiding tiles.
2. Select corner and edge statues, click marked destinations, cancel selection
   and play one move for each player. Rules should feel identical to 0.4.
3. Check that the six silhouettes remain recognizable and warm/slate armies
   remain distinct under cloudy lighting and the two local fires.
4. Open `scenes/debug/capture_lab.tscn`, press F6, then 1–6. Watch attacker and
   victim during each camera movement. Ruins should remain a background rather
   than a foreground obstruction.
5. In the lab, C toggles a Core victim. Verify victory appears after camera return.
   Use Enter to replay, Space to accelerate, and R to restart a normal match.
6. Repeat captures and a restart during capture. Check for camera drift, lingering
   fragments or stuck input. Blood Step and Terror should behave as in 0.4.
7. Inspect frame rate on the local GPU at the intended window size. The cloud's
   software rendering is not a performance claim for that hardware.

Known limitations: buildings, cliffs, fire and statues are composition proxies,
not final realistic assets. Cliff forms are intentionally simple and softened
by fog. The existing downward-looking close capture shots often frame the board
and sky; lower ruins read most strongly in the strategic view and camera return.
There is no final vegetation, cloth, sky texture, environment audio,
weather simulation, final sculpture or Hex mechanic. Version 0.6 was not started.
