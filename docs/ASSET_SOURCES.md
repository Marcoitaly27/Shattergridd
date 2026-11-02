# External asset source register

No external model or texture was added in version 0.9. Existing native prototype
resources retain their previous provenance; this document does not invent their
creator, source, license or commercial-use permission.

Copy the following record for each future external model/texture/animation.
Keep unknown fields explicitly unknown until verified. Do not treat “free to
download” as a license or infer that AI-assisted output has cleared rights.

## Record template — not an existing asset

| Field | Record |
| --- | --- |
| Asset name / stable ID | `<fill>` |
| Project paths: original file, wrapper, textures | `<fill>` |
| Source type: original / CC0 / library / AI-assisted / other | `<fill>` |
| Creator / provider | `<fill or unknown>` |
| License name and version | `<fill or unknown>` |
| License text / evidence location | `<fill>` |
| Download / source URL | `<fill or not applicable>` |
| Commercial-use status | `<allowed / restricted / unknown; basis>` |
| Attribution requirement and exact credit | `<fill or none with evidence>` |
| Modifications and author/date | `<cleanup, UV, texture, rig, mesh, scale changes>` |
| Original source archive / revision | `<fill>` |
| For generated content: tool/model/version and supplied inputs | `<fill if applicable>` |
| Review date / reviewer / unresolved restrictions | `<fill>` |

Record variants and derivative textures against their source record. Keep original
source files outside the imported runtime scene when appropriate; record where
Blender/source archives are maintained. No source/library is endorsed here.

## Research candidate — KayKit Knight (not imported)

Reviewed 2026-11-03. The public Adventurers pack contains
`addons/kaykit_character_pack_adventures/Characters/gltf/Knight.glb`.

| Field | Verified research record |
| --- | --- |
| Provider / creator | KayKit Game Assets / Kay Lousberg |
| Repository | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 |
| Character listing | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/tree/main/addons/kaykit_character_pack_adventures/Characters/gltf |
| License | CC0 1.0; personal, educational and commercial use permitted; credit optional |
| Original evidence | https://raw.githubusercontent.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0/main/LICENSE.txt |
| Evidence copy | `docs/asset_research/KayKit-Adventurers-LICENSE.txt` |
| Cost | Public free pack; no EXTRA/SOURCE tier purchase made |
| Project model paths | None: no model, texture, animation, addon or executable imported |
| Modifications | None |
| Fit assessment | Author explicitly describes stylised low-poly characters; substantial modeling/pose/material work required for realistic Warden |
| Status | Possible free modeling base, not approved final SHATTERGRID art |

The source README advertises shields/weapons and rigged characters; shield
separation, rig compatibility, mesh quality and animation suitability have not
been tested locally because the binary assets were not imported. This research
does not certify a ready-to-use realistic Warden or unchanged upstream revisions.
