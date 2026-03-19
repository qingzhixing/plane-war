extends RefCounted

class_name UpgradePickService

var _upgrade_service: UpgradeService


func _init(upgrade_service: UpgradeService) -> void:
	_upgrade_service = upgrade_service


func build_pick_candidates(main: Node, player: Node) -> Array[Dictionary]:
	var all_upgrades := _upgrade_service.get_all_upgrades()
	var pool: Array[Dictionary] = []
	var at_max_bullets := false
	var bullet_count := 1
	var arrow_unlocked := false
	var bomb_unlocked := false
	if player != null and player.has_method("get_bullet_count") and player.has_method("get_max_bullet_count"):
		bullet_count = int(player.get_bullet_count())
		at_max_bullets = bullet_count >= int(player.get_max_bullet_count())
	if player != null and player.has_method("has_weapon_unlocked"):
		arrow_unlocked = bool(player.has_weapon_unlocked("arrow"))
	if player != null and player.has_method("has_weapon_unlocked"):
		bomb_unlocked = bool(player.has_weapon_unlocked("bomb"))
	for u in all_upgrades:
		if u["id"] == "spell_auto" and main.has_method("has_spell_auto") and main.has_spell_auto():
			continue
		if u["id"] == "multi_shot" and at_max_bullets:
			continue
		if u["id"] == "spread_focus" and bullet_count <= 1:
			continue
		if u["id"] == "arrow_cooldown" and not arrow_unlocked:
			continue
		if u["id"] == "bomb_side_cooldown" and not bomb_unlocked:
			continue
		pool.append(u)
	return pool


func choose_upgrades(pool: Array[Dictionary], pick_count: int = 3) -> Array[Dictionary]:
	var mutable_pool := pool.duplicate(true)
	mutable_pool.shuffle()
	var count: int = mini(pick_count, mutable_pool.size())
	var chosen: Array[Dictionary] = []
	for i in count:
		chosen.append(mutable_pool[i])
	# 保证至少出现 1 张直接战斗收益词条，避免鸡肋三选
	var has_combat_card := false
	for c in chosen:
		if _upgrade_service.is_direct_combat_upgrade(c["id"]):
			has_combat_card = true
			break
	if not has_combat_card:
		for c in mutable_pool:
			if _upgrade_service.is_direct_combat_upgrade(c["id"]):
				if chosen.is_empty():
					chosen.append(c)
				else:
					chosen[0] = c
				break
	return chosen
