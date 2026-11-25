extends RefCounted

const Expedition := preload("res://world/expedition.gd")
const ALPHABET := "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
const LENGTH := 6
const MODES := [
	[Expedition.Rules.SANDBOX, Expedition.MapSize.LARGE],
	[Expedition.Rules.NORMAL, Expedition.MapSize.SMALL],
	[Expedition.Rules.NORMAL, Expedition.MapSize.MEDIUM],
	[Expedition.Rules.NORMAL, Expedition.MapSize.LARGE],
	[Expedition.Rules.HARD, Expedition.MapSize.SMALL],
	[Expedition.Rules.HARD, Expedition.MapSize.MEDIUM],
	[Expedition.Rules.HARD, Expedition.MapSize.LARGE],
]


# The first symbol carries the mode and map size, the rest is random. A code
# therefore rebuilds the same expedition for everyone who enters it.
static func generate(rules: Expedition.Rules, map_size: Expedition.MapSize) -> String:
	var mode := _mode_index(rules, map_size)
	var bytes := Crypto.new().generate_random_bytes(LENGTH)
	@warning_ignore("integer_division")
	var variants := ALPHABET.length() / MODES.size()
	var code := ALPHABET[mode + MODES.size() * (bytes[0] % variants)]
	for i in range(1, LENGTH):
		code += ALPHABET[bytes[i] % ALPHABET.length()]
	return code


static func parse(text: String) -> Dictionary:
	var code := ""
	for character in text.to_upper():
		if character not in " -":
			code += character
	if code.length() != LENGTH:
		return {}
	for character in code:
		if not ALPHABET.contains(character):
			return {}
	var mode := ALPHABET.find(code[0]) % MODES.size()
	@warning_ignore("integer_division")
	if ALPHABET.find(code[0]) >= MODES.size() * (ALPHABET.length() / MODES.size()):
		return {}
	return {"code": code, "rules": MODES[mode][0], "map_size": MODES[mode][1]}


static func display(code: String) -> String:
	@warning_ignore("integer_division")
	return code.left(LENGTH / 2) + "-" + code.substr(LENGTH / 2)


static func map_seed(code: String) -> int:
	return code.hash()


static func _mode_index(rules: Expedition.Rules, map_size: Expedition.MapSize) -> int:
	if rules == Expedition.Rules.SANDBOX:
		return 0
	for index in MODES.size():
		if MODES[index][0] == rules and MODES[index][1] == map_size:
			return index
	return 3
