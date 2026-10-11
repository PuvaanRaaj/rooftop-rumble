class_name RumbleRounds
extends RefCounted
var wins: Array = []
var round_number := 0
func begin(count: int) -> void:
	wins.clear()
	for i in range(count): wins.append(0)
	round_number = 0
func resolve(survivors: Array) -> int:
	if survivors.size() > 1: return -2
	if survivors.is_empty(): return -1
	var winner: int = survivors[0]
	wins[winner] += 1
	return winner
func champion() -> int:
	for i in range(wins.size()):
		if wins[i] >= 3: return i
	return -1
