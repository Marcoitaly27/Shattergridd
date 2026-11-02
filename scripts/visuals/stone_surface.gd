@tool
extends Resource
## Real PBR maps only; no procedural texture generation or final weathering shader.

@export var base_color: Color = Color(0.64, 0.63, 0.58)
@export_range(0, 1) var roughness: float = 0.95
@export_range(0, 1) var metallic: float = 0.0
@export var albedo: Texture2D
@export var normal: Texture2D
@export_range(0, 2) var normal_strength: float = 0.8
@export var roughness_map: Texture2D
@export var metallic_map: Texture2D
@export var ambient_occlusion: Texture2D
## Packed glTF convention: occlusion R, roughness G, metallic B.
@export var packed_orm: Texture2D
@export var height: Texture2D
@export var enable_parallax: bool = false
@export var weathering_mask: Texture2D
@export var weathering_albedo: Texture2D
@export var weathering_normal: Texture2D
@export var emission: Color = Color.BLACK
@export_range(0, 0.25) var emission_energy: float = 0.05


func build_material(tint: Color = Color.WHITE) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = "Instance stone surface"
	material.albedo_color = base_color * tint
	material.albedo_texture = albedo
	material.roughness = roughness if roughness_map == null and packed_orm == null else 1.0
	material.metallic = metallic if metallic_map == null and packed_orm == null else 1.0
	material.roughness_texture = roughness_map if packed_orm == null else packed_orm
	material.metallic_texture = metallic_map if packed_orm == null else packed_orm
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED if packed_orm == null else BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED if packed_orm == null else BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.ao_enabled = ambient_occlusion != null or packed_orm != null
	material.ao_texture = ambient_occlusion if packed_orm == null else packed_orm
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.normal_enabled = normal != null
	material.normal_texture = normal
	material.normal_scale = normal_strength
	material.heightmap_enabled = enable_parallax and height != null
	material.heightmap_texture = height
	material.detail_enabled = weathering_albedo != null or weathering_normal != null
	material.detail_mask = weathering_mask
	material.detail_albedo = weathering_albedo
	material.detail_normal = weathering_normal
	material.emission_enabled = emission != Color.BLACK
	material.emission = emission
	material.emission_energy_multiplier = emission_energy
	return material
