extends Area2D

class_name InteractionArea

@export var action_name : String = "interact"

var interact : Callable = func():
	pass

func _on_body_entered(_body):
	InteractionManager.register_area(self)
	pass # Replace with function body.

func _on_body_exited(_body):
	InteractionManager.unregistered_area(self)
	pass # Replace with function body.
