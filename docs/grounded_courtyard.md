# Grounded cathedral courtyard

The user's revised direction places the board on continuous ground rather than a suspended structure. Board transforms, tile surfaces, characters, abilities and camera controls are unchanged.

## Changes

- `scripts/world/grounded_courtyard.gd`: a continuous 360 m ground surface at y=-0.15, two courses of stone paving around the board and sparse fallen stones. No physics bodies or picking layers.
- `materials/world/courtyard_ground.{gdshader,tres}`: meter-scaled staggered paving, worn joints, restrained dirt/green staining and rough stone. Original procedural material; no external assets or costs.
- `scripts/world/world_visuals.gd`: instantiates the courtyard instead of suspended architecture, lower settlement and floating landmarks. Existing source scenes remain recoverable and available; braziers remain.
- `scenes/main.tscn`: existing cathedral moved onto the court at (-39,-0.15,-8), without modifying its mesh/materials/scale. Directional shadow opacity reduced to 0.55 for tactical clarity underneath its shadow. Lighting colors, energy and day/night timing remain unchanged.
- `docs/MASTER_GAME_VISION.md`: grounded courtyard and debris wording replaces suspended battlefield direction.
- `tests/grounded_courtyard_smoke.gd`: checks every tile's real ray picking, statue resting height and absence of decorative collision.

The old board foundation is buried beneath the continuous ground; its existing debris collision and tile logic are retained. There are no new colliders outside the board. Off-board destruction fragments can still fall through the visual-only court; landing effects there remain future presentation work.

## Visual evidence

Real Godot Compatibility renders at 1440x1000, software OpenGL. No retouching.

The matched before/after pairs use the exact same strategic camera and day/night lighting, including shadow opacity 0.55 in both. The before scene reinstates the original world and original cathedral position. Initial untouched baseline screenshots are also retained separately.

- [Before, matched daylight](grounded-previews/before-day.png)
- [After, daylight](grounded-previews/after-day.png)
- [Before, matched night](grounded-previews/before-night.png)
- [After, night](grounded-previews/after-night.png)
- [Cinematic camera, far edge](grounded-previews/edge-0.png)
- [Cinematic camera, near edge](grounded-previews/edge-7.png)

## Validation and limitations

- Grounded courtyard smoke: 146 checks, 0 failures (all 64 tiles, statue heights, collision separation).
- Capture/restart subset: 140 checks, 0 failures, headless (Hunter/Witch captures, idle and in-capture restart, victory restart).
- Day and night actually rendered; separate camera samples at opposite board edges.
- Legacy interaction smoke: 116 checks, 25 failures both BEFORE and AFTER this change. These are pre-existing failures, not a passing test. No gameplay edits were made to conceal them.
- The user's Warden Blender source cannot be imported by this cloud installation; missing-resource messages and incomplete Warden visuals occur in the unchanged baseline too. Its source and character scenes are untouched. Full roster visual approval requires the user's working Godot/Blender installation.
- Ground material is procedural and visibly repetitive at this stage; this is the grounded layout pass, not the photorealistic concept-image finish. No new vegetation assets were introduced.
- Hardware performance on Windows and exhaustive cinematic/ability combinations are not certified by software-rendered cloud checks.

## Manual review

Close Godot, pull main in GitHub Desktop, reopen the project and press F5. Confirm all statues import locally. Play moves for both armies, inspect selection and destination borders at edges, trigger captures near both ends, reach night and restart with R. Confirm the entire field remains readable and the local Warden looks unchanged.
