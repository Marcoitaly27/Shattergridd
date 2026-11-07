# Mosaic, fallen bell and iron braziers

Extends the grounded cloister court from `6a1acfa` without changing gameplay,
characters, board coordinates or camera controls.

The entrance-side rosette and interrupted tessera border suggest an older ritual
pavement. Small gaps expose the existing ground. The fallen bell sits outside the
southwest apron, beside the cathedral burial ground, with an open mouth, interior
clapper and broken headstock. Two imported iron braziers replace the primitive
stem/bowl/conical fire meshes. The original two light sources and audio emitter
group are retained; there are no decorative colliders.

## Files

- `scripts/art/build_courtyard_relics.py`, `assets/world/relics/`: original Blender
  source and three GLB assets, import settings, provenance.
- `scripts/world/grounded_courtyard.gd`: visual-only mosaic and bell attachment.
- `scenes/world/modules/brazier.tscn`, `scripts/world/brazier.gd`: imported basket,
  restrained animated flame surfaces and material binding.
- `materials/world/aged_metal.gdshader`, bronze/iron materials, fire shader/material:
  muted oxidation and soft animated flame silhouettes.
- `materials/world/worn_tesserae.gdshader`: dirt and surface variation across the
  four muted mosaic colors.

No external assets or paid services used; no new third-party attribution required.
[Asset provenance](../assets/world/relics/README.md).

## Review

Godot Compatibility, software OpenGL, same strategic camera and lighting for
before/after. Night lighting is applied by the review harness without advancing
the match clock, so HUD turn/day text remains unchanged. Screenshots are raw.

| Light | Before | After |
| --- | --- | --- |
| Day | [Before](relic-previews/before-day.png) | [After](relic-previews/after-day.png) |
| Night | [Before](relic-previews/before-night.png) | [After](relic-previews/after-night.png) |

These are original modeled props and procedural materials, not scanned final art.
Fire uses lightweight crossed surfaces; oblique closeups may reveal that approach.
The pre-existing cloud Warden Blender import failure remains; character source
and scenes are unchanged. No claim of fixing the unrelated legacy test failures.

To review locally: close Godot, pull main, reopen, wait for imports, press F5.
Inspect the entrance mosaic, bell beside the graves and both corner braziers.
Check selections and captures around the corners, including the night phase.

Verification completed:

- 210 checks passed for all 64 tile picks, statue heights, destination borders
  and absence of decorative collision.
- 269 checks passed for movement, captures at opposite edges and restart paths.
- Actual Compatibility renders reviewed in day/night lighting; no new GDScript
  or shader compile errors. Existing Warden import errors persist as documented.
- No hardware performance claim or exhaustive cinematic visibility claim; the
  added props stay outside the playable tiles and prior camera controls remain.
