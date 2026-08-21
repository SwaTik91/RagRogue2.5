extends Control

signal upgrade_chosen(upgrade_id: String)

var choices: Array = []
var catalog: Array = []


func _init() -> void:
	catalog = _read_catalog()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for i in 3:
		var button := _choice_button(i)
		if button == null:
			continue
		var idx := i
		button.pressed.connect(func() -> void: choose(idx))


func pick_three(rng: RandomNumberGenerator) -> Array:
	if catalog.is_empty():
		catalog = _read_catalog()
	var pool: Array = catalog.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var n := mini(3, pool.size())
	return pool.slice(0, n)


func present(offered: Array) -> void:
	choices = offered.duplicate()
	for i in 3:
		var button := _choice_button(i)
		if button == null:
			continue
		if i < choices.size():
			button.visible = true
			button.disabled = false
			button.text = _label_for(choices[i])
		else:
			button.visible = false
			button.disabled = true
			button.text = ""


func choose(index: int) -> void:
	if index < 0 or index >= choices.size():
		return
	var upgrade_id := str(choices[index].get("id", ""))
	if upgrade_id == "":
		return
	upgrade_chosen.emit(upgrade_id)


func _choice_button(index: int) -> Button:
	var button_name := "Choice%d" % index
	var named := get_node_or_null("%" + button_name) as Button
	if named != null:
		return named
	return get_node_or_null("Panel/Choices/" + button_name) as Button


func _label_for(item: Dictionary) -> String:
	var title := str(item.get("name", item.get("id", "Upgrade")))
	var bits: Array[String] = []
	if int(item.get("atk_bonus", 0)) != 0:
		bits.append("+%d ATK" % int(item["atk_bonus"]))
	if int(item.get("hp_bonus", 0)) != 0:
		bits.append("+%d HP" % int(item["hp_bonus"]))
	if float(item.get("cdr_bonus", 0.0)) != 0.0:
		bits.append("-%d%% CD" % int(round(float(item["cdr_bonus"]) * 100.0)))
	if bits.is_empty():
		return title
	return "%s\n%s" % [title, "  ".join(bits)]


func _read_catalog() -> Array:
	var out: Array = []
	var file := FileAccess.open("res://data/run_upgrades.json", FileAccess.READ)
	if file == null:
		return out
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Array):
		return out
	for item in parsed:
		if item is Dictionary and item.has("id"):
			out.append(item)
	return out
