class_name ShapeData
extends Control


var color: Color
var grid: Array
var coords: Array


func rotate_left() -> void:
	_rotate_grid(1, -1)
	
	
func rotate_right() -> void:
	_rotate_grid(-1, 1)


func _rotate_grid(sign_of_x: int, sign_of_y: int) -> void:
	var rotated_grid: Array = grid.duplicate(true)
	for x in coords:
		for y in coords:
			# map x and y to array indices
			var x1 = coords.find(x)
			var y1 = coords.find(y)
			var x2 = coords.find(sign_of_y * y)
			var y2 = coords.find(sign_of_x * x)
			# note that y comes first because the grid is stored as
			# an array of rows, so we first specify the row number (y)
			# and then the column (x)
			rotated_grid[y1][x1] = grid[y2][x2]
	grid = rotated_grid
