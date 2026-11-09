extends RefCounted

const MAX_HEALTH := 100
const RENOVATION_PRICE := 100
const POTION_PRICE := 20
const POTION_HEAL := 30

var coins := 150
var health := 60
var potions := 0
var shops: Array[String] = []
var save_path: String
var load_error := false

func _init(path: String) -> void:
	save_path = path
	if not FileAccess.file_exists(save_path):
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		load_error = true
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary or data.get("version") != 1:
		load_error = true
		return
	for key in ["coins", "health", "potions"]:
		var value: Variant = data.get(key)
		if not (value is int or value is float) or value < 0 or value > 2147483647 or value != floor(value):
			load_error = true
			return
	if data.health > MAX_HEALTH or not data.get("shops") is Array:
		load_error = true
		return
	for id in data.shops:
		if not id is String or id.is_empty():
			load_error = true
			return
	coins = int(data.coins)
	health = int(data.health)
	potions = int(data.potions)
	shops.assign(data.shops)

func renovate(id: String) -> bool:
	if shops.has(id) or coins < RENOVATION_PRICE:
		return false
	var upgraded := shops.duplicate()
	upgraded.append(id)
	return commit(coins - RENOVATION_PRICE, health, potions, upgraded)

func buy_potion() -> bool:
	return coins >= POTION_PRICE and commit(coins - POTION_PRICE, health, potions + 1, shops)

func use_potion() -> bool:
	if potions == 0 or health >= MAX_HEALTH:
		return false
	return commit(coins, mini(MAX_HEALTH, health + POTION_HEAL), potions - 1, shops)

func commit(next_coins: int, next_health: int, next_potions: int, next_shops: Array[String]) -> bool:
	if load_error:
		return false
	var pending := save_path + ".tmp"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return false
	var written := file.store_string(JSON.stringify({
		"version": 1, "coins": next_coins, "health": next_health,
		"potions": next_potions, "shops": next_shops,
	}))
	file.close()
	if not written or DirAccess.rename_absolute(pending, save_path) != OK:
		DirAccess.remove_absolute(pending)
		return false
	coins = next_coins
	health = next_health
	potions = next_potions
	shops = next_shops
	return true
