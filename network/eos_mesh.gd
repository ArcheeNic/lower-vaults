extends RefCounted

signal peer_left(user_id: String)
signal pose_received(user_id: String, pose: Dictionary)
signal connections_changed

# The socket name includes the lobby ID and the bucket includes the wire version.
const FLOAT_FIELDS := ["px", "py", "pz", "qx", "qy", "qz", "qw"]
const PACKET_SIZE := 40
const DIAL_INTERVAL_MS := 5000

var _peer: Variant
var _local_user := ""
var _members: Dictionary = {}
var _connected: Dictionary = {}
var _next_dial := 0

func open(lobby_id: String, user_id: String) -> bool:
	_local_user = user_id
	_peer = ClassDB.instantiate("EOSGMultiplayerPeer")
	_peer.set_auto_accept_connection_requests(false)
	_peer.set_allow_delayed_delivery(true)
	_peer.incoming_connection_request.connect(_on_request)
	_peer.peer_connected.connect(_on_connected)
	_peer.peer_disconnected.connect(_on_disconnected)
	var err: int = _peer.create_mesh("LV" + lobby_id.sha256_text().left(24))
	if err != OK:
		_peer = null
		return false
	_peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
	_peer.set_target_peer(0)
	return true

func close() -> void:
	if _peer:
		for id in _peer.get_all_peers():
			_peer.disconnect_peer(id, true)
		_peer.close()
		_peer = null
	_members.clear()
	_connected.clear()

func set_members(members: Dictionary) -> void:
	if members == _members:
		return
	_members = members
	for id in _connected.keys():
		if not _members.has(_connected[id]):
			_peer.disconnect_peer(id, true)
	_next_dial = 0

func has_walkers() -> bool:
	return not _connected.is_empty()

func poll() -> void:
	_peer.poll()
	if Time.get_ticks_msec() >= _next_dial:
		_next_dial = Time.get_ticks_msec() + DIAL_INTERVAL_MS
		# One dialer per pair. Both sides still exchange EOSG peer IDs.
		for user_id: String in _members:
			if _local_user < user_id and not _peer.has_user_id(user_id):
				_peer.add_mesh_peer(user_id)
		for user_id: String in _peer.get_all_connection_requests():
			if _members.has(user_id):
				_peer.accept_connection_request(user_id)
	for _i in mini(128, _peer.get_available_packet_count()):
		var id: int = _peer.get_packet_peer()
		var packet: PackedByteArray = _peer.get_packet()
		if _connected.has(id):
			var pose := decode_pose(packet)
			if not pose.is_empty():
				pose_received.emit(_connected[id], pose)

func send_pose(pose: Dictionary) -> void:
	if has_walkers():
		_peer.put_packet(encode_pose(pose))

static func encode_pose(pose: Dictionary) -> PackedByteArray:
	var packet := PackedByteArray()
	packet.resize(PACKET_SIZE)
	packet.encode_u32(0, pose.sequence)
	packet.encode_s32(4, pose.cell_x)
	packet.encode_s32(8, pose.cell_y)
	for i in FLOAT_FIELDS.size():
		packet.encode_float(12 + 4 * i, pose[FLOAT_FIELDS[i]])
	return packet

static func decode_pose(packet: PackedByteArray) -> Dictionary:
	if packet.size() != PACKET_SIZE:
		return {}
	var pose := {"sequence": packet.decode_u32(0), "cell_x": packet.decode_s32(4), "cell_y": packet.decode_s32(8)}
	for i in FLOAT_FIELDS.size():
		var value := packet.decode_float(12 + 4 * i)
		if not is_finite(value):
			return {}
		pose[FLOAT_FIELDS[i]] = value
	return pose

func _on_request(data: Dictionary) -> void:
	if _members.has(data.remote_user_id):
		_peer.accept_connection_request(data.remote_user_id)
	else:
		# Lobby member notifications can arrive after the first connection request.
		# A legitimate dialer will retry once the member list is up to date.
		_peer.deny_connection_request(data.remote_user_id)

func _on_connected(id: int) -> void:
	var user_id: String = _peer.get_peer_user_id(id)
	if not _members.has(user_id):
		_peer.disconnect_peer(id, true)
		return
	_connected[id] = user_id
	connections_changed.emit()

func _on_disconnected(id: int) -> void:
	if _connected.has(id):
		var user_id: String = _connected[id]
		_connected.erase(id)
		peer_left.emit(user_id)
		connections_changed.emit()
