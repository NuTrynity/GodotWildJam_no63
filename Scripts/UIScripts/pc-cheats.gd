extends CanvasLayer

@export var player_resources = PlayerResource
@export var cheats : Array[String]

@onready var input = %LineEdit
@onready var output_block = %OutputBlock
@onready var terminal = $Shop/PanelContainer/VBoxContainer/ScrollContainer/ShopItems/terminal
@onready var cash_label = $Shop/PanelContainer/VBoxContainer/Cash
@onready var output = preload("res://Nodes/UI/pc_output_text.tscn")

var line_text : String = ""
var click = load("res://Assets/SFX/click_sfx.ogg")

func _ready():
	terminal.item_bought.connect(_terminal_bought)

func _process(_delta):
	cash_label.text = "Cash-on-Hand: " + str(GlobalScript.money) + " $"

func _terminal_bought():
	$HomeScreen/Apps/Terminal.show()

func _on_line_edit_text_submitted(new_text):
	line_text = new_text
	input.clear()
	output_text()

func output_text():
	var line = output.instantiate()
	
	if line_text == "sudo --help":
		line.text = "Cheats:
		sudo give money - gives 9999 spendable funds
		sudo give rating - gives 999 ratings
		
		exit - exits the terminal
		clear - erases the terminal"
	elif line_text == cheats[0]:
		GlobalScript.money += 9999
		line.text = "Cheat Activated"
	elif line_text == cheats[1]:
		GlobalScript.ratings += 100
	elif line_text == "exit":
		$HomeScreen.show()
		$Terminal.hide()
	elif line_text == "clear":
		for otp in output_block.get_children(): #This code block gives errors, but doesn't do much
			if otp.is_in_group("terminal_lines"):
				otp.remove_from_group("terminal_lines")
				otp.queue_free()
	else:
		line.text = "Invalid Input see 'sudo --help'"
	
	output_block.add_child(line)

func _on_terminal_btn_pressed():
	$HomeScreen.hide()
	$Terminal.show()
	input.grab_focus()
	AudioManager.play_sound(click)

func _on_exit_btn_pressed():
	$Terminal.hide()
	$Shop.hide()
	$HomeScreen.show()
	AudioManager.play_sound(click)

func _on_shop_btn_pressed():
	$Shop.show()
	$HomeScreen.hide()
	AudioManager.play_sound(click)

func _on_power_btn_pressed():
	hide()
	get_tree().paused = false
	AudioManager.play_sound(click)
