extends Control

@export var resources : PlayerMealCarry
@export var game_manager : GameManager
@export var qouta : int

@onready var animation = $AnimationPlayer
@onready var money_label = $Results/Money/Amt/Result
@onready var ratings = $Results/Label/RatingBar
@onready var day_label = $DayLabel
@onready var timer = Timer.new()
@onready var qouta_timer = Timer.new()

var click = load("res://Assets/SFX/click_sfx.ogg")
var victory_sfx = load("res://Assets/Music/Good Job!.wav")
var current_qouta : int = 0

func _ready():
	game_manager.day_end.connect(_end_day)
	ratings.max_value = qouta
	
	setup_timer()
	next_day()

func _process(_delta):
	money_label.text = "$ " + str(GlobalScript.cash_on_hand)
	ratings.value = current_qouta
	day_label.text = "DAY " + str(game_manager.days)
	
	if GlobalScript.rating >= current_qouta:
		qouta += qouta * 1.1
		current_qouta = 0

func setup_timer():
	add_child(timer)
	timer.one_shot = true
	timer.wait_time = 3
	timer.connect("timeout", day_finished)
	
	add_child(qouta_timer)
	qouta_timer.one_shot = false
	qouta_timer.wait_time = 0.1
	qouta_timer.connect("timeout", increase_qouta)

func increase_qouta():
	if current_qouta <= GlobalScript.rating:
		current_qouta += 100
		GlobalScript.rating -= 100
	else:
		qouta_timer.stop()

func next_day():
	animation.play("day_counter")
	await animation.animation_finished
	hide()

func day_finished():
	animation.play("Results")
	
	await animation.animation_finished
	qouta_timer.start()

func _end_day():
	timer.start()
	show()
	get_tree().paused = true
	animation.play("Game_Over")
	AudioManager.play_sound(victory_sfx)
	game_manager._reset()
	resources.carry_amt = 0

func _on_next_day_pressed():
	get_tree().reload_current_scene()
	AudioManager.play_sound(click)
	game_manager.days += 1
