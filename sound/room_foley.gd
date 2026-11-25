extends AudioStreamPlayer3D

# Clip, reference gain (dB) and pitch at the moving part.
const CUES := {
	&"clock": [preload("res://sound/fixtures/clock.ogg"), -14., 1.0],
	&"balance": [preload("res://sound/fixtures/clock.ogg"), -15., .65],
	&"loom": [preload("res://sound/fixtures/shuttle.ogg"), -12., 1.0],
	&"press": [preload("res://sound/fixtures/machine.ogg"), -10., 1.0],
	&"bell": [preload("res://sound/fixtures/bell.ogg"), -15., 1.0],
	&"fork": [preload("res://sound/fixtures/fork.ogg"), -16., 1.0],
	&"drip": [preload("res://sound/fixtures/water.ogg"), -12., 1.05],
	&"vent": [preload("res://sound/fixtures/vent.ogg"), -11., 1.0],
	&"rustle": [preload("res://sound/fixtures/rustle.ogg"), -13., 1.0],
}

var _walker: CharacterBody3D
var _soundscape: Node
var _gain: float


func _ready() -> void:
	unit_size = 5.
	max_distance = 26.
	attenuation_filter_cutoff_hz = 3700.
	attenuation_filter_db = -12.
	finished.connect(set_process.bind(false))
	set_process(false)


func strike(cue: StringName) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera or camera.global_position.distance_squared_to(global_position) > max_distance * max_distance:
		return
	var walker := camera.get_parent() as CharacterBody3D
	if not walker or not walker.has_method("is_walking") or not walker.is_walking():
		return
	# Closed faces can put another fixture only one storey above the listener.
	var room: Node3D = walker.get("surface")
	if not is_instance_valid(room) or not room.is_ancestor_of(self):
		return
	_walker = walker
	_soundscape = walker.get_parent().get("soundscape")
	var voice: Array = CUES[cue]
	stream = voice[0]
	_gain = voice[1]
	pitch_scale = voice[2]
	volume_db = _gain + _soundscape.room_duck_db()
	play()
	set_process(true)


func _process(_delta: float) -> void:
	if not _walker.is_walking():
		stop()
		set_process(false)
		return
	volume_db = _gain + _soundscape.room_duck_db()
