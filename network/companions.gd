extends Node3D

const FIGURE := preload("res://models/surveyor.glb")
const SEND_INTERVAL := 1.0 / 12.0
const STALE_MS := 6500
const SNAP_DISTANCE := 3.0

class Companion extends Node3D:
	var cell: Vector2i
	var local_pose: Transform3D
	var sequence := -1
	var received_at := 0

var _peers := {}
var _session: Node
var _walker: Node3D
var _cells: Dictionary
var _cell_at: Callable
var _send_in := 0.0
var _sequence := 0
var _connected := false


func bind(session: Node, walker: Node3D, cells: Dictionary, cell_at: Callable) -> void:
	process_mode = PROCESS_MODE_ALWAYS # Networking continues in the local pause menu.
	_session = session
	_walker = walker
	_cells = cells
	_cell_at = cell_at
	session.pose_received.connect(_receive_pose)
	session.peer_left.connect(_remove_peer)
	session.status_changed.connect(_set_status)
	set_process(false)


func _set_status(state: String) -> void:
	_connected = state == "online"
	set_process(_connected)
	if not _connected:
		for id: String in _peers.keys():
			_remove_peer(id)
	_send_in = 0.0


func _process(delta: float) -> void:
	_send_in -= delta
	if _send_in <= 0.0:
		_send_in = SEND_INTERVAL
		_send_pose()
	var now := Time.get_ticks_msec()
	for id: String in _peers.keys():
		var peer: Companion = _peers[id]
		if now - peer.received_at > STALE_MS:
			_remove_peer(id)
			continue
		var room := _cells.get(peer.cell) as Node3D
		if not is_instance_valid(room):
			peer.hide()
			continue
		var target := room.global_transform * peer.local_pose
		var distance := target.origin.distance_squared_to(peer.global_position)
		if not peer.visible or distance > SNAP_DISTANCE * SNAP_DISTANCE:
			peer.global_transform = target
		else:
			peer.global_transform = peer.global_transform.interpolate_with(target, 1.0 - exp(-18.0 * delta))
		# Two walkers can share the entrance or pass through each other.
		peer.visible = peer.global_position.distance_squared_to(_walker.global_position) > 0.34 * 0.34


func _send_pose() -> void:
	var cell: Vector2i = _cell_at.call(_walker.position)
	var room := _cells.get(cell) as Node3D
	if not is_instance_valid(room):
		return
	var local := room.global_transform.affine_inverse() * _walker.global_transform
	var at := local.origin
	var q := local.basis.orthonormalized().get_rotation_quaternion()
	_sequence += 1
	_session.send_pose({
		"sequence": _sequence, "cell_x": cell.x, "cell_y": cell.y,
		"px": at.x, "py": at.y, "pz": at.z, "qx": q.x, "qy": q.y, "qz": q.z, "qw": q.w,
	})


func _receive_pose(id: String, pose: Dictionary) -> void:
	if not _connected:
		return
	for key in ["sequence", "cell_x", "cell_y"]:
		if typeof(pose.get(key)) != TYPE_INT:
			return
	for key in ["px", "py", "pz", "qx", "qy", "qz", "qw"]:
		if typeof(pose.get(key)) not in [TYPE_FLOAT, TYPE_INT]:
			return
	if pose.sequence < 0 or pose.cell_x < -2147483648 or pose.cell_x > 2147483647 or pose.cell_y < -2147483648 or pose.cell_y > 2147483647:
		return
	var at := Vector3(pose.px, pose.py, pose.pz)
	var q := Quaternion(pose.qx, pose.qy, pose.qz, pose.qw)
	if not at.is_finite() or at.length_squared() > 128.0 * 128.0 or not q.is_finite() or absf(q.length_squared() - 1.0) > 0.01:
		return
	var peer := _peers.get(id) as Companion
	if peer == null:
		peer = Companion.new()
		peer.hide()
		peer.add_child(FIGURE.instantiate())
		peer.add_child(_shoulder_lamp())
		add_child(peer)
		_peers[id] = peer
	elif pose.sequence <= peer.sequence:
		return
	peer.sequence = pose.sequence
	peer.cell = Vector2i(pose.cell_x, pose.cell_y)
	peer.local_pose = Transform3D(Basis(q.normalized()), at)
	peer.received_at = Time.get_ticks_msec()


# A warm glass lens distinguishes fellow walkers from the archive's surveyors.
func _shoulder_lamp() -> MeshInstance3D:
	var lens := SphereMesh.new()
	lens.radius = 0.072
	lens.height = lens.radius * 2.0
	lens.radial_segments = 12
	lens.rings = 6
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("ffc383")
	brass.emission_enabled = true
	brass.emission = brass.albedo_color
	brass.emission_energy_multiplier = 2.0
	lens.material = brass
	var lamp := MeshInstance3D.new()
	lamp.mesh = lens
	lamp.position = Vector3(-0.23, 1.39, -0.06)
	return lamp


func _remove_peer(id: String) -> void:
	var peer := _peers.get(id) as Companion
	if peer != null:
		peer.hide()
		peer.queue_free()
		_peers.erase(id)
