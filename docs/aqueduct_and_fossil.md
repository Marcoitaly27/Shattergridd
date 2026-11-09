# Broken aqueduct and embedded fossil

Adds two original environment elements on top of `6e381c2`:

- Five elevated masonry watercourse bays with an open upper channel, one
  interrupted central span, standing supports and fallen masonry below the gap.
  The route runs diagonally behind the court, extending beyond the strategic
  frame to suggest a larger surrounding world.
- One enormous weathered long bone partly surrounded by ruined masonry beside
  the cathedral. Its creature is intentionally unspecified; no living dragon or
  full skeleton is introduced.

`build_aqueduct.py` authors the geometry in Blender, reusing the original mesh
helpers in `build_cloister.py`. `assets/world/aqueduct/` contains the exported
model, LOD import settings and provenance. `ancient_bone` shader/material adds
muted aged coloration. `grounded_courtyard.gd` attaches the visual-only model.
No external downloads, fees, new licenses, lights, collisions or gameplay rules.
Existing statues, cathedral and controls remain unchanged. The strategic camera FOV
is widened from 37 to 42 degrees to include more surrounding architecture; its
position and fixed strategic behavior are retained. Before/after comparisons
use the same revised FOV.

The strategic view intentionally shows a portion of the aqueduct; this is an
original modeled setting element, not scanned final architecture. Stone courses
remain regular and the fossil anatomy is stylized rather than a specific animal
reconstruction. Cloud Warden import failures remain pre-existing and unfixed.

Raw day/night screenshots use identical camera and lighting before/after. The
before image hides only the added ruins. Night lighting is applied without
advancing the match clock, so HUD day text is unchanged.

| Light | Before | After |
| --- | --- | --- |
| Day | [Before](aqueduct-previews/before-day.png) | [After](aqueduct-previews/after-day.png) |
| Night | [Before](aqueduct-previews/before-night.png) | [After](aqueduct-previews/after-night.png) |

Local review: close Godot, pull main in GitHub Desktop, reopen and F5. Inspect the
fossil near the cathedral and aqueduct beyond the ruined arcade. Verify board
edge selections and captures and inspect both lighting phases on the local GPU.

Verification: 210 checks passed for 64-cell picking, destination border heights,
statue grounding and collision separation; 269 checks passed for edge captures,
normal movement, turn transitions and restart. Actual day/night Compatibility
renders inspected. New shader/script resources load without new compile errors;
existing Warden import failures remain. Software OpenGL cloud rendering does not
certify local GPU performance or every possible cinematic configuration.

Sampled cinematic poses at [far edge](aqueduct-previews/edge-0.png) and
[near edge](aqueduct-previews/edge-7.png) keep both actors visible. Rubble was
corrected to rotate around its own center and rest on the ground; final viewport
captures verify that placement.
