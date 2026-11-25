extends Node3D

const ModularRoom := preload("res://world/modular_room.gd")
const FogShader := preload("res://world/dark_trail.gdshader")
const MAX_HEALTH := 100.
const DAMAGE_PER_SECOND := 8.
const SPACING := 1.1
const MAX_LINK := 1.8
const HALL_RADIUS := 2.4
const RISE_SECONDS := 4.
const BUCKET_SIZE := 14.

class Knot:
	var point: Vector3
	var radius: float
	var headroom: float
	var storey_y: float
	var age := -1.
	var height := 0.

class Segment:
	var start: Knot
	var end: Knot
	var fog: FogVolume

	func update_height() -> void:
		if fog:
			fog.material.set_shader_parameter("rise", Vector2(start.height, end.height))
			fog.visible = start.height > .001 or end.height > .001

	func exposure_at(feet: Vector3, body_height: float) -> float:
		var a := Vector2(start.point.x, start.point.z)
		var axis := Vector2(end.point.x, end.point.z) - a
		var offset := Vector2(feet.x, feet.z) - a
		var t := clampf(offset.dot(axis) / maxf(.00001, axis.length_squared()), 0., 1.)
		var radial := (offset - t * axis).length() / lerpf(start.radius, end.radius, t)
		if radial >= 1.:
			return 0.
		var base := lerpf(start.point.y, end.point.y, t)
		var depth := lerpf(start.height, end.height, t) * sqrt(1. - radial * radial)
		var overlap := minf(feet.y + body_height, base + depth) - maxf(feet.y, base)
		return smoothstep(0., .30, overlap) * (1. - smoothstep(.82, 1., radial))

var walker_rid: RID
var health := MAX_HEALTH
var exposure := 0.
var _last_knot: Knot
var _buckets := {}
var _visible_buckets := {}
var _fresh: Array[Knot] = []
var _rising: Array[Segment] = []
var _last_bucket := Vector3i.MAX


func _show_segment(segment: Segment) -> void:
	var a := segment.start
	var b := segment.end
	var radius := maxf(a.radius, b.radius)
	var low := a.point.min(b.point) - Vector3(radius, .05, radius)
	var high := a.point.max(b.point) + Vector3(radius, 0., radius)
	high.y = maxf(a.point.y + a.headroom, b.point.y + b.headroom)
	var fog := FogVolume.new()
	fog.size = high - low
	fog.position = (high + low) * .5
	var material := ShaderMaterial.new()
	material.shader = FogShader
	material.set_shader_parameter("start", Vector4(a.point.x, a.point.y, a.point.z, a.radius))
	material.set_shader_parameter("end_point", Vector4(b.point.x, b.point.y, b.point.z, b.radius))
	fog.material = material
	segment.fog = fog
	segment.update_height()
	add_child(fog)


func _update_visible(center: Vector3i) -> void:
	if center == _last_bucket:
		return
	_last_bucket = center
	var nearby := {}
	for x in range(-2, 3):
		for y in range(-2, 3):
			for z in range(-2, 3):
				var key := center + Vector3i(x, y, z)
				nearby[key] = true
				if not _visible_buckets.has(key):
					for segment: Segment in _buckets.get(key, []):
						_show_segment(segment)
	for key: Vector3i in _visible_buckets:
		if not nearby.has(key):
			for segment: Segment in _buckets.get(key, []):
				segment.fog.queue_free()
				segment.fog = null
	_visible_buckets = nearby


func _grow(point: Vector3, delta: float) -> void:
	for i in range(_fresh.size() - 1, -1, -1):
		var knot := _fresh[i]
		if knot.age < 0.:
			if point.distance_to(knot.point) < knot.radius + .65:
				continue
			knot.age = 0.
		knot.age = minf(knot.age + delta, RISE_SECONDS)
		knot.height = knot.headroom * smoothstep(0., RISE_SECONDS, knot.age)
		if knot.age >= RISE_SECONDS:
			_fresh.remove_at(i)
	for i in range(_rising.size() - 1, -1, -1):
		var segment := _rising[i]
		segment.update_height()
		if segment.start.age >= RISE_SECONDS and segment.end.age >= RISE_SECONDS:
			_rising.remove_at(i)


func _record(point: Vector3, bucket: Vector3i, room: ModularRoom) -> void:
	var knot := Knot.new()
	knot.point = point
	var local := room.to_local(point)
	knot.radius = ModularRoom.WIDTH * .9 if room.on_flight(local) else HALL_RADIUS
	# The room cap also applies at open stairwells. Lower landings and beams
	# can limit the height further, even within a single modular room.
	knot.storey_y = room.global_position.y
	var ceiling := knot.storey_y + ModularRoom.SIZE.y * .5
	var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * .12,
		Vector3(point.x, maxf(point.y + .13, ceiling), point.z), 1)
	ray.exclude = [walker_rid]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		ceiling = minf(ceiling, hit.position.y)
	knot.headroom = maxf(0., ceiling - point.y) * .8
	var segment := Segment.new()
	segment.start = knot
	if _last_knot and _last_knot.storey_y == knot.storey_y and point.distance_to(_last_knot.point) <= MAX_LINK:
		segment.start = _last_knot
	segment.end = knot
	_last_knot = knot
	_fresh.append(knot)
	_rising.append(segment)
	if not _buckets.has(bucket):
		_buckets[bucket] = []
	_buckets[bucket].append(segment)
	_show_segment(segment)


func advance(point: Vector3, grounded: bool, delta: float, room: ModularRoom, body_height: float) -> void:
	var bucket := Vector3i((point / BUCKET_SIZE).floor())
	_update_visible(bucket)
	_grow(point, delta)
	exposure = 0.
	var nearest: Knot
	var nearest_dist := SPACING * SPACING
	# Segments are indexed by their endpoint. The base may be one storey
	# below the walker, including when the walker is in the air.
	var reach := HALL_RADIUS + MAX_LINK
	var low := Vector3i(((point - Vector3(reach, ModularRoom.SIZE.y + MAX_LINK, reach)) / BUCKET_SIZE).floor())
	var high := Vector3i(((point + Vector3(reach, body_height + MAX_LINK, reach)) / BUCKET_SIZE).floor())
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			for z in range(low.z, high.z + 1):
				for segment: Segment in _buckets.get(Vector3i(x, y, z), []):
					exposure = maxf(exposure, segment.exposure_at(point, body_height))
					var distance := segment.end.point.distance_squared_to(point)
					if distance <= nearest_dist:
						nearest_dist = distance
						nearest = segment.end
	health = maxf(0., health - DAMAGE_PER_SECOND * exposure * delta)
	if not grounded or not room:
		_last_knot = null
	elif nearest:
		_last_knot = nearest
	else:
		_record(point, bucket, room)
