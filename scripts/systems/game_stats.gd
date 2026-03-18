extends Node

signal stats_changed(stats: Dictionary)

var _stats: Dictionary = {}


func update_stats(next_stats: Dictionary) -> void:
	_stats = next_stats.duplicate(true)
	emit_signal("stats_changed", _stats)


func get_stat(key: String, default_value: Variant = null) -> Variant:
	return _stats.get(key, default_value)

