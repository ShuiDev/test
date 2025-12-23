extends TextureRect

@onready var hc = $HealthComponent
@onready var sc = $StatsComponent
@onready var ac = $AttackComponent

func _process(delta: float) -> void:
	ac.set_value(ac.value - sc.speed * delta)
	if ac.value == ac.min_value:
		ac.new_attack(sc.attack)
		ac.set_value(ac.max_value)
