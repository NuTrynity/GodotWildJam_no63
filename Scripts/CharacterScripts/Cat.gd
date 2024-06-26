extends CharacterBody2D
class_name Cat

enum State {IDLE, APPROACH, ACT, HUNGRY, REST }
var state = State.IDLE as State

enum IdleState {STAND, WALK, SLEEP}
var idleState = IdleState.STAND as State

@export var player_resources : PlayerResource
@export var idle_speed : int = 70

@export var rating_value : int = 10
@export var approach_speed : int = 110
@export var pause_duration : float = 4.0
@export var cd_duration : float = 4.0
@export var min_stand_time : float = 3.0
@export var max_stand_time : float = 10.0
@export var sleep_time : float = 20.0

@onready var animations = $CatSkin as CatAnimation
@onready var cat_sprite = $CatSkin/CatSprite

@onready var standing_timer := Timer.new() as Timer
@onready var pause_timer := Timer.new() as Timer
@onready var cd_timer := Timer.new() as Timer
@onready var sleep_timer := Timer.new() as Timer

@onready var aiMvt := $AiMovement as CatAiMovement

var rng := RandomNumberGenerator.new() as RandomNumberGenerator

var patience_timer : Timer = null
var on_cd : bool = false

func _ready():
	setup_cat()
	check_for_customers()
	
func setup_cat():
	add_child(standing_timer)
	standing_timer.one_shot = true
	standing_timer.connect("timeout", _on_standing_end)
	
	add_child(sleep_timer)
	sleep_timer.one_shot = true
	sleep_timer.connect("timeout", _on_sleep_start)
	
	add_child(pause_timer)
	pause_timer.one_shot = true
	pause_timer.connect("timeout", _on_pause_end)
	
	add_child(cd_timer)
	cd_timer.one_shot = true
	cd_timer.connect("timeout", _on_cd_end)
	
	to_idle_stand()
	start_sleep_timer()
	animations.idle()
	
func _physics_process(_delta : float) -> void:
	match state:
		State.IDLE:
			idle()
			
		State.APPROACH:
			if !aiMvt.can_target_customer():
				aiMvt.untarget_customer()
				to_idle_stand()
				start_sleep_timer()
			elif aiMvt.reached_target():
				to_act()
			else:
				walking()
			
		State.ACT:
			if !aiMvt.can_target_customer():
				stop_act()
			
		State.HUNGRY:
			pass
		State.REST:
			pass

# called in process
func idle():
	# timer of random length for how long to idle
	if (idleState == IdleState.STAND):
		return
	# set a random target and walk towards it
	if (idleState == IdleState.WALK):
		walking()
		if (aiMvt.reached_target()):
			to_idle_stand()
	
func to_idle_stand():
	aiMvt.speed = idle_speed
	state = State.IDLE
	idleState = IdleState.STAND
	start_standing_timer()
	
	animations.idle()
	
func to_idle_walk():
	aiMvt.speed = idle_speed
	state = State.IDLE
	idleState = IdleState.WALK
	aiMvt.target_random_point()
	
	animations.walk()
	
func to_idle_sleep():
	state = State.IDLE
	idleState = IdleState.SLEEP
	standing_timer.stop()
	
	animations.sleep()

func to_approach():
	standing_timer.stop()
	sleep_timer.stop()
	state = State.APPROACH
	aiMvt.speed = approach_speed
	
	animations.walk()

func to_act():
	state = State.ACT
	var npc = aiMvt.target_npc
	npc.interacting_with_cat_func()
	# pause timer
	start_pause_timer()
	npc.patience_timer.set_paused(true)
	face_table()
	
	animations.interact()
	
	GlobalScript.adjust_ratings(rating_value)
	
func face_table():
	var sit_area = aiMvt.target.get_parent()
	cat_sprite.flip_h = sit_area.facing_left
		
func start_standing_timer():
	standing_timer.wait_time = rng.randf_range(min_stand_time, max_stand_time)
	standing_timer.start()
	
func start_pause_timer():
	pause_timer.wait_time = pause_duration
	pause_timer.start()
	
func start_cd_timer():
	on_cd = true
	cd_timer.wait_time = cd_duration
	cd_timer.start()
	
func start_sleep_timer():
	sleep_timer.wait_time = rng.randf_range(sleep_time - 4, sleep_time + 4)
	sleep_timer.start()

func _on_standing_end():
	to_idle_walk()
	
func _on_sleep_start():
	to_idle_sleep()
	
func _on_pause_end():
	# finishes pausing, opens npc up for another cat
	var save_npc = aiMvt.target_npc
	stop_act()
	save_npc.ready_for_cat_func()

func stop_act():
	aiMvt.target_npc.patience_timer.set_paused(false)
	pause_timer.stop()
	aiMvt.untarget_customer()
	
	to_idle_walk()
	start_cd_timer()
	start_sleep_timer()
	
func _on_cd_end():
	on_cd = false
	check_for_customers()
	
func walking():
	aiMvt.approach_target()
	if velocity.x > 0:
		cat_sprite.flip_h = false
	else:
		cat_sprite.flip_h = true

func is_idle() -> bool:
	return state == State.IDLE && !on_cd
	
func approach_customer(npc:Npc):
	aiMvt.target_customer(npc)
	to_approach()
	
func check_for_customers():
	if (aiMvt.try_target_customer()):
		to_approach()
	
