extends Node2D

var player = 1
var turn := 0
var previous_piece_moved = {"piece": null, "prev_pos": null, "curr_pos": null}

@onready var cells = $ChessPieceLocations
@onready var pieces = $ChessPieces

const chess_cell = preload("res://chess_piece_location.tscn")
const chess_piece = preload("res://chess_piece.tscn")

var mouse_pos : Vector2
var dragging : bool = false

func _ready():
	for x in range(8):
		for y in range(8):
			# Create chess cell
			var obj = chess_cell.instantiate()
			obj.position = Vector2(13 + 22*x, 13 + 22*y)
			obj.position_notation = Vector2(x+1,8-y)
			cells.add_child(obj)
	for x in range(8):
		for y in range(8):
			match(y):
				0:
					var piece = chess_piece.instantiate()
					piece.color = -1
					match(x):
						0:
							piece.type = 5
						1:
							piece.type = 2
						2:
							piece.type = 0
						3:
							piece.type = 4
						4:
							piece.type = 1
						5:
							piece.type = 0
						6:
							piece.type = 2
						7:
							piece.type = 5
					piece.curr_pos = Vector2(x+1,8-y)
					piece.position = Vector2(13 + 22*x, 13 + 22*y)
					piece._owner = self
					pieces.add_child(piece)
				1:
					var piece = chess_piece.instantiate()
					piece.color = -1
					piece.type = 3
					piece.curr_pos = Vector2(x+1,8-y)
					piece.position = Vector2(13 + 22*x, 13 + 22*y)
					piece._owner = self
					pieces.add_child(piece)
				6:
					var piece = chess_piece.instantiate()
					piece.color = 1
					piece.type = 3
					piece.curr_pos = Vector2(x+1,8-y)
					piece.position = Vector2(13 + 22*x, 13 + 22*y)
					piece._owner = self
					pieces.add_child(piece)
				7:
					var piece = chess_piece.instantiate()
					piece.color = 1
					match(x):
						0:
							piece.type = 5
						1:
							piece.type = 2
						2:
							piece.type = 0
						3:
							piece.type = 4
						4:
							piece.type = 1
						5:
							piece.type = 0
						6:
							piece.type = 2
						7:
							piece.type = 5
					piece.curr_pos = Vector2(x+1,8-y)
					piece.position = Vector2(13 + 22*x, 13 + 22*y)
					piece._owner = self
					pieces.add_child(piece)
	check_every_piece_legal_move()


func check_every_piece_legal_move():
	for piece in pieces.get_children():
		piece.get_legal_move()

func switch_turn():
	player *= -1

func check_cell_occupied(pos:Vector2) -> bool:
	for cell in cells.get_children():
		if cell.position_notation == pos:
			return cell.piece["occupied"]
	return false

func get_cell(pos:Vector2):
	for cell in cells.get_children():
		if cell.position_notation == pos:
			return cell
	return null

func get_piece_occupying(pos:Vector2):
	for cell in cells.get_children():
		if cell.position_notation == pos:
			return cell.piece["piece"]
	return null
