class_name BattleStats
extends RefCounted

## 战斗统计：得分、连击、DPS 窗口、本局最优与历史记录持久化。
## 从 GameMain 中拆出，职责单一，不依赖场景树。

const GRAZE_SCORE: int = 9
const _DPS_WINDOW_SECONDS: float = 5.0
const _RECORDS_FILE_PATH: String = "user://records.cfg"

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var current_dps: float = 0.0
var max_dps: float = 0.0
var best_score: int = 0
var best_dps: float = 0.0
var best_combo: int = 0

var _damage_events: Array = []


func on_successful_hit(combo_gain: int) -> void:
	if combo <= 0:
		combo = combo_gain
	else:
		combo += combo_gain
	if combo > max_combo:
		max_combo = combo


func apply_hit_penalty() -> void:
	if combo > 0:
		combo = maxi(0, int(floor(float(combo) * 0.7)))


func record_damage(amount: float) -> void:
	if amount <= 0:
		return
	var now := float(Time.get_ticks_msec()) / 1000.0
	_damage_events.append({"time": now, "amount": amount})


func record_kill(base_score: int, score_mult: float) -> void:
	if base_score <= 0:
		return
	var gained := int(round(float(base_score) * get_combo_multiplier() * score_mult))
	score += maxi(0, gained)


func record_graze(score_mult: float, combo_gain: int) -> void:
	var gained := maxi(1, int(round(float(GRAZE_SCORE) * score_mult)))
	score += gained
	on_successful_hit(combo_gain)


func update_dps() -> void:
	var now := float(Time.get_ticks_msec()) / 1000.0
	var cutoff := now - _DPS_WINDOW_SECONDS
	var i := 0
	while i < _damage_events.size():
		if _damage_events[i].get("time", 0.0) < cutoff:
			_damage_events.remove_at(i)
		else:
			i += 1
	var total := 0.0
	for e in _damage_events:
		total += float(e.get("amount", 0.0))
	current_dps = total / _DPS_WINDOW_SECONDS
	if current_dps > max_dps:
		max_dps = current_dps


func get_combo_multiplier() -> float:
	if combo < 10:
		return 1.0
	elif combo < 25:
		return 1.2
	elif combo < 50:
		return 1.5
	elif combo < 100:
		return 2.0
	else:
		return 3.0


func get_combo_buff_tier() -> int:
	if combo < 10:
		return 0
	if combo < 25:
		return 1
	if combo < 50:
		return 2
	if combo < 100:
		return 3
	return 4 + int(floor((combo - 100) / 100.0))


func finalize_records() -> Dictionary:
	var diff := {
		"score": {"old": best_score, "new": score, "is_new": false},
		"dps": {"old": best_dps, "new": max_dps, "is_new": false},
		"combo": {"old": best_combo, "new": max_combo, "is_new": false},
	}
	var changed := false
	if score > best_score:
		best_score = score
		changed = true
		diff["score"]["is_new"] = true
	if max_dps > best_dps:
		best_dps = max_dps
		changed = true
		diff["dps"]["is_new"] = true
	if max_combo > best_combo:
		best_combo = max_combo
		changed = true
		diff["combo"]["is_new"] = true
	if changed:
		save_records()
	diff["any_new"] = changed
	return diff


func load_records() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_RECORDS_FILE_PATH) != OK:
		return
	best_score = int(cfg.get_value("records", "best_score", 0))
	best_dps = float(cfg.get_value("records", "best_dps", 0.0))
	best_combo = int(cfg.get_value("records", "best_combo", 0))


func save_records() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_score", best_score)
	cfg.set_value("records", "best_dps", best_dps)
	cfg.set_value("records", "best_combo", best_combo)
	cfg.save(_RECORDS_FILE_PATH)


func debug_add_combo(amount: int) -> void:
	if amount == 0:
		return
	combo = maxi(0, combo + amount)
	if combo > max_combo:
		max_combo = combo


func debug_set_combo(value: int) -> void:
	combo = maxi(0, value)
	if combo > max_combo:
		max_combo = combo
