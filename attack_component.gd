extends Attack

signal on_attack(a)

func new_attack(a):
	damage = a * randf_range(.8,1.1)
	on_attack.emit(a)
