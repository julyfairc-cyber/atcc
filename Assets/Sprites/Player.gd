extends CharacterBody2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


const SPEED = 220.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 9.8

func _ready() -> void:
	if GameState.last_player_position != Vector2.ZERO:
		global_position = GameState.last_player_position
		
func _physics_process(_delta: float) -> void:
	#Add animation
	if velocity.x > 1 or velocity.x <-1:
		animated_sprite_2d.animation = "walk"
	else :
		animated_sprite_2d.animation= "idle"
		
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
