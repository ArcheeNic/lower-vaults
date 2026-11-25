extends Node3D

const Stage := preload("res://tableaux/stage.gd")
const Foley := preload("res://sound/room_foley.gd")
const Works := preload("res://tableaux/working_machinery.gd")
const Drifts := preload("res://tableaux/drifting_life.gd")

# Each group of pieces is batched once. A whole fish, bell or mechanism then
# moves on a single pivot, including any articulated pieces attached to it.
class Movement:
	var pivot: Node3D
	var rest: Transform3D
	var period: float
	var phase: float
	var displacement: Vector3
	var crosswise: Vector3
	var angle: Vector3
	var turning: bool
	var follow_flow: bool

var movements: Array[Movement] = []
var _batches: Array[Node3D] = []
var _time := 0.
var _voice: Foley
var _cue: StringName
var floor_mounted := false
var wing := Node3D.new()
var _interval := 0.


func assemble(room: Node3D, scene_id: int, focus: Vector3) -> void:
	name = "RoomLife"
	# Fixtures can stand down in a closed court beside the rail. Over an
	# active court their moving pieces and support beams hang above head height.
	var sites: Array[Vector3] = []
	var best := -INF
	for normal: Vector3 in [Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT, Vector3.BACK]:
		var at := normal * 9.7
		var horizontal := absf(normal.z) > .5
		var footprint := Rect2(at.x-6.9 if horizontal else at.x-2.35, at.z-2.35 if horizontal else at.z-6.9,
			13.8 if horizontal else 4.7, 4.7 if horizontal else 13.8)
		var safe := true
		for face: Vector3i in [Vector3i.UP, Vector3i.DOWN]:
			for zone: int in room.ports.get(face, []):
				if footprint.intersects(room._well_rect(zone).grow(.40)):
					safe = false
		if not safe: continue
		sites.append(at)
		var sector := Vector2i(1+roundi(normal.x),1+roundi(normal.z))
		var in_void: bool = not room.has_court(sector)
		# The live pieces face the rail. Favour the side alongside the
		# room's main landmark, with some distance from the landmark itself.
		var spacing := Vector2(focus.x-at.x,focus.z-at.z).length()
		var score := -absf(spacing-10.) + (6. if in_void else 0.)
		if scene_id == 32:
			score = -at.z
		if score > best:
			best = score
			position = at
			rotation.y = atan2(-normal.x, -normal.z)
			floor_mounted = in_void and scene_id not in [2,23,24,32]
	if floor_mounted: position.y = -2.1
	add_child(wing)
	# Give flocks a second pocket of activity towards another side of the
	# room, so the animals pass different landings as the player walks in.
	var other := position
	var furthest := 0.
	for at in sites:
		var sep := at.distance_squared_to(position)
		if sep > furthest:
			furthest = sep
			other = at
	wing.position = transform.affine_inverse() * other
	if furthest > 1.:
		var sector := Vector2i(1+roundi(other.x/9.7),1+roundi(other.z/9.7))
		if not room.has_court(sector): wing.position.y -= 2.35
		wing.rotation.y = atan2(-other.x,-other.z) - rotation.y
	if scene_id >= 18 and scene_id <= 31:
		Drifts.build(self, scene_id)
	else:
		Works.build(self, scene_id)
	for group in _batches:
		group._flush_parts()
		for m in movements:
			if group == m.pivot or m.pivot.is_ancestor_of(group):
				for child in group.get_children():
					if child is MultiMeshInstance3D: child.set_meta("moving_scenery", true)
				break
	_batches.clear()


func pieces(at: Vector3, support: Node3D = self) -> Node3D:
	var group := Stage.new()
	group._body.free()
	group.position = at
	support.add_child(group)
	_batches.append(group)
	return group


func oscillate(pivot: Node3D, period: float, phase: float, displacement := Vector3.ZERO,
		angle := Vector3.ZERO, crosswise := Vector3.ZERO, turning := false) -> void:
	var m := Movement.new()
	m.pivot = pivot
	m.rest = pivot.transform
	m.period = period
	m.phase = phase
	m.displacement = displacement
	m.crosswise = crosswise
	m.angle = angle
	m.turning = turning
	movements.append(m)


# The nose of a swimmer points along local -X. Turn it into the tangent
# of the ellipse, so it sweeps the far bank and comes back facing upstream.
func swim(pivot: Node3D, period: float, phase: float, reach: Vector3, curve: Vector3) -> void:
	oscillate(pivot, period, phase, reach, Vector3.ZERO, curve)
	movements.back().follow_flow = true


func turn(pivot: Node3D, period: float, axis: Vector3) -> void:
	oscillate(pivot, period, 0., Vector3.ZERO, axis, Vector3.ZERO, true)


func sound(cue: StringName, interval: float) -> void:
	_voice = Foley.new()
	_cue = cue
	_voice.position.y = 4.6
	add_child(_voice)
	_interval = interval


func _process(delta: float) -> void:
	var eye := get_viewport().get_camera_3d()
	if not eye or eye.global_position.distance_squared_to(global_position) > 55.*55.:
		return
	var before := _time
	_time = fmod(_time + delta, 86400.)
	for m in movements:
		var theta := TAU*_time/m.period + m.phase
		var wave := sin(theta)
		var transform3 := m.rest
		transform3.origin += m.displacement*wave + m.crosswise*cos(theta)
		if m.follow_flow:
			var tangent := m.displacement*cos(theta) - m.crosswise*wave
			transform3.basis = Basis.from_euler(Vector3(0,atan2(tangent.z,-tangent.x),.16*wave))*m.rest.basis
		else:
			transform3.basis = Basis.from_euler(m.angle*(theta if m.turning else wave))*m.rest.basis
		m.pivot.transform = transform3
	if _voice and floori((_time+_interval*.5)/_interval) != floori((before+_interval*.5)/_interval):
		_voice.strike(_cue)
