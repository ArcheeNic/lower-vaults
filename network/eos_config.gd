extends RefCounted

const PROJECT_CONFIG := "res://network/eos.cfg"
const FIELDS := ["product_id", "sandbox_id", "deployment_id", "client_id", "client_secret"]


static func load_settings() -> Dictionary:
	var path := PROJECT_CONFIG
	if not OS.has_feature("editor"):
		var external := OS.get_executable_path().get_base_dir().path_join("eos.cfg")
		if FileAccess.file_exists(external):
			path = external
	if not FileAccess.file_exists(path):
		return {}
	var config := ConfigFile.new()
	if config.load(path) != OK:
		push_warning("Could not read EOS client configuration.")
		return {}
	var settings := {}
	for field: String in FIELDS:
		var value: Variant = config.get_value("eos", field, "")
		if typeof(value) != TYPE_STRING or value.strip_edges().is_empty():
			push_warning("Missing EOS client setting: %s" % field)
			return {}
		settings[field] = value.strip_edges()
	return settings
