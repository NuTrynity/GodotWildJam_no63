extends Control

@export var resources : PlayerMealCarry
@export var game_manager : GameManager

@onready var animation = $AnimationPlayer
@onready var timer = Timer.new()
@onready var to_cash_timer = Timer.new()
@onready var cash_label = $Results/Cash/Amt/Result
@onready var day_label = $DayLabel

var click = load("res://Assets/SFX/click_sfx.ogg")
var victory_sfx = load("res://Assets/Music/Good Job!.wav")

func _ready():
	game_manager.game_end.connect(_end_day)
	setup_timer()
	next_day()

func _process(_delta):
	cash_label.text = str(GlobalScript.cash_on_hand)
	day_label.text = "DAY: " + str(game_manager.days)

func setup_timer():
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 3
	timer.connect("timeout", day_finished)

func next_day():
	day_label.set_anchors_preset(PRESET_CENTER, true)
	animation.play("day_counter")

func day_finished():
	animation.play("Results")

func _end_day():
	timer.start()
	show()
	get_tree().paused = true
	animation.play("Game_Over")
	AudioManager.play_sound(victory_sfx)
	game_manager._reset()

func _on_next_day_pressed():
	get_tree().change_scene_to_file("res://scene_0.tscn")
	get_tree().paused = false
	AudioManager.play_sound(click)
	game_manager.days += 1
