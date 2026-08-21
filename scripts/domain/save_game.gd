class_name SaveGame
extends RefCounted


static func load_or_create(path: String) -> Dictionary:
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary and _is_valid_account(parsed):
				return parsed
	var data := _default_account()
	write(path, data)
	return data


static func write(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveGame.write failed: %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))


static func _default_account() -> Dictionary:
	return {
		"version": 1,
		"heroes": [
			Hero.new(ClassId.Value.SWORDMAN).to_dict(),
			Hero.new(ClassId.Value.MAGE).to_dict(),
			Hero.new(ClassId.Value.ARCHER).to_dict()
		]
	}


static func _is_valid_account(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != 1:
		return false
	var heroes = data.get("heroes", null)
	return heroes is Array and heroes.size() == 3
