extends RefCounted

class_name RecordsService

const _RECORDS_FILE_PATH: String = "user://records.cfg"


static func load_best_records() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(_RECORDS_FILE_PATH)
	if err != OK:
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
	cfg.save(_RECORDS_FILE_PATH)
