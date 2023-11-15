extends Node2D

var is_empty : bool = true
var held_item : Node2D = null
	
func get_is_empty() -> bool:
	return is_empty
	
func add_item(item:Node2D) -> void:
	held_item = item
	held_item.global_position = global_position
	is_empty = false
	
func remove_item() -> Node2D:
	held_item = null
	is_empty = true
	return held_item
