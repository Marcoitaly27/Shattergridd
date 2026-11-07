# Ceremonial courtyard props

Original meshes authored for SHATTERGRID by `scripts/art/build_courtyard_relics.py`
using Blender 4.3.2. No external models, textures, paid services or third-party
asset licenses are introduced. This does not alter the repository's license.

Rebuild: `blender --background --python scripts/art/build_courtyard_relics.py`.

- `fallen_bell.glb`: thick hollow bronze bell, cast bands, crown eye, interior
  clapper and broken wooden headstock, tilted and seated on its lowest point.
- `iron_brazier.glb`: splayed iron legs, fire bowl, basket ribs and coal bed.
  Instanced twice by the existing brazier scene; existing audio group retained.
- `ceremonial_mosaic.glb`: interrupted tessera border and damaged eight-point
  entrance rosette. Muted limestone, slate, ochre and oxide colors. It occupies
  surrounding ground, never the playable tiles.

Material batches and Godot-generated mesh LODs limit overhead. No collision,
additional light or animation imports are required. Fire uses three crossed
transparent surfaces per existing brazier; the two existing bounded lights remain.
