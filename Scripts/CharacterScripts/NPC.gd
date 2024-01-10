extends CharacterBody2D
class_name Npc

signal ready_for_cat
signal leaving

@export var game_manager : GameManager
@export var player_resources : PlayerMealCarry
@export var patience : float

@onready var pivot : Node2D = $NPCSkin
@onready var start_scale : Vector2 = pivot.scale
@onready var animations = $NPCSkin/NPCAnimations
@onready var npc_sprite = $NPCSkin/NPCSprite as Sprite2D
@onready var meal_want = $NPCSkin/ThoughtBubble/MealWanted
@onready var thought_bubble = $NPCSkin/ThoughtBubble
@onready var interact_area = $InteractionArea
@onready var patience_bar = $Patience
@onready var patience_timer = Timer.new()
@onready var eat_timer = Timer.new()
@onready var aiMvt := $AiMovement as NpcAiMovement
@onready var meal_price_label = preload("res://Nodes/UI/meal_price_on_buy.tscn")

var meal_i_want : int
var can_be_interacted : bool = false
var is_leaving : bool = false
var is_sitting : bool = false
var is_angry : bool = false

# for cat targeting
var targeter : Node2D = null

var current_meal : Node2D = null

enum State {APPROACH, IDLE, ACT, LEAVE}
var state := State.IDLE as State

func _ready():
	patience_bar.max_value = patience
	patience_bar.global_position.y -= 64
	patience_bar.hide()
	
	interact_area.interact = Callable(self, "_on_player_give_meal")
	interact_area.monitoring = false
	
	npc_sprite.flip_h = false
	
	meal_want.hide()
	thought_bubble.hide()
	meal_i_want = player_resources.randomize_meal_index()
	if meal_i_want == 0:
		meal_want.texture = load("res://Sprites/omurice.png")
	elif meal_i_want == 1:
		meal_want.texture = load("res://Sprites/cat_latte.png")
		
	idle_animation()

'''
func _physics_process(_delta : float) -> void:
	patience_bar.value = patience
	
	if can_be_interacted == false:
		interact_area.monitoring = false
	else:
		interact_area.monitoring = true
	#NPC State Block
	if aiMvt.reached_target() && not is_leaving:
		animations.play("sitting")
		npc_sprite.texture = load("res://Sprites/customer sprites/customer1_sitting.png")
	else:
		animations.play("walking")
		patience_bar.hide()
		npc_sprite.texture = load("res://Sprites/customer sprites/customer1_standing.png")
	
	if is_sitting == false:
		if not is_zero_approx(velocity.x):
			pivot.scale.x = sign(velocity.x) * start_scale.x
'''

func _physics_process(_delta : float) -> void:
	match state:
		# idle: deciding what to do
		State.IDLE:
			var find_target = aiMvt.find_and_pick_target()
			if find_target != null:
				aiMvt.makepath()
				state = State.APPROACH
			
		# approaching: going towards target
		State.APPROACH:
			aiMvt.approach_target()
			walk_animation()
			
			if aiMvt.reached_target():
				state = State.ACT
				aiMvt.target.npc_act_setup(self)
			
		# acting: interacting with target, target should take control of the npc to decide what they're doing
		State.ACT:
			aiMvt.target.npc_act(self)
			# target sets the state to LEAVE
			
		# leaving: npc is approaching door
		State.LEAVE:
			aiMvt.approach_target()
			walk_animation()

func sit_area_act_setup():
	patience_timer_setup()
	patience_bar.value = patience
	patience_timer.start()
	patience_bar.show()
	meal_want.show()
	thought_bubble.show()
	interact_area.monitoring = true
	
	emit_signal("ready_for_cat", self)
	sit_animation()
	
func sit_area_act():
	pass
	
func sit_area_leave():
	state = State.LEAVE
	aiMvt.goto_exit()
	leaving.emit()
	meal_want.hide()
	thought_bubble.hide()
	patience_bar.hide()
	interact_area.monitoring = false
	
	if is_angry == true:
		meal_want.show()
		thought_bubble.show()
	else:
		meal_want.hide()
		thought_bubble.hide()

# ends sit_area action
func _on_meal_finished():
	current_meal.queue_free()
	current_meal = null
	aiMvt.target.npc_leave(self)
	
func _on_timer_timeout():
	patience -= 1
	patience_bar.value = patience
	
	# out of patience, gets angry and leaves
	if patience_bar.value <= 0:
		patience_timer.stop()
		aiMvt.target.npc_leave(self)
		
		player_resources.adjust_rating(-player_resources.rating_decrease_amt)
	
# used by targets to tell npc to leave
func set_leave_state():
	state = State.LEAVE
	
func walk_animation():
	animations.play("walking")
	if velocity.x > 0:
		npc_sprite.flip_h = true
	else:
		npc_sprite.flip_h = false
	npc_sprite.texture = load("res://Sprites/customer sprites/customer1_standing.png")

func sit_animation():
	animations.play("sitting")
	npc_sprite.texture = load("res://Sprites/customer sprites/customer1_sitting.png")
	
	var sit_area = aiMvt.target as SitArea
	if sit_area.facing_left:
		npc_sprite.flip_h = false
	else:
		npc_sprite.flip_h = true
	
func idle_animation():
	animations.play("idle")
	npc_sprite.texture = load("res://Sprites/customer sprites/customer1_standing.png")
	
func patience_timer_setup():
	add_child(patience_timer)
	patience_timer.one_shot = false
	patience_timer.wait_time = 0.1
	patience_timer.connect("timeout", _on_timer_timeout)
	
	add_child(eat_timer)
	eat_timer.one_shot = true
	eat_timer.wait_time = 5
	eat_timer.connect("timeout", _on_meal_finished)

func _on_player_give_meal():
	player_resources.give_meal(self)

func spawn_label():
	var price_label = meal_price_label.instantiate()
	price_label.price = str(GlobalScript.meal_types[meal_i_want]["price"] * game_manager.combo_meter)
	price_label.position = global_position
	price_label.position.y -= 360 #just on her head
	price_label.position.x -= price_label.size.x / 2
	get_parent().add_child(price_label)

func grab_meal(meal):
	var sit_area = aiMvt.target as SitArea
	player_resources.carry_amt -= 1
	meal.get_parent().remove_child(meal)
	add_child(meal)
	meal.global_position = self.global_position
	meal.position.y -= 143
	current_meal = meal
	
	if sit_area.facing_left:
		meal.position.x -= 150
	else:
		meal.position.x += 150

	patience_timer.stop()
	patience_bar.hide()
	meal_want.hide()
	thought_bubble.hide()
	eat_timer.start()
	game_manager.start_combo.emit()
	interact_area.monitoring = false
	
	spawn_label()
	GlobalScript.inventory[meal_i_want]["count"] -= 1
	GlobalScript.cash_on_hand += GlobalScript.meal_types[meal_i_want]["price"] * game_manager.combo_meter
	player_resources.adjust_rating(player_resources.rating_increase_amt, patience_bar)
	game_manager.combo_meter += 1

'''
func _on_chair_detector_area_entered(area):
	if area.is_in_group("chair"):
		is_sitting = true
		can_be_interacted = true
		patience_timer.start()
		patience_bar.show()
		meal_want.show()

func _on_chair_detector_area_exited(area):
	if area.is_in_group("chair"):
		is_sitting = false
		can_be_interacted = false
		meal_want.hide()
		patience_timer.stop()
'''

func _on_leave_detector_area_entered(area):
	if area.is_in_group("LeaveArea"):
		if state == State.LEAVE:
			game_manager.check_result()
			queue_free()

# returns point where cat should sit nearby, don't call when leaving
func get_cat_point() -> Node2D:
	var sit_area = aiMvt.target as SitArea
	return sit_area.get_cat_point()
	
func ready_for_cat_func():
	if (state == State.ACT && patience_bar.is_visible()):
		emit_signal("ready_for_cat", self)
