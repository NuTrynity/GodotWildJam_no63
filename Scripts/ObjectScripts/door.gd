extends Node2D
class_name Door

signal npc_spawned

@export var table_manager : TableManager
@export var game_manager : GameManager

@export var min_time : float
@export var max_time : float

@onready var npc_spawn_timer = Timer.new()
@onready var difficulty_timer = Timer.new()
@onready var randomizer = RandomNumberGenerator.new()

var npc = preload("res://Nodes/CharacterNodes/npc.tscn")
var npc_spawn_time : float
var customer_amt : int

func _ready():
	setup_timer()
	npc_spawn_timer.start()
	
	customer_amt = randi() % 20 + 1

func stop_spawning():
	var bell_sfx = load("res://Assets/SFX/shop_doorbell.mp3")
	npc_spawn_timer.stop()
	AudioManager.play_sound(bell_sfx)

func randomize_spawn():
	npc_spawn_time = randomizer.randf_range(min_time, max_time)
	npc_spawn_timer.wait_time = npc_spawn_time

func reduce_cooldown():
	if min_time >= 1:
		min_time -= 0.1
		max_time -= 0.1
	else:
		difficulty_timer.stop()

func setup_timer():
	add_child(npc_spawn_timer)
	npc_spawn_timer.one_shot = false
	randomize_spawn()
	npc_spawn_timer.connect("timeout", _on_timer_end)
	
	add_child(difficulty_timer)
	difficulty_timer.one_shot = false
	difficulty_timer.wait_time = 2.5
	difficulty_timer.connect("timeout", reduce_cooldown)
	difficulty_timer.start()

func _on_timer_end():
	spawn_customer()
	randomize_spawn()
	
	table_manager.chair_num += 1
	
	if table_manager.chair_num > 2:
		table_manager.chair_num = 1
		table_manager.table_num += 1
		if table_manager.table_num > 4:
			table_manager.table_num = 1

func spawn_customer():
	if customer_amt <= 0:
		stop_spawning()
		return
	
	var bell_sfx = load("res://Assets/SFX/shop_doorbell.mp3")
	var customer = npc.instantiate()
	customer.position = global_position
	customer.position.y += 100
	game_manager.customers += 1
	customer_amt -= 1
	get_parent().add_child(customer)
	
	emit_signal("npc_spawned", customer)
	AudioManager.play_sound(bell_sfx)
