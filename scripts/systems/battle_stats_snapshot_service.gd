extends RefCounted

class_name BattleStatsSnapshotService


func build_snapshot(main: Node) -> Dictionary:
	if main == null:
		return {}
	return {
		"score": int(main.score),
		"combo": int(main.combo),
		"current_dps": float(main.current_dps),
		"max_dps": float(main.max_dps),
		"wave": int(main._wave),
		"extension_wave": int(main._extension_wave),
		"threat_tier": int(main.threat_tier),
		"is_boss_spawned": bool(main._boss_spawned),
		"lives_remaining": int(main._lives_remaining),
		"combo_guard_charges": int(main._combo_guard_charges),
		"spell_cooldown_remaining": float(main._spell_cooldown_remaining),
		"spell_cooldown_total": float(main.get_spell_cooldown_total()),
		"has_spell_auto": bool(main._spell_auto),
	}
