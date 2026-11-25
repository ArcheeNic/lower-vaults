extends SceneTree

const RoomCode := preload("res://network/room_code.gd")
const Expedition := preload("res://world/expedition.gd")


func _initialize() -> void:
	var failures := 0
	for mode: Array in RoomCode.MODES:
		for _i in 200:
			var code := RoomCode.generate(mode[0], mode[1])
			var parsed := RoomCode.parse(RoomCode.display(code).to_lower())
			if parsed.get("code") != code or parsed.rules != mode[0] or parsed.map_size != mode[1]:
				printerr("Round trip failed for ", code, " ", mode)
				failures += 1
	var sandbox := RoomCode.parse(RoomCode.generate(Expedition.Rules.SANDBOX, Expedition.MapSize.SMALL))
	if sandbox.rules != Expedition.Rules.SANDBOX:
		printerr("Sandbox code lost its mode")
		failures += 1
	for bad: String in ["", "K7Q2M", "K7Q2MXX", "K7Q-2M0", "O7Q2MX", "97Q2MX", "K7Q2M!"]:
		if not RoomCode.parse(bad).is_empty():
			printerr("Accepted invalid code ", bad)
			failures += 1
	if RoomCode.map_seed("K7Q2MX") != RoomCode.map_seed(RoomCode.parse("k7q-2mx").code):
		printerr("Seed depends on formatting")
		failures += 1
	print("PASS" if failures == 0 else "FAIL: %d" % failures)
	quit(1 if failures else 0)
