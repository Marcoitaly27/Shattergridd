extends Resource

const Cue = preload("res://scripts/audio/audio_cue.gd")
@export var cues: Array[Cue] = []


func find_cue(id: StringName) -> Resource:
	for cue in cues:
		if cue != null and cue.cue_id == id:
			return cue
	return null


func missing_ids() -> Array[StringName]:
	var missing: Array[StringName] = []
	for cue in cues:
		if cue != null and cue.streams().is_empty():
			missing.append(cue.cue_id)
	return missing
