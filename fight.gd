extends VBoxContainer
@onready var player_hc = %HealthComponent
@onready var player_ac = %AttackComponent
@onready var enemy = $Node2D
var player_sc

func _ready() -> void:
	enemy.ac.on_attack.connect(player_hc.take_damage)
	player_ac.on_attack.connect(enemy.hc.take_damage)
	
func _process(delta: float) -> void:
	player_ac.set_value(player_ac.value - player_sc.speed * delta)
	if player_ac.value == player_ac.min_value:
		player_ac.new_attack(player_sc.attack)
		player_ac.set_value(player_ac.max_value)
