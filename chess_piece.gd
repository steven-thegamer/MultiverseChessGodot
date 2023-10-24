extends Node2D

enum piece_type {
	BISHOP,
	KING,
	HORSE,
	PAWN,
	QUEEN,
	ROOK
}

enum team {
	BLACK = -1,
	WHITE = 1
}

var curr_pos : Vector2
var has_moved := false
var legal_move : Array[Vector2]
var offset : Vector2
var selected := false
var init_pos : Vector2
var _owner = null
var en_passant_move = []
var castling_move = []

@export var type : piece_type 
@export var color : team
@onready var sprite = $Sprite2D

func _ready():
	sprite.animation = "black" if color == -1 else "white"
	sprite.frame = type
	init_pos = position
	_owner.get_cell(curr_pos).set_piece(self)

func _process(delta):
	if selected:
		global_position = get_global_mouse_position() - offset

func get_legal_move():
	legal_move = []
	en_passant_move = []
	match(type):
		0:
			bishop_legal_move()
		1:
			king_legal_move()
		2:
			knight_legal_move()
		3:
			pawn_legal_move()
		4:
			queen_legal_move()
		5:
			rook_legal_move()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			offset = get_global_mouse_position() - global_position
			selected = true
			_owner.dragging = true
		else:
			selected = false
			_owner.dragging = false
			if _owner.mouse_pos in legal_move and _owner.player == color:
				_owner.get_cell(curr_pos).remove_piece()
				_owner.previous_piece_moved["prev_pos"] = curr_pos
				has_moved = true
				curr_pos = _owner.mouse_pos
				_owner.previous_piece_moved["curr_pos"] = curr_pos
				
				var attack_is_en_passant = true if type == 3 and curr_pos in en_passant_move else false
				var move_is_castling = true if type == 1 and curr_pos in castling_move else false
				
				if _owner.check_cell_occupied(curr_pos) == true:
					_owner.get_piece_occupying(curr_pos).queue_free()
				elif attack_is_en_passant:
					_owner.get_piece_occupying(Vector2(curr_pos.x,curr_pos.y - color)).queue_free()
				elif move_is_castling:
					if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y)) == false and _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y)).type == 5:
						var target_pos := Vector2(curr_pos.x-1,curr_pos.y)
						var piece = _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y))
						_owner.get_cell(Vector2(curr_pos.x+1,curr_pos.y)).remove_piece()
						_owner.get_cell(target_pos).set_piece(piece)
						_owner.get_piece_occupying(target_pos).curr_pos = target_pos
						_owner.get_piece_occupying(target_pos).init_pos = Vector2((target_pos.x-1)*22 + 13, (8-target_pos.y)*22 + 13)
						_owner.get_piece_occupying(target_pos).return_to_pos()
						
					elif cell_allowed(Vector2(curr_pos.x-2,curr_pos.y)) == false and _owner.get_piece_occupying(Vector2(curr_pos.x-2,curr_pos.y)).type == 5:
						var target_pos := Vector2(curr_pos.x+1,curr_pos.y)
						var piece = _owner.get_piece_occupying(Vector2(curr_pos.x-2,curr_pos.y))
						_owner.get_cell(Vector2(curr_pos.x-2,curr_pos.y)).remove_piece()
						_owner.get_cell(target_pos).set_piece(piece)
						_owner.get_piece_occupying(target_pos).curr_pos = target_pos
						_owner.get_piece_occupying(target_pos).init_pos = Vector2((target_pos.x-1)*22 + 13, (8-target_pos.y)*22 + 13)
						_owner.get_piece_occupying(target_pos).return_to_pos()
					
					
				_owner.get_cell(curr_pos).set_piece(self)
				init_pos = Vector2((curr_pos.x-1)*22 + 13, (8-curr_pos.y)*22 + 13)
				_owner.previous_piece_moved["piece"] = self
				_owner.check_every_piece_legal_move()
				_owner.switch_turn()
			return_to_pos()

func return_to_pos():
	position = init_pos


func pawn_legal_move():
	if !has_moved and cell_allowed(Vector2(self.curr_pos.x,self.curr_pos.y + 2*color)) and cell_allowed(Vector2(self.curr_pos.x,self.curr_pos.y + color)):
		legal_move.append(Vector2(self.curr_pos.x,self.curr_pos.y + 2*color))
	if cell_allowed(Vector2(self.curr_pos.x,self.curr_pos.y + color)):
		legal_move.append(Vector2(self.curr_pos.x,self.curr_pos.y + color))
	if cell_allowed(Vector2(self.curr_pos.x + 1, self.curr_pos.y + color)) or _owner.get_piece_occupying(Vector2(self.curr_pos.x + 1, self.curr_pos.y + color)).color != color:
		if _owner.get_piece_occupying(Vector2(self.curr_pos.x + 1, self.curr_pos.y + color)) != null:
			legal_move.append(Vector2(self.curr_pos.x + 1, self.curr_pos.y + color))
	if cell_allowed(Vector2(curr_pos.x - 1, curr_pos.y + color)) or _owner.get_piece_occupying(Vector2(curr_pos.x - 1, curr_pos.y + color)).color != color:
		if _owner.get_piece_occupying(Vector2(curr_pos.x - 1, curr_pos.y + color)) != null:
			legal_move.append(Vector2(curr_pos.x -1, curr_pos.y + color))
	
	# EN PASSANT
	if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y+color)) and cell_allowed(Vector2(self.curr_pos.x + 1, self.curr_pos.y)) == false and _owner.get_piece_occupying(Vector2(self.curr_pos.x + 1, self.curr_pos.y)) == _owner.previous_piece_moved["piece"] and abs(_owner.previous_piece_moved["curr_pos"].y - _owner.previous_piece_moved["prev_pos"].y) == 2 and _owner.get_piece_occupying(Vector2(self.curr_pos.x + 1, self.curr_pos.y)).color != color:
		legal_move.append(Vector2(curr_pos.x + 1, curr_pos.y + color))
		en_passant_move.append(Vector2(curr_pos.x + 1, curr_pos.y + color))
	
	if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y+color)) and cell_allowed(Vector2(self.curr_pos.x - 1, self.curr_pos.y)) == false and _owner.get_piece_occupying(Vector2(self.curr_pos.x - 1, self.curr_pos.y)) == _owner.previous_piece_moved["piece"] and abs(_owner.previous_piece_moved["curr_pos"].y - _owner.previous_piece_moved["prev_pos"].y) == 2 and _owner.get_piece_occupying(Vector2(self.curr_pos.x - 1, self.curr_pos.y)).color != color:
		legal_move.append(Vector2(curr_pos.x - 1, curr_pos.y + color))
		en_passant_move.append(Vector2(curr_pos.x - 1, curr_pos.y + color))
	
	# PROMOTION

func knight_legal_move():
	if cell_allowed(Vector2(curr_pos.x+2,curr_pos.y-1)) or _owner.get_piece_occupying(Vector2(curr_pos.x+2,curr_pos.y-1)).color != color:
		legal_move.append(Vector2(curr_pos.x+2,curr_pos.y-1))
	if cell_allowed(Vector2(curr_pos.x+2,curr_pos.y+1)) or _owner.get_piece_occupying(Vector2(curr_pos.x+2,curr_pos.y+1)).color != color:
		legal_move.append(Vector2(curr_pos.x+2,curr_pos.y+1))
	if cell_allowed(Vector2(curr_pos.x-2,curr_pos.y-1)) or _owner.get_piece_occupying(Vector2(curr_pos.x-2,curr_pos.y-1)).color != color:
		legal_move.append(Vector2(curr_pos.x-2,curr_pos.y-1))
	if cell_allowed(Vector2(curr_pos.x-2,curr_pos.y+1)) or _owner.get_piece_occupying(Vector2(curr_pos.x-2,curr_pos.y+1)).color != color:
		legal_move.append(Vector2(curr_pos.x-2,curr_pos.y+1))

	if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y-2)) or _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y-2)).color != color:
		legal_move.append(Vector2(curr_pos.x+1,curr_pos.y-2))
	if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y+2)) or _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y+2)).color != color:
		legal_move.append(Vector2(curr_pos.x+1,curr_pos.y+2))
	if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y-2)) or _owner.get_piece_occupying(Vector2(curr_pos.x-1,curr_pos.y-2)).color != color:
		legal_move.append(Vector2(curr_pos.x-1,curr_pos.y-2))
	if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y+2)) or _owner.get_piece_occupying(Vector2(curr_pos.x-1,curr_pos.y+2)).color != color:
		legal_move.append(Vector2(curr_pos.x-1,curr_pos.y+2))

func rook_legal_move():
	var compare = curr_pos + Vector2.UP
	while compare.x <= 8 and compare.x >= 1 and compare.y <= 8 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
			compare += Vector2.UP
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
	compare = curr_pos + Vector2.DOWN
	while compare.x <= 8 and compare.x >= 1 and compare.y <= 8 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
			compare += Vector2.DOWN
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
	compare = curr_pos + Vector2.LEFT
	while compare.x <= 8 and compare.x >= 1 and compare.y <= 8 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
			compare += Vector2.LEFT
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
	compare = curr_pos + Vector2.RIGHT
	while compare.x <= 8 and compare.x >= 1 and compare.y <= 8 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
			compare += Vector2.RIGHT
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
	
func bishop_legal_move():
	var compare = Vector2(curr_pos.x+1,curr_pos.y+1)
	while compare.x <= 8 and compare.y <= 8 and compare.x >= 1 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
		compare += Vector2(1,1)
	compare = Vector2(curr_pos.x+1,curr_pos.y-1)
	while compare.x <= 8 and compare.y <= 8 and compare.x >= 1 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
		compare += Vector2(1,-1)
	compare = Vector2(curr_pos.x-1,curr_pos.y+1)
	while compare.x <= 8 and compare.y <= 8 and compare.x >= 1 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
		compare += Vector2(-1,1)
	compare = Vector2(curr_pos.x-1,curr_pos.y-1)
	while compare.x <= 8 and compare.y <= 8 and compare.x >= 1 and compare.y >= 1:
		if cell_allowed(compare):
			legal_move.append(compare)
		else:
			if _owner.get_piece_occupying(compare).color != color:
				legal_move.append(compare)
			break
		compare += Vector2(-1,-1)

func queen_legal_move():
	rook_legal_move()
	bishop_legal_move()

func king_legal_move():
	if cell_allowed(Vector2(curr_pos.x,curr_pos.y-1)) or _owner.get_piece_occupying(Vector2(curr_pos.x,curr_pos.y-1)).color != color:
		legal_move.append(Vector2(curr_pos.x,curr_pos.y-1))
	if cell_allowed(Vector2(curr_pos.x,curr_pos.y+1)) or _owner.get_piece_occupying(Vector2(curr_pos.x,curr_pos.y+1)).color != color:
		legal_move.append(Vector2(curr_pos.x,curr_pos.y+1))
	if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y)) or _owner.get_piece_occupying(Vector2(curr_pos.x-1,curr_pos.y)).color != color:
		legal_move.append(Vector2(curr_pos.x-1,curr_pos.y))
	if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y)) or _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y)).color != color:
		legal_move.append(Vector2(curr_pos.x+1,curr_pos.y))
	if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y-1)) or _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y-1)).color != color:
		legal_move.append(Vector2(curr_pos.x+1,curr_pos.y-1))
	if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y+1)) or _owner.get_piece_occupying(Vector2(curr_pos.x+1,curr_pos.y+1)).color != color:
		legal_move.append(Vector2(curr_pos.x+1,curr_pos.y+1))
	if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y+1)) or _owner.get_piece_occupying(Vector2(curr_pos.x-1,curr_pos.y+1)).color != color:
		legal_move.append(Vector2(curr_pos.x-1,curr_pos.y+1))
	if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y-1)) or _owner.get_piece_occupying(Vector2(curr_pos.x-1,curr_pos.y-1)).color != color:
		legal_move.append(Vector2(curr_pos.x-1,curr_pos.y-1))
	
	# CASTLING
	if !has_moved:
		if cell_allowed(Vector2(curr_pos.x-1,curr_pos.y)) and cell_allowed(Vector2(curr_pos.x-2,curr_pos.y)) and cell_allowed(Vector2(curr_pos.x-3,curr_pos.y)) and _owner.get_piece_occupying(Vector2(curr_pos.x-4,curr_pos.y)) and _owner.get_piece_occupying(Vector2(curr_pos.x+3,curr_pos.y)).type == 5:
			castling_move.append(Vector2(curr_pos.x-2,curr_pos.y))
			legal_move.append(Vector2(curr_pos.x-2,curr_pos.y))
		if cell_allowed(Vector2(curr_pos.x+1,curr_pos.y)) and cell_allowed(Vector2(curr_pos.x+2,curr_pos.y)) and _owner.get_piece_occupying(Vector2(curr_pos.x+3,curr_pos.y)).has_moved == false and _owner.get_piece_occupying(Vector2(curr_pos.x+3,curr_pos.y)).type == 5:
			castling_move.append(Vector2(curr_pos.x+2,curr_pos.y))
			legal_move.append(Vector2(curr_pos.x+2,curr_pos.y))

func cell_allowed(pos : Vector2):
	return _owner.check_cell_occupied(pos)  == false
