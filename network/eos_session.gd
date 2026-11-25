extends Node

signal status_changed(state: String)
signal peer_left(peer_id: String)
signal pose_received(peer_id: String, pose: Dictionary)

const Config := preload("res://network/eos_config.gd")
const WalkMesh := preload("res://network/eos_mesh.gd")
const BUCKET_PREFIX := "lower-vaults-v1-"
const MAX_PLAYERS := 8
const EOS_SUCCESS := 0
const EOS_INVALID_USER := 3
const EOS_ALREADY_CONFIGURED := 15
const EOS_NOT_FOUND := 18
const EOS_DUPLICATE_NOT_ALLOWED := 24
const EOS_LOBBY_TOO_MANY_PLAYERS := 9004
const EOS_LOBBY_INVALID_SESSION := 9006
const EOS_DEVICE_ID_ACCESS_TOKEN := 10

# EOSG reads named properties from RefCounted options, including nested structs.
class Options extends RefCounted:
	var fields: Dictionary
	func _init(values: Dictionary) -> void:
		fields = values
	func _get(property: StringName) -> Variant:
		return fields.get(property)

var _sdk: Variant
var _settings: Dictionary
var _initialized := false
var _platform := false
var _device_ready := false
var _refresh_login := false
var _user := ""
var _wanted := ""
var _lobby := ""
var _leaving := false
var _last_diagnostic := ""
var _bucket := ""
var _members: Dictionary = {}
var _mesh: WalkMesh
var _busy := false
var _status := ""
var _next_attempt := 0
var _next_solo_search := 0
var _next_roster := 0
var _retry_delay := 1000

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func is_configured() -> bool:
	if not Engine.has_singleton("IEOS") or not ClassDB.can_instantiate("EOSGMultiplayerPeer"):
		return false
	if _settings.is_empty():
		_settings = Config.load_settings()
	return not _settings.is_empty()

func start(match_key: String = "sandbox") -> void:
	if not is_configured():
		_set_status("offline")
		return
	var target := BUCKET_PREFIX + match_key
	if _wanted == target:
		return
	_wanted = target
	_close_mesh()
	_next_attempt = 0
	_retry_delay = 1000
	_set_status("connecting")

func stop() -> void:
	_wanted = ""
	_close_mesh()
	_next_attempt = 0
	_set_status("offline")

func send_pose(pose: Dictionary) -> void:
	if _mesh:
		_mesh.send_pose(pose)

func _process(_delta: float) -> void:
	if _platform:
		_sdk.tick()
	if _mesh:
		_mesh.poll()
	if _busy or (_wanted.is_empty() and _lobby.is_empty()):
		return
	if Time.get_ticks_msec() >= _next_attempt:
		_busy = true
		await _advance()
		_busy = false

# Serialize EOS operations. A late join/create still records its lobby so a new
# selection (or stop) can leave it before matching again.
func _advance() -> void:
	if not _lobby.is_empty() and (_wanted != _bucket):
		if not await _leave():
			_retry()
		return
	if _wanted.is_empty():
		return
	if not _platform and not _setup():
		_retry()
		return
	if _user.is_empty() or _refresh_login:
		_set_status("connecting")
		if not await _login():
			_retry()
		else:
			_show_connections()
		return
	if _lobby.is_empty():
		_set_status("searching")
		if not await _match(_wanted):
			_retry()
		return
	if not _mesh:
		_mesh = WalkMesh.new()
		if not _mesh.open(_lobby, _user):
			_mesh = null
			_retry()
			return
		_mesh.peer_left.connect(peer_left.emit)
		_mesh.pose_received.connect(pose_received.emit)
		_mesh.connections_changed.connect(_show_connections)
		_next_roster = 0
		_show_connections()
	var now := Time.get_ticks_msec()
	if now >= _next_roster:
		_refresh_members()
		if not _mesh:
			return
	if now >= _next_solo_search and _members.is_empty():
		# Simultaneous first launches can create separate lobbies before EOS
		# indexes either one. Merge into an occupied lobby, or the smaller
		# lobby ID when both are still singletons.
		_next_solo_search = now + randi_range(20000, 30000)
		await _match(_wanted)
		return
	_next_attempt = now + 500

func _setup() -> bool:
	if not _sdk:
		_sdk = Engine.get_singleton("IEOS")
		_sdk.connect_interface_auth_expiration.connect(_on_auth_expiration)
		_sdk.connect_interface_login_status_changed.connect(_on_login_status)
		_sdk.lobby_interface_lobby_member_status_received_callback.connect(_on_member_status)
	if not _initialized:
		var result: int = _sdk.platform_interface_initialize(Options.new({
			"product_name": "The Lower Vaults", "product_version": "1"
		}))
		if result not in [EOS_SUCCESS, EOS_ALREADY_CONFIGURED]:
			return _failed("Initialize", result)
		_initialized = true
	var values := _settings.duplicate()
	values.merge({
		"cache_directory": ProjectSettings.globalize_path("user://eos-cache"),
		"encryption_key": "", "override_country_code": "", "override_locale_code": "",
		"flags": 2, # EOS_PF_DISABLE_OVERLAY
		"is_server": false, "tick_budget_in_milliseconds": 2,
		"task_network_timeout_seconds": 15.0, "rtc_options": Options.new({})
	})
	_platform = _sdk.platform_interface_create(Options.new(values))
	if not _platform:
		return _failed("CreatePlatform (null handle)", -1)
	return true

func _login() -> bool:
	if not _device_ready:
		_sdk.connect_interface_create_device_id(Options.new({"device_model": OS.get_name()}))
		var device: Dictionary = await _sdk.connect_interface_create_device_id_callback
		if device.result_code not in [EOS_SUCCESS, EOS_DUPLICATE_NOT_ALLOWED]:
			return _failed("CreateDeviceId", device.result_code)
		_device_ready = true
	var options := Options.new({
		"credentials": Options.new({"type": EOS_DEVICE_ID_ACCESS_TOKEN, "token": ""}),
		"user_login_info": Options.new({"display_name": "Walker", "nsa_id_token": ""})
	})
	_sdk.connect_interface_login(options)
	var login: Dictionary = await _sdk.connect_interface_login_callback
	if login.result_code == EOS_INVALID_USER:
		_sdk.connect_interface_create_user(Options.new({"continuance_token": login.continuance_token}))
		var created: Dictionary = await _sdk.connect_interface_create_user_callback
		if created.result_code != EOS_SUCCESS:
			return _failed("CreateUser", created.result_code)
		# EOSG initializes the P2P mediator on a successful *login* callback.
		_sdk.connect_interface_login(options)
		login = await _sdk.connect_interface_login_callback
	if login.result_code != EOS_SUCCESS or str(login.local_user_id).is_empty():
		return _failed("ConnectLogin", login.result_code)
	_user = login.local_user_id
	_refresh_login = false
	return true

func _match(target: String) -> bool:
	var current := _lobby
	var created: Dictionary = _sdk.lobby_interface_create_lobby_search(Options.new({"max_results": 32}))
	if created.result_code != EOS_SUCCESS:
		return _failed("CreateLobbySearch", created.result_code)
	var search: Variant = created.lobby_search
	var filter_result: int = search.set_parameter("bucket", target, 0)
	if filter_result != EOS_SUCCESS:
		return _failed("SetLobbySearchParameter", filter_result)
	search.find(_user)
	var found: Dictionary = await _sdk.lobby_search_find_callback
	if _wanted != target or _lobby != current:
		return true
	if found.result_code not in [EOS_SUCCESS, EOS_NOT_FOUND]:
		return _failed("FindLobbies", found.result_code)
	var candidates := {}
	for index in search.get_search_result_count():
		var item: Dictionary = search.copy_search_result_by_index(index)
		if item.result_code != EOS_SUCCESS:
			continue
		var info: Dictionary = item.lobby_details.copy_info()
		if info.result_code != EOS_SUCCESS:
			continue
		var details: Dictionary = info.lobby_details
		if details.bucket_id == target and details.available_slots > 0:
			var occupied: bool = details.max_members - details.available_slots > 1
			if details.lobby_id != current and (current.is_empty() or occupied or details.lobby_id < current):
				candidates[details.lobby_id] = item.lobby_details
	if not current.is_empty():
		if candidates.is_empty() or not _members.is_empty():
			return true
		if not await _leave():
			return false
	var ids := candidates.keys()
	ids.sort()
	for id: String in ids:
		if _wanted != target:
			return true
		_sdk.lobby_interface_join_lobby(Options.new({
			"local_user_id": _user, "lobby_details": candidates[id],
			"presence_enabled": false, "rtc_room_join_action_type": 0
		}))
		var joined: Dictionary = await _sdk.lobby_interface_join_lobby_callback
		if joined.result_code == EOS_SUCCESS:
			_adopt_lobby(joined.lobby_id, target)
			return true
		if joined.result_code not in [EOS_NOT_FOUND, EOS_LOBBY_TOO_MANY_PLAYERS, EOS_LOBBY_INVALID_SESSION]:
			return _failed("JoinLobby", joined.result_code)
	if _wanted != target:
		return true
	_sdk.lobby_interface_create_lobby(Options.new({
		"local_user_id": _user, "bucket_id": target, "lobby_id": "",
		"max_lobby_members": MAX_PLAYERS, "permission_level": 0, # PublicAdvertised
		"disable_host_migration": false, "presence_enabled": false,
		"allowed_platform_ids": [], "rtc_room_join_action_type": 0
	}))
	var lobby: Dictionary = await _sdk.lobby_interface_create_lobby_callback
	if lobby.result_code != EOS_SUCCESS:
		return _failed("CreateLobby", lobby.result_code)
	_adopt_lobby(lobby.lobby_id, target)
	return true

func _adopt_lobby(id: String, target: String) -> void:
	_lobby = id
	_bucket = target
	_retry_delay = 1000
	_last_diagnostic = ""
	_next_solo_search = Time.get_ticks_msec() + randi_range(15000, 20000)

func _leave() -> bool:
	var leaving := _lobby
	_leaving = true
	_close_mesh()
	_sdk.lobby_interface_leave_lobby(Options.new({"local_user_id": _user, "lobby_id": leaving}))
	var result: Dictionary = await _sdk.lobby_interface_leave_lobby_callback
	_leaving = false
	if result.result_code not in [EOS_SUCCESS, EOS_NOT_FOUND, EOS_LOBBY_INVALID_SESSION] and _lobby == leaving:
		return _failed("LeaveLobby", result.result_code)
	if _lobby == leaving:
		_lobby = ""
		_bucket = ""
	return true

func _refresh_members() -> void:
	_next_roster = Time.get_ticks_msec() + 10000
	var copied: Dictionary = _sdk.lobby_interface_copy_lobby_details(Options.new({"local_user_id": _user, "lobby_id": _lobby}))
	if copied.result_code == EOS_NOT_FOUND:
		_lost_lobby()
		return
	if copied.result_code != EOS_SUCCESS:
		return
	var details: Variant = copied.lobby_details
	var members := {}
	for index in details.get_member_count():
		var id: String = details.get_member_by_index(index)
		if id != "" and id != _user:
			members[id] = true
	_members = members
	if _mesh:
		_mesh.set_members(_members)

func _on_member_status(data: Dictionary) -> void:
	if _leaving or _lobby.is_empty() or data.lobby_id != _lobby:
		return
	if data.target_user_id == _user and data.current_status in [1, 2, 3, 5]:
		_lost_lobby()
	else:
		_refresh_members()

func _on_auth_expiration(data: Dictionary) -> void:
	if data.local_user_id == _user:
		_refresh_login = true
		_next_attempt = 0

func _on_login_status(data: Dictionary) -> void:
	if data.local_user_id == _user and data.current_status == 0:
		_user = ""
		_lost_lobby()

func _lost_lobby() -> void:
	_lobby = ""
	_bucket = ""
	_close_mesh()
	_retry()

func _close_mesh() -> void:
	if _mesh:
		_mesh.connections_changed.disconnect(_show_connections)
		_mesh.close()
		_mesh = null
	_members.clear()

func _show_connections() -> void:
	if _mesh and _wanted == _bucket:
		_set_status("online" if _mesh.has_walkers() else "waiting")

func _failed(operation: String, code: int) -> bool:
	var diagnostic := "EOS %s returned %d" % [operation, code]
	if diagnostic != _last_diagnostic:
		push_warning(diagnostic)
		_last_diagnostic = diagnostic
	return false

func _retry() -> void:
	if not _wanted.is_empty():
		_set_status("retrying")
	_next_attempt = Time.get_ticks_msec() + _retry_delay + randi_range(0, 500)
	_retry_delay = mini(_retry_delay * 2, 30000)

func _set_status(value: String) -> void:
	if value != _status:
		_status = value
		status_changed.emit(value)

func _exit_tree() -> void:
	_wanted = ""
	_close_mesh()
	if _platform and not _leaving and not _lobby.is_empty():
		_sdk.lobby_interface_leave_lobby(Options.new({"local_user_id": _user, "lobby_id": _lobby}))
		_sdk.tick()
