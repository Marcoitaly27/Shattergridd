# Zero-budget visual pass — 0.10.1

This is the first presentation pass on the existing battlefield, following the
Master Game Vision. It costs €0 and adds no purchased asset, external model,
texture image, rig, animation library, shader or rendering plugin. The current
statues and distant buildings remain prototypes, not production sculptures/ruins.

## What changes visibly

- Daylight uses a mildly warmer directional key and a lower ambient contribution,
  giving the carved forms and tile bevels stronger light/shadow separation.
- The existing cool fill keeps silhouettes readable. Night has its own cool key,
  fill, ambient, background brightness and fog colour; braziers retain warm contrast.
- Ash stone shifts toward weathered limestone; Slate remains a cooler dark stone.
  Tile/foundation colour ranges, restrained grain normals and lower specular response
  improve material consistency without changing team identity or interaction hints.
- A shorter directional shadow range and reduced bias improve near-board shadow
  definition using the existing shadow-casting light. No extra shadow maps or lights.
- Height/distance/sky fog are balanced together so lower settlement volumes blend
  into the valley atmosphere while the playing surface stays clear.
- Existing undercroft piers extend lower, strengthening the architectural support
  silhouette. No new procedural buildings or more elaborate primitive characters.

The strategic camera, board coordinates/size, meshes and physics of playable tiles,
army formation, characters, abilities, turn clock, capture rules and sound hooks
retain their current behaviour. No free camera, progression or additional content.

## Presentation ownership and cost

`day_night_presentation.gd` observes the authoritative clock. It interpolates only
when the actual phase changes, not on every completed round. Each match uses a
shallow duplicate of Environment for its mutable atmosphere parameters. The
immutable sky is shared; the transition changes background energy rather than
rebaking the procedural sky every frame. The owned transition is killed on exit.

Existing Compatibility rendering is preserved. No SSAO/SSIL, volumetric fog,
full-screen effects or new per-frame processing were added. Existing two local fire
lights and one shadow-casting directional key remain; distant world collision and
instancing budgets remain unchanged: 38 geometry nodes, 11 batches, 168 instances.

## Free Warden source research

A verified public free source is
[KayKit Adventurers](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0).
Its character listing includes Knight.glb. Kay Lousberg's original license says
CC0 and permits commercial use without mandatory credit. Evidence and exact URLs
are recorded in [the source register](ASSET_SOURCES.md); a copy of the source license
is retained under `docs/asset_research/`.

This is **stylised low-poly art**, as the author explicitly states. It is only a
possible free modeling base. It requires substantial silhouette/proportion/pose
work, stone materials and a detachable-shield review to become a realistic Warden.
It was not imported or assigned to the character. No claim is made that its rig,
shield structure, animations or model quality have been tested in SHATTERGRID.
No realistic production-ready free Warden was verified during this pass.

The next art step is a focused Warden replacement with the existing GLB wrapper
workflow, using a suitable licensed source and Blender cleanup/sculpting. Making
all seven statues detailed and realistic is a separate art-production task; adding
stone colour to a stylised model does not complete it.

## Files and validation

Modified: the existing Environment; five board/statue stone materials; ancient
masonry material; key/fill scene settings; day/night presentation; undercroft
proportions; six environment-isolation checks in the existing world suite; version
and README. Added this report and the source-candidate record/license evidence.

Godot 4.6.3: **3,879 checks passed across ten headless suites** and **2,417 checks
passed across eight OpenGL Compatibility suites**. No failed checks or GDScript
errors were reported. Editor import completed, all **412 resource references**
resolved, and `git diff --check` passed. Before/after renders were inspected at
1152×800, including the selected night Werewolf and its movement highlights.
OpenGL review uses software Mesa, not the user's Windows GPU. No final model/texture
fidelity or production GPU performance is claimed.

## Manual review

1. Close Godot, Pull origin, reopen and F5 → choose armies → START MATCH.
2. Check stone contrast, statue silhouettes, tile borders and readable highlights.
3. After five turns each, check nightfall, Werewolf transformation and both army
   colours. After five more each, daylight should return smoothly.
4. Play close captures near all corners. Check stone normals/shadows, clear camera
   framing, readable debris and exact return to the strategic camera.
5. Restart in daylight/night, return to loadout and try the capture lab. New matches
   must start in daylight with no lingering atmosphere or transition.
6. On the local Windows GPU, check brightness and frame rate at the normal game
   resolution. Appearance and speed depend on the display/driver and actual assets.
