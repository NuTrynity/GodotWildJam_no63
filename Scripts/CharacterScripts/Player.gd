extends CharacterBody2D

@export var player_stats : PlayerResource
@export var move_speed : float = 500.0

@onready var pivot : Node2D = $PlayerSkin
@onready var start_scale : Vector2 = pivot.scale
@onready var animations = $PlayerSkin/PlayerAnimations

var input = Vector2.ZERO
var joystick_input = Vector2(0, 0)

func _physics_process(_delta):
	input = get_input()
	
	velocity = input * move_speed
	move_and_slide()

func _process(_delta):
	var is_idle = is_zero_approx(velocity.x) and is_zero_approx(velocity.y)
	var is_walking = not Vector2.ZERO
	
	if is_idle:
		animations.play("idle")
	elif is_walking:
		animations.play("walking")
	
	flip_pivot()
	
func flip_pivot():
	if not is_zero_approx(velocity.x):
		pivot.scale.x = sign(velocity.x) * start_scale.x

func get_input():
	input.x = int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left"))
	input.y = int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	
	return input.normalized()

func _on_joy_stick_use_move_vector(move_vector):
	velocity = move_vector * move_speed
	move_and_slide()
	flip_pivot()
