extends Node

var last_run := {
	"level": 1,
	"exp": 0,
	"max_hp": 100,
	"wins": 0,
	"wave": 0,
	"kills": 0,
	"highest_wave": 0,
	"total_kills": 0,
}

func update(level: int, exp: int, max_hp: int, wins: int, wave: int, kills: int):
	last_run["level"] = level
	last_run["exp"] = exp
	last_run["max_hp"] = max_hp
	last_run["wins"] = wins
	last_run["wave"] = wave
	last_run["kills"] = kills

	Account.update_record(wave, kills)

	var data = Account.get_player_data()
	last_run["highest_wave"] = data.get("highest_wave", 0)
	last_run["total_kills"] = data.get("total_kills", 0)
