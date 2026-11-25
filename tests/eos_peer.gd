extends SceneTree

# Run on two devices with the same test name and different sides (A and B).
const EosSession := preload("res://network/eos_session.gd")
const TIMEOUT_MS := 120000

var session := EosSession.new()
var side: int
var received := false
var acknowledged := false
var sequence := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	root.add_child(session)
	if args.size() != 2 or args[0].is_empty() or args[1] not in ["A", "B"]:
		printerr("Usage: godot --headless --script tests/eos_peer.gd -- TEST_NAME A|B")
		quit(2)
		return
	if not session.is_configured():
		printerr("Install EOSG and configure network/eos.cfg before running the live test.")
		quit(2)
		return
	side = 1 if args[1] == "A" else 2
	session.status_changed.connect(func(state: String): print("EOS: ", state))
	session.pose_received.connect(_on_pose)
	session.start("probe-" + args[0].sha256_text().left(16))
	var deadline := Time.get_ticks_msec() + TIMEOUT_MS
	var finish_at := 0
	while Time.get_ticks_msec() < deadline:
		sequence += 1
		session.send_pose({
			"sequence": sequence, "cell_x": side, "cell_y": int(received),
			"px": float(side), "py": 0.0, "pz": 0.0,
			"qx": 0.0, "qy": 0.0, "qz": 0.0, "qw": 1.0
		})
		if acknowledged:
			if finish_at == 0:
				# Keep acknowledging packets so the second process can also finish.
				finish_at = Time.get_ticks_msec() + 3000
			elif Time.get_ticks_msec() >= finish_at:
				break
		await create_timer(0.1).timeout
	session.stop()
	await create_timer(1.0).timeout
	if acknowledged:
		print("PASS: both devices exchanged poses through EOS.")
	else:
		printerr("Timed out before the other device acknowledged a pose.")
	quit(0 if acknowledged else 1)


func _on_pose(_peer: String, pose: Dictionary) -> void:
	var other_side := 3 - side
	if pose.cell_x == other_side and pose.px == float(other_side) and pose.sequence > 0:
		received = true
		acknowledged = acknowledged or pose.cell_y == 1
