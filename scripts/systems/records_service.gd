extends RefCounted

class_name RecordsService
const _LogBridgeRef = preload("res://scripts/systems/log_bridge.gd")

const _RECORDS_FILE_PATH: String = "user://records.cfg"


static func load_best_records() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(_RECORDS_FILE_PATH)
	if err != OK:
		_LogBridgeRef.warn("RecordsService load failed (%d), fallback defaults." % err)
		return {
			"best_score": 0,
			"best_dps": 0.0,
			"best_combo": 0,
		}
	return {
		"best_score": int(cfg.get_value("records", "best_score", 0)),
		"best_dps": float(cfg.get_value("records", "best_dps", 0.0)),
		"best_combo": int(cfg.get_value("records", "best_combo", 0)),
	}


static func save_best_records(best_score: int, best_dps: float, best_combo: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_score", best_score)
	cfg.set_value("records", "best_dps", best_dps)
	cfg.set_value("records", "best_combo", best_combo)
	var err := cfg.save(_RECORDS_FILE_PATH)
	if err != OK:
		_LogBridgeRef.error("RecordsService save failed (%d)." % err)


static func finalize_best_records(best_records: Dictionary, run_stats: Dictionary) -> Dictionary:
	var old_best_score := int(best_records.get("best_score", 0))
	var old_best_dps := float(best_records.get("best_dps", 0.0))
	var old_best_combo := int(best_records.get("best_combo", 0))
	var run_score := int(run_stats.get("score", 0))
	var run_dps := float(run_stats.get("dps", 0.0))
	var run_combo := int(run_stats.get("combo", 0))

	var diff := {
		"score": {"old": old_best_score, "new": run_score, "is_new": false},
		"dps": {"old": old_best_dps, "new": run_dps, "is_new": false},
		"combo": {"old": old_best_combo, "new": run_combo, "is_new": false},
	}

	var new_best_score := old_best_score
	var new_best_dps := old_best_dps
	var new_best_combo := old_best_combo
	var changed := false
	if run_score > old_best_score:
		new_best_score = run_score
		changed = true
		diff["score"]["is_new"] = true
	if run_dps > old_best_dps:
		new_best_dps = run_dps
		changed = true
		diff["dps"]["is_new"] = true
	if run_combo > old_best_combo:
		new_best_combo = run_combo
		changed = true
		diff["combo"]["is_new"] = true
	diff["any_new"] = changed

	return {
		"best_score": new_best_score,
		"best_dps": new_best_dps,
		"best_combo": new_best_combo,
		"changed": changed,
		"diff": diff,
	}
