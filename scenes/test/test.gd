class_name Test
extends Control
# Interactive integration test scene

var shape: ShapeData

onready var shape_label := $ShapeLabel as Label
onready var grid := $Grid as Label
onready var main := $Main as Main
onready var spin_box := $SpinBox as SpinBox


func _input(event):
	var new_pos: int = main.pos
	var dir: int = main.Rotate.NONE
	if event.is_action_pressed("ui_down"):
		new_pos += main.cols
	if event.is_action_pressed("ui_left"):
		new_pos -= 1
	if event.is_action_pressed("ui_right"):
		new_pos += 1
	if event.is_action_pressed("ui_up"):
		new_pos -= main.cols
	if event.is_action_pressed("ui_rotate_left"):
		dir = main.Rotate.LEFT
	if event.is_action_pressed("ui_rotate_right"):
		dir = main.Rotate.RIGHT
	
	if new_pos != main.pos or dir != main.Rotate.NONE:
		main.move_shape(new_pos, dir)
		get_tree().set_input_as_handled()


func _on_PickShape_button_down():
	shape = ShapesFactory.get_shape()
	shape_label.text = shape.name
	_show_grid()


func _on_RotateLeft_button_down():
	shape.rotate_left()
	_show_grid()


func _on_RotateRight_button_down():
	shape.rotate_right()
	_show_grid()
	

func _show_grid():
	grid.text = ""
	for row in shape.grid:
		for col in row:
			if col:
				grid.text += "x "
			else:
				grid.text += "_ "
		grid.text += "\n"


func _on_PlaceShape_button_down():
	main.clear_grid()
	main.shape = ShapesFactory.get_shape()
	main.pos = spin_box.value
	main.add_shape_to_grid()


func _on_RemoveShape_button_down():
	main.remove_shape_from_grid()


func _on_Lock_button_down():
	main.lock_shape_to_grid()
