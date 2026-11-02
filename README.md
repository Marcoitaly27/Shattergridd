# SHATTERGRID · 0.1

First static 3D battlefield prototype for Godot 4. A suspended stone sanctuary,
64 individually generated tiles, and two opposing lines of eight temporary
stone figures. This version has **no gameplay or interactive controls**.

## Open and play

Import `project.godot` in **Godot 4.3 or later** and press **F6** from
`scenes/main.tscn`, or **F5 / Play** from anywhere. The main scene is configured.
Validated with Godot **4.6.3**, using the Compatibility renderer. No external
assets, plugins, packages, or export templates are required to run the project.

The perspective camera is fixed. All tiles, both armies, and the floating
platform should fit on screen. Ash figures have square crowns; darker slate
figures have pointed hoods. These are intentionally simple, temporary markers,
not the designs for the eventual characters.

## Structure

- `scenes/main.tscn`: composition, 16 placed piece instances, camera and lighting.
- `scenes/board/` and `scripts/board/`: deterministic 8×8 masonry generation,
  individually beveled tiles, rim courses and suspended foundation.
- `scenes/pieces/` and `scripts/pieces/`: piece root and separate primitive visual.
- `materials/`: native noise, stone color gradients and subtle normal mapping.
- `environments/`: dark sky, ambient light and native non-volumetric fog.
- `assets/` and `effects/`: reserved for later models, audio and effects.
- `tests/battlefield_smoke.gd`: native scene integration checks.

The battlefield builds its meshes on scene load, including in the editor through
`@tool`. Generated children are not serialized. Reopen the scene after changing
generation code to rebuild it; do not hand-edit generated children.
The fixed random seed makes the small wear and surface variations repeatable.

Each piece root carries a unique `piece_id`, `army`, and `grid_coordinate`.
Positions are authored in the main scene; coordinates are descriptive data in
0.1, not an implemented movement system. Cell `(0, 0)` is at `(-5.25, 0, -5.25)`;
tile spacing is 1.5. `battlefield.gd.grid_to_local()` supplies tile-top centers.

To introduce a future statue, duplicate/inherit the piece scene, preserve the
root and replace its `Visuals` child with the model scene. The root does not
depend on primitive node paths or overwrite imported model materials. A visual
may optionally implement `set_army(int)`. Its own AnimationPlayer, effects and
audio can live below `Visuals`. Unique movement, turns, captures, destruction
and victory systems are deliberately left for later versions.

## Validate

Run from the repository root:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://tests/battlefield_smoke.gd
godot --headless --path . --quit-after 10
```

The integration check verifies resource loading, all 64 coordinates, 16 unique
piece identities, eight pieces per army, opposite starting edges, placement,
silhouettes, perspective framing including the foundation, fog and key light.
It returns a nonzero exit code on failure. Headless checks do not validate
rendered appearance; inspect that in the editor or a normal Play session.

On a cloud machine with a read-only home directory, set writable native cache
and configuration paths before running Godot:

```sh
export XDG_CACHE_HOME=/workspace/.cache
export XDG_CONFIG_HOME=/workspace/.config
export XDG_DATA_HOME=/workspace/.local/share
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
```

Visual review: check the whole board is visible, both stone palettes and armies
are distinguishable, the underside floats against the dark background, and fog
does not obscure the playable surface. GPU rendering and lighting may vary
slightly by platform. Realistic statues, ruins, cinematic destruction, and
gameplay are outside the scope of 0.1.
