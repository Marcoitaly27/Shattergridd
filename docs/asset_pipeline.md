# SHATTERGRID 0.9 — external 3D assets and PBR pipeline

Systems provide integration; production assets provide detail. Detailed armor,
anatomy, cloth, weapons, creatures and ruins belong in external asset production,
not in increasingly elaborate Godot primitive generators.

## Audit of the actual repository

Starting revision: `dcfcc82` (0.8). All eight existing native suites passed before
changes: **3,636 runtime checks**.

| Area | Actual starting state / disposition |
| --- | --- |
| Structure / launch | Working: builder → match; separate F6 cinematic lab |
| CharacterDefinition / loadouts | Working data-driven identity, category, model/movement/capture/audio references; independent reflected loadouts |
| Character scenes | Six explicitly named native primitive prototypes, not production sculptures |
| Visual attachment | Existing `Piece/Visuals/Model`; model loading separated from logical coordinates, but corrections/picking/material selection incomplete |
| Board / environment | Working 8×8 logical board, tile picking; independently replaceable suspended shell/settlement/landmarks |
| Capture / camera | Working six procedural behaviors, authoritative impact/shatter, fitted close views and exact strategic restoration |
| Destruction | Temporary bounded chunks/dust, not actual fractured source meshes |
| Audio | Working optional profiles/buses/hooks; **no real recordings** |
| Materials / shaders | Native StandardMaterial3D, small existing NoiseTextures; no custom shaders or imported PBR maps |
| Imported models / rigs | **None**: no GLB/GLTF/FBX/Blender files or production skeletal animation |
| Collision | Prototype compound primitive proxies; no collision in distant world. Production proxy/import boundaries needed extension |
| Lighting | Existing cold key/fill, fog and two braziers, preserved |
| Tools | F3/F4 diagnostics, performance probe and regression suites, preserved/extended |

No broken baseline system required repair. Hex remains absent. No new characters,
roster decisions, lore, balance rules, progression, models or texture images were
created/downloaded. Actual GLB re-import, skinning and real-texture appearance
cannot be claimed without real assets; the replacement test uses existing native
resources only.

## Stable character structure and configuration

The existing name **Visuals** is the equivalent of VisualRoot; it was retained to
preserve scene/capture compatibility:

```text
Piece                            logical ID, owner, coordinate, statuses
  PickBody                       simple interaction shapes, layer 2
  SelectionRing / ArmyMark       interaction identity
  Visuals                        army facing and transient cinematic transforms
    Model                        wrapper + per-definition correction transform
      AssetRoot
        ImportedCharacter        future real GLB instance
      PickAnchor                 visible torso/selection point
      InteractionProxy(s)         Shape3D authoring data, not physics bodies
      EffectsAnchor / AudioAnchor
      AnimationPlayer            optional, configured path/library
      AnimationTree              optional, artist-owned
```

Duplicate `scenes/assets/CHR_VisualWrapper_Template.tscn` for a real character.
It deliberately contains **no model or fake imported reference**. The Capsule
proxy and markers are editable configuration, not a pretend production statue.
Keep the imported GLB as an external child; do not edit its generated contents.
`CharacterDefinition.model_scene` references the wrapper. The legacy script path
`placeholder_visual.gd` now hosts the reusable adapter; it is not a new modeler.

New optional definition fields:

- `visual_scale`, `visual_offset`, `visual_rotation_degrees`: affect Model only.
- `paired_model_scene`: alternate art for reflected member 1, same gameplay choice.
- `prototype_visual`: development stage label; all current definitions remain true.
- `picking_mode`: bounds, authored proxies, or legacy primitive parts.
- `framing_bounds`: optional conservative **model-local** animation/deformation AABB.
- `animation_config`: wrapper-local player/tree paths and conceptual state→clip map.
- `team_material_mode`, `team_surface_names`, `stone_material_profile`, `team_tints`:
  controlled material integration. Existing team palette remains supported.

No animation/VFX/audio file is invented for an empty optional field. AudioProfile
and capture behavior remain independent shared data. Wrapper anchors are future
attachment points; no empty VFX manager or final animation system was added.

`Piece.replace_visual(packed_scene)` demonstrates an instance-only art replacement
without editing its CharacterDefinition, board, turn, ability or objective data.
It refreshes picking and refuses replacement while movement/capture is active.
Passing null returns to the configured model. Normal authoring changes the
wrapper/definition before play; shared definitions should not be mutated mid-action.

## Scale, orientation and pivots

Use **1 unit ≈ 1 metre**. Forward is **local −Z**, up is +Y. Slate faces the opposing
army through Visuals' Y rotation; Model's export correction remains separate.

| Quantity | Current / recommended convention |
| --- | --- |
| Tile centre spacing | 1.5 m, unchanged |
| Visible stone tile width / height | 1.455 m / 0.24 m, unchanged |
| Recommended character footprint incl. weapon/rest pose | ≤1.35–1.40 m; soft review warning beyond ±0.72 m |
| Current prototypes | Deliberately compact, roughly 0.7–1.8 m; not resized in this pass |
| Future ordinary humanoid | Approximately 1.8–2.2 m |
| Future large humanoid | Approximately 2.2–2.6 m; review near 3 m |
| Low creature | Different proportions, same logical tile footprint |

The origin is ground-centred. The Piece already sits on its tile's top; do not
compensate by changing board placement. Correct pivot/units in Blender first,
then use a small Model offset/rotation if necessary. Use positive scale. Nonpositive
scales are warned about and sanitized on integration. Oversized or off-centre
assets generate development warnings, not new occupancy rules.

Use a paired wrapper/model variant, alternate pose or safe weapon orientation for
reflection. Do not negate a skeleton's scale. `paired_model_scene` provides the
first safe variant hook; it never changes the character ID or deployment role.

## Preferred GLB workflow / replace one placeholder

1. Produce/source the asset externally. Record source/license information using
   [ASSET_SOURCES.md](ASSET_SOURCES.md); preserve an original source revision.
2. Clean topology and transforms in Blender, remove hidden/unneeded parts, UV
   unwrap, check normals/tangents, set metric scale and a ground-centred pivot.
3. Author real PBR textures; rig/animate only if needed. Export a real GLB/GLTF.
   No special Blender direct-import dependency is required by this project.
4. Add it under a future `assets/characters/<id>/source/` folder when the file
   exists. Let Godot import; inspect scale, mesh/material names, skeleton and clips.
   Avoid automatic `-col`/`-convcol` collision generation for character visuals.
5. Duplicate the character wrapper template as e.g. `CHR_Executioner_Visual.tscn`.
   Instantiate the GLB under AssetRoot. Keep re-imported internals intact. Put
   project-specific materials, proxy data and event libraries in the wrapper.
6. Move PickAnchor to a visible torso point. Fit a few InteractionProxy nodes with
   Box/Capsule/Sphere/Cylinder Shape3D resources. The adapter duplicates/bakes
   their scale into the real PickBody without modifying the source Shape3D.
7. On the existing Executioner definition, change **only** `model_scene` to that
   wrapper and configure visual correction, `prototype_visual = false`, and
   picking mode Authored proxies or Bounds. Leave character ID, category,
   movement, ability, Core flag and loadout selection unchanged.
8. Choose Keep authored or Named surfaces material mode. Configure real stone
   textures/team variants only on intended surfaces. Test both owners and both
   reflected members. Leave old placeholder scenes available for fallback/review.
9. If real attack clips exist, configure animation integration below. Otherwise
   retain the existing procedural capture behavior. Validate with F7 and suites.
10. Re-export the source GLB and re-import it once. The wrapper's settings should
    survive. Recheck named surfaces, node paths, proxies, bounds and animation
    markers if the source hierarchy changed. Commit `.import` configuration where
    applicable, never generated `.godot` caches.

Future prefixes: `CHR_`, `ENV_`, `PROP_`, `MAT_`, `VFX_`, `SFX_`. Prefer stable IDs
and names, with `_Visual`, `_Collision`, `_LOD1` and map suffixes where useful.
Existing hundreds of files were not renamed. Current six scene roots now also
carry `asset_stage = prototype`; normal gameplay shows no ugly prototype labels.

## Animation integration and event timing

`VisualAnimation` adapts an optional AnimationPlayer/AnimationTree. Conceptual
requests use `Piece.request_visual_animation(&"idle")`, `move`, `capture_attack`,
`ability`, `reaction`, `victory` or another configured state. Move/idle are wired
for normal movement. Other future states can be requested without a roster switch.
A custom wrapper may implement `request_animation_state(state)` for an artist-owned
AnimationTree. Tree configuration is optional; no state-machine framework is forced.

For an authored capture:

1. Configure `AnimationConfig.player_path` relative to Model and map
   `states[&"capture_attack"]` to an existing non-looping clip.
2. Keep a project-owned copy of the clip/library for custom method tracks, or
   another non-destructive wrapper-owned animation resource. Do not edit generated
   GLB animation resources in place and expect those edits to survive re-import.
   Keep original skeleton tracks/paths and event additions under source control.
3. A method track targets the wrapper root's
   `report_animation_event(&"impact")`. Relative paths use AnimationPlayer.root_node;
   the target must be **Model itself**. Add `anticipation`, `swing` and `recovery`
   markers as appropriate. This root relays events to the visual adapter.
4. Keep tracks inside Model. They may animate bones/visuals, never Piece, Board,
   GameManager or other scene objects. Use in-place clips; gameplay owns board
   translation/settling. Root-motion-driven gameplay was not introduced.
5. Provide RESET/idle or a clean first/rest frame, and conservative framing bounds
   for animated extents. Fit clips against the existing capture recovery/settle.

A valid event clip automatically selects the authored capture behavior. The
existing director keeps its camera, lock, completion and monotonic timeline.
It manually advances AnimationPlayer on that same clock; method callbacks are
immediate. The impact marker triggers shake, sound hooks, cracks, shatter, debris
and optional local hit pause. Duplicate impact markers resolve only once.
Prior player process/speed/pose and optional AnimationTree activation are restored.
No arbitrary “wait 0.73 seconds” controls the authored impact.

Missing clips/impact relay or out-of-model tracks are warned about and retain the
existing procedural fallback. A final defensive clip-end resolution prevents a
corrupt relay from leaving occupancy unresolved; valid clips use the authored
marker. The six current Tween behaviors remain exclusively prototype presentation.
No final skeletal animation, rig or animation asset was authored in this pass.

## PBR stone and team materials

`resources/visuals/MAT_StoneSurface_Template.tres` is a **configuration Resource**,
not a fake texture/material scan. Duplicate it and assign real maps. It builds
StandardMaterial3D instances with base colour, albedo, normal strength, roughness,
metallic, AO, optional height/parallax, native detail weathering mask/albedo/normal
and extremely restrained optional emission. Empty maps remain disabled.

Packed glTF ORM uses AO **R**, roughness **G**, metallic **B**. Separate maps use
red. Base colour is sRGB; normals and masks are linear data. Verify normal-map Y
orientation on import. Height/parallax is off by default and needs Compatibility
renderer/performance review. Moss/dirt/cracks may be baked into real maps or a
native detail layer/mask; no custom final shader or huge weathering system exists.

Material modes:

- Keep authored: preserve the imported look.
- Whole mesh prototype: preserve the existing two-stone treatment for the six
  prototypes; not the recommended production approach for mixed metal/cloth.
- Named surfaces: match authored material resource names in `team_surface_names`.
  Unmatched metal/cloth/etc remain authored. The selected team Material or optional
  stone profile applies only to named stone surfaces.

Overrides are on MeshInstance3D, not shared mesh surface resources. Tinting copies
only the material and shares textures; stone profiles build a new instance.
`set_instance_tint` cannot recolour another piece. Team palette/tints and one/two
pedestal marks preserve readability without red/blue full-body paint. A real model
should use a few stable authored material names to survive re-import.

## Environment and collision

Duplicate `ENV_VisualWrapper_Template.tscn`, assign a real future source scene and
configure correction, category, visibility range and shadows. Categories are
structural arena, background architecture, props, vegetation, VFX and lighting.
There is no gameplay reference. Existing visual modules already separate arena
shell, settlement and landmarks; replacing them does not change BoardState.

Imported source collision is made inert: zero layers/masks, disabled shapes,
frozen rigid bodies and disabled Area monitoring. Source colliders are still
reported for cleanup. Gameplay pieces use their separate simple PickBody, not
render triangles. The legacy compound-part path is only for native primitives;
other meshes safely fall back to one bounds proxy.

Most scenery needs **no collision**. Structural gameplay collision should be
simple, wrapper/game-owned and separate from imported visual meshes. The existing
tile/slab collision remains authoritative for fragments. Never add a distant
catch floor. Native visibility ranges are supported on environment wrappers;
playable hero meshes should use no finite disappearance range.

## Production budgets and workflow checklists

Review targets, not enforced rules:

| Asset class | Starting triangle guideline | Texture guideline |
| --- | --- | --- |
| Hero statue / close capture | 20–60k, silhouette-first; profile all 16 + shadows | Usually 2K; 4K only when capture detail justifies it |
| Important arena modules | 10–50k per significant module | Tiling 1K–2K / sensible trim sheets |
| Mid-distance ruined building | 2–15k | 512–1K, up to 2K for a landmark |
| Far skyline / cliff silhouette | 100–2k | 256–512 or shared palette/atlas |
| Props / vegetation | Importance/distance-dependent | Shared textures, sensible alpha cost |

Use Godot's imported mesh LOD generation where it preserves silhouette/rig quality;
review transitions at strategic and close camera distances. No elaborate LOD
manager or aggressive hero culling was added. A 4K RGBA texture is about 64 MiB
uncompressed, ~85 MiB with mipmaps; several maps multiply that cost. Prefer ORM
packing, texture sharing and appropriate desktop compression, not automatic 4K.

Character checklist: concept → external model → topology/UV → real PBR textures
→ optional rig/animations → GLB export → Godot wrapper → scale/orientation/pivot
→ proxy/markers → state/event integration → existing definition reference → both
armies/reflected positions → strategic readability → capture/audio/destruction
→ Core/restart → GPU/memory/LOD review → source-register update.

Environment checklist: source/license record → external cleanup → scale/pivot/UV
→ real materials → GLB import → wrapper/category → simple collision only if needed
→ range/LOD/shadows → optional existing audio hooks → atmosphere/readability and
capture-camera clearance → performance and re-import test.

## Replacement proof, tools, files and validation

`tests/asset_smoke.gd` uses existing native scenes and **RAM-only** wrapper/clip
fixtures. It does not save models, animations or textures and adds no roster entry.
It replaces an Executioner's visual with the existing Witch, completes a capture
and earns Blood Step; replaces a Core's visual with Wyrm and still ends the match;
swaps a chapel through an environment wrapper and still moves/advances turns.

It also tests correction/proxy isolation, material ownership/named surfaces, ORM
channel configuration, positive-scale pair variants, disabled source collision,
missing/unsafe animation fallback, and actual AnimationPlayer impact markers at
**two different clip times**. Both resolve once, restore player/camera state and
retain audio hooks. Restart during manual playback cleans the entire old context.

F7 toggles the development asset inspector within the existing overlay: selected
character ID, actual model scene, correction, animation source, material/team
mode, reflected member, stage and warnings. F3 hides the overlay; release builds
and `enabled = false` create no production inspection UI.

Created: `scripts/visuals/` helpers/configuration/validation/animation/proxy/stone/
environment/wrapper adapters; authored capture behavior and Resource; character
and environment wrapper templates; stone configuration template; asset smoke suite;
this guide and the source-register template; script UIDs.

Modified: CharacterDefinition visual fields, existing visual adapter and Piece
hooks, CaptureContext integration, F7 debug UI, prototype stage metadata on six
scenes, project version and README. GameManager, board/turn/status/loadout rules,
CaptureDirector, existing capture behaviors, audio architecture, actual stone
materials and environment composition were preserved.

Verification on Godot 4.6.3: all nine headless suites passed **3,702 checks**;
seven OpenGL Compatibility suites passed **2,240 checks**, including the new
66-check asset suite. No GDScript errors or failed checks were reported. The
editor import completed; all **316** local resource references resolved and
`git diff --check` passed. F7 was inspected at 960×666 with the existing board
and prototypes. The renderer used software Mesa; this is not a GPU benchmark.

Actual GLB import,
real PBR texture fidelity, skinned animation bounds and re-import compatibility
remain manual integration checks once a genuine asset is supplied. Audio still
has no recordings and Hex remains absent. Version 0.10 was not started.

## Exact manual review

1. Pull with Godot closed; reopen project and F5 → confirm armies → START MATCH.
   Existing six prototypes and atmosphere should look unchanged. Move/capture for
   both players, test friendly blocking, hints and one turn per action.
2. Select a piece and F7. Inspect scene/scale/offset/animation/material/stage.
   Current prototypes should show procedural animation and no integration warnings.
   F3 hides it; these labels never appear in normal gameplay by themselves.
3. F6 capture lab, 1–6/C/Enter: existing six captures and Core victory still work;
   R/rematch/return reset positions, statuses, debris, camera and audio scope.
4. For one real GLB, follow the numbered replacement workflow. Check exact ground
   contact, −Z forward, both armies and both reflected slots; click on the torso
   and edge tiles. Proxy counts should remain small, regardless of mesh detail.
5. Test material modes and named stone surfaces: preserve metal/cloth, distinguish
   armies and adjust one instance without recolouring the others.
6. Configure a real event clip. Check anticipation/swing/impact/recovery sync,
   audio/destruction/shake at the authored impact, one capture/turn, exact camera
   return and cancellation by R. Test all corners and largest visual bounds.
7. Re-export/re-import the source once. Wrapper correction/proxy/team/event data
   must survive; repair changed source node/material names in the wrapper.
8. Replace one background module through an environment wrapper. Check no distant
   collision, useful visibility range, silhouette scale/fog and no camera clipping.
9. Review real normals/roughness/ORM/masks, texture memory, LODs and frame rate on
   Windows/Godot 4.7. Cloud tests with native fixtures are not a production-art or
   local GPU certification.
