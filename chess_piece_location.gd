extends Area2D

var position_notation : Vector2

var piece = {"occupied":false,"piece":null}

func _ready():
	pass

func _process(delta):
	pass

func set_piece(body):
	piece["occupied"] = true
	piece["piece"] = body

func remove_piece():
	piece["piece"] = null
	piece["occupied"] = false

func _on_mouse_entered():
	if get_parent().get_parent().dragging == true:
		get_parent().get_parent().mouse_pos = position_notation
