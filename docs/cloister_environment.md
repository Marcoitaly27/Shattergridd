# Cloister and burial courtyard

This pass extends the existing grounded board without changing tile coordinates,
characters, rules, army setup, controls or lighting. Main baseline: `3c511c0`.

## Scene and assets

- Three joined masonry bays frame the far side of the court. One arch is broken;
  its fallen stones lie beneath the missing section. Dressed blocks have bevelled
  edges, paired shafts and a restrained stone material.
- Five aligned graves and two sarcophagi sit near the cathedral. Their elevations
  are sampled from the existing cathedral base to avoid burying the new models.
- One bare tree, including roots and tapered branches, anchors the far corner.
- Sparse opaque grass blades occupy burial ground and pier footings. No new
  dynamic lights, transparent foliage, physics bodies or gameplay collision.
- The ground shader transitions into soil closer to the court, with missing
  paving, damp joints and restrained green weathering at the perimeter.

The new GLB is authored in Blender by `scripts/art/build_cloister.py`, not built
from Godot primitives at runtime. Its four material batches share imported
geometry; mesh LOD generation is enabled. The imported cathedral is used only to
sample support heights, not copied into the new asset. No external asset library,
paid service or texture download was used. See
[asset provenance](../assets/world/cloister/README.md). Existing cathedral and
character licenses remain unchanged.

## Changed files

- `scripts/art/build_cloister.py`: reproducible Blender source.
- `assets/world/cloister/`: model, import settings and provenance.
- `scripts/world/grounded_courtyard.gd`: visual-only model attachment/materials.
- `materials/world/courtyard_ground.gdshader`: paving-to-soil transition.
- `materials/world/cloister_stone.*`, `dead_wood.tres`: rough stone and wood.
- `tests/grounded_courtyard_smoke.gd`: destination borders across all 64 cells.
- `tests/cloister_capture_smoke.gd`: edge captures, movement and restart.
- `tests/courtyard_visual_review.gd`: reproducible render and frame-time sample.

## Verification

- Ground/cell test: **210 checks, 0 failures**. All 64 actual tile rays, statue
  resting heights, destination border heights and no decorative collision.
- Capture/movement/restart: **269 checks, 0 failures**, headless. Hunter and Witch
  capture timelines at both ends, ordinary selection/movement/turn advance,
  idle/in-capture restart and victory restart.
- Godot Compatibility renders at 1440x1000, day and night; same camera and lighting
  for comparison. Edge camera samples inspect visibility near both armies.
- No new gameplay scripts or character resources changed.

The pre-existing Warden Blender import failure remains in this cloud installation
(Blender 4.3.2 cannot read that source file). Warden source/scenes are untouched.
The screenshots therefore do not certify that character's full appearance.
The earlier legacy interaction suite has 25 known failures on the baseline;
this pass does not claim that suite is fixed or passing.

## Visual limits

This is a restrained original environment pass, not scanned photorealistic art.
Masonry is still fairly regular, graves have simple carvings, and the procedural
soil/stone needs further art refinement. No claim of matching the concept image.
The fixed strategy HUD can cover parts of the far architecture; controls and HUD
were deliberately preserved. Off-board debris still has no physical ground
collider, as in the previous grounded court.

## Review locally

Close Godot, pull `main` in GitHub Desktop, reopen the project and press F5.
Inspect the graves beside the cathedral and ruined arcade behind the field.
Select pieces at the edges, move both armies, capture near both ends, reach night,
and restart. Verify the Warden imports with the user's local Blender version.

For comparable screenshots/performance, run Godot with
`--path . --resolution 1440x1000 --script tests/courtyard_visual_review.gd`.
Set `REVIEW_STAGE=baseline` to restore the original shader and omit the new meshes
in memory, or `REVIEW_STAGE=final` for the current scene. Set `REVIEW_DIRECTORY`
to the output directory. No source files are changed by the review script.

## Render comparison

| Light | Before | After |
| --- | --- | --- |
| Day | [Original court](cloister-previews/before-day.png) | [Cloister court](cloister-previews/after-day.png) |
| Night | [Original court](cloister-previews/before-night.png) | [Cloister court](cloister-previews/after-night.png) |

The review harness applies day/night lighting directly without advancing the
match clock; the HUD is therefore unchanged. The strategic camera, light energy,
colors, shadows, resolution and roster are identical in each pair. Screenshots
are raw viewport output. [Far edge](cloister-previews/edge-0.png) and
[near edge](cloister-previews/edge-7.png) show calculated cinematic poses; neither
new architecture nor tree obscures the actors in these sampled views.

## Performance sample

Same resumed cloud session, Godot 4.6.3 Compatibility, 1440x1000, Mesa llvmpipe
LLVM 19.1.7 software rendering on an AMD EPYC 9V74 virtual CPU (5 exposed CPUs).
60 sequential frames per lighting state after warm-up; separate runs, no other
Godot render/test process active. These are viewport frame intervals, not GPU
timings. No VSync support in this virtual display.

| Metric | Baseline | Final |
| --- | ---: | ---: |
| Day median frame interval | 523.973 ms | 562.600 ms |
| Day p95 | 637.640 ms | 650.369 ms |
| Night median frame interval | 531.099 ms | 550.318 ms |
| Night p95 | 603.522 ms | 612.853 ms |
| Render draw calls | 733 | 744 |
| Render primitive counter | 1,250,690 | 1,315,369 |

The measured median interval increases about 7.4% by day and 3.6% by night;
render counters increase by 11 draw calls and about 5.2% primitives (including
render passes). Both versions are very slow on software rendering. These short
samples are affected by shared cloud CPU load and do not predict Windows GPU
FPS. Hardware profiling remains a local review step.
