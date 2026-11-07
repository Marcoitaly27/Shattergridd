# Original courtyard details

`courtyard_details.glb` is original geometry authored for SHATTERGRID by the
repository script `scripts/art/build_cloister.py` with Blender 4.3.2.
The existing cathedral mesh is read to sample ground heights only; its geometry
is not copied. No external meshes, textures, scans, paid services or third-party asset packs
were used. There are no third-party attribution requirements introduced by this
asset. This provenance statement does not change the repository's license.

Rebuild from the repository root:

    blender --background --python scripts/art/build_cloister.py

Coordinates and placements are authored in the script, exported as glTF with
Godot's Y-up convention. Meshes are grouped into four materials; no collision or
lights are exported. Godot generates mesh LODs on import. The stone override is
attached by `grounded_courtyard.gd`. Existing cathedral/statue assets are unchanged
and retain their original provenance requirements.

Includes three masonry bays (one with a broken arch and associated rubble), five
aligned graves, two sarcophagi, a bare tree with roots, and sparse solid grass
blades. These are restrained original environment models, not scanned production
assets. Future refinement can replace them without changing gameplay.
