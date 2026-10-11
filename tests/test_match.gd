extends SceneTree
func _initialize() -> void:
	var rules = load("res://scripts/game/round_manager.gd").new()
	rules.begin(2)
	assert(rules.resolve([0, 1]) == -2, "Living players means continue")
	assert(rules.resolve([]) == -1, "Simultaneous knockouts must draw")
	assert(rules.wins == [0, 0], "Draw cannot award wins")
	for i in range(3):
		assert(rules.resolve([1]) == 1)
	assert(rules.champion() == 1, "First to three wins match")
	print("PASS: continue, draw, round scores, match champion")
	quit()
