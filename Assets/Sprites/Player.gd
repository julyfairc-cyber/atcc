extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 220.0
const JUMP_VELOCITY = -400.0


func _physics_process(_delta: float) -> void:
	#Add animation
	if velocity.x > 1 or velocity.x <-1:
		animated_sprite_2d.animation = "walk"
	else :
		animated_sprite_2d.animation= "idle"
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	if direction == 1.0 :
		animated_sprite_2d.flip_h = false
	elif direction == -1.0 :
		animated_sprite_2d.flip_h = true
