extends CharacterBody2D

const SPEED = 250 # Hero movement speed.
var type:String = "" # Hero type to match.

# Loads global variables.
@onready var Globals = get_node("/root/Global")


##
# Sets the hero initial velocity.
##
func _ready():
	velocity = Vector2(SPEED, SPEED)


##
# Detects collisions and adjusts the hero velocity and rotation accordingly.
##
func _physics_process(delta):
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
	else:
		rotation = velocity.angle()


##
# Detects mouse click on a hero.
##
func _on_input_event(_viewport, event, _shape_idx):
	if (event.is_pressed()):
		
		# Creates tween and animates the scale and modulate.
		var tween :=  create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(self, "modulate", Color(1.5,1.5,1.5,1), 0.3)
		tween.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 0.3)
		tween.tween_property(self, "scale", Vector2(1, 1), 0.3)
		
		# Checks if current hero clicked is the same type than previous hero clicked.
		# In this case, both heroes are removed from the game and hero count gets updated.
		if Globals.clicked_hero != null and Globals.clicked_hero != self and Globals.clicked_hero.type == type:
			_destroy(Globals.clicked_hero)
			_destroy(self)
			Global.heroes_count -= 2
		# If hero clicked is not the same than previous hero clicked then it gets highlighted.
		elif Globals.clicked_hero != null and Globals.clicked_hero != self:
			Globals.clicked_hero.modulate = Color(1, 1, 1, 1)
		
		# Updates the hero clicked variable.
		Globals.clicked_hero = self


##
# Removes hero from the game animating its scale and modulate.
##
func _destroy(hero: CharacterBody2D):
	var tween :=  create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(hero, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(hero, "modulate", Color(1,1,1,0), 0.3)
	tween.tween_callback(hero.queue_free)
