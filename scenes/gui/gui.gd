class_name GUI
extends CenterContainer
# GUI
#
#

# action should be an Action enum value
signal button_pressed(action)

enum Action {
		NEW_GAME,
		PAUSE,
		MUSIC,
		SOUND,
		ABOUT
}

var music_db := 0.0
var sound_db := 0.0

var level: int = 1 setget set_level
var lines: int = 0 setget set_lines
var score: int = 0 setget set_score
var hi_score: int = 0 setget set_hi_score

onready var play_area_grid := $HBoxContainer/Center/Grid as GridContainer
onready var back_grid := $HBoxContainer/Center/BackGrid as GridContainer
onready var next_grid := $HBoxContainer/Right/NextContainer/Next as GridContainer
onready var about := $AboutDialog as AcceptDialog
onready var new_game_button := $HBoxContainer/Left/VBox/NewGame as Button
onready var pause_button := $HBoxContainer/Left/VBox/Pause as Button
onready var music_slider := $HBoxContainer/Left/VBox/MusicContainer/Music as HSlider
onready var sound_slider := $HBoxContainer/Left/VBox/SoundContainer/Sound as HSlider
onready var about_button := $HBoxContainer/Left/VBox/About as Button

onready var level_label := $HBoxContainer/Left/VBox/Statistics/Level as Label
onready var lines_label := $HBoxContainer/Left/VBox/Statistics/Lines as Label
onready var score_label := $HBoxContainer/Left/VBox/Statistics/Score as Label
onready var hi_score_label := $HBoxContainer/Left/VBox/Statistics/HighScore as Label


func _ready() -> void:
	# Set slider step
	music_slider.set_step(0.0001)
	sound_slider.set_step(0.0001)
	
	# create main game grid
	add_cells(back_grid, 200)
	add_cells(play_area_grid, 200)
	
	# Initialize grids
	clear_all_cells()


func set_level(value: int) -> void:
	level_label.text = str(value)
	level = value
	
func set_lines(value: int) -> void:
	lines_label.text = str(value)
	lines = value
	
func set_score(value: int) -> void:
	score_label.text = str(value)
	score = value
	
func set_hi_score(value: int) -> void:
	# set format to use hi-score to define UI width
	hi_score_label.text = "%08d" % value
	hi_score = value


func reset_stats(new_hi_score := 0, new_level := 1, new_score := 0, 
		new_lines := 0) -> void:
	self.level = new_level
	self.score = new_score
	self.hi_score = new_hi_score
	self.lines = new_lines


func load_settings(new_hi_score: int, music_value: int, sound_value: int) \
		-> void:
	self.hi_score = new_hi_score
	self.music_slider.value = music_value
	self.sound_slider.value = sound_value


func add_cells(grid: GridContainer, n: int) -> void:
	# Adds the specified number of cells to a grid container
	var num_cells: int = grid.get_child_count()
	while num_cells < n:
		# TODO instead of duplicating already existing cells we should
		#		load the cell as a scene, making it easily reusable.
		grid.add_child(grid.get_child(0).duplicate())
		num_cells += 1


func clear_cells(grid: GridContainer) -> void:
	for cell in grid.get_children():
		var tr: TextureRect = cell as TextureRect
		if tr:
			tr.modulate = Color(0)


func clear_all_cells() -> void:
	clear_cells(play_area_grid)
	clear_cells(next_grid)


func set_next_shape(shape: ShapeData) -> void:
	# Draws the shape to the next shape grid.
	
	# Remove previous cells (leave the first one intact
	# as it is used by `add_cells` to duplicate and create
	# the rest)
	# TODO once `add_cells` is npt based on duplicating an existing cell
	# 	we can remove all cells here. 
	for i in range(1, next_grid.get_child_count()):
		next_grid.remove_child(next_grid.get_child(i))
	
	var num_rows := shape.grid.size()
	var num_cols := shape.coords.size()
	
	next_grid.set_columns(num_cols)
	add_cells(next_grid, num_rows * num_cols)
	clear_cells(next_grid)
	
	for row in num_rows:
		for col in num_cols:
			var grid_pos: int = (row * num_cols) + col
			if shape.grid[row][col]:
				next_grid.get_child(grid_pos).modulate = shape.color


func set_button_state(button: Button, state: bool) -> void:
	button.set_disabled(state)


func set_button_text(button: Button, text: String) -> void:
	button.set_text(text)


func set_button_states(state: bool) -> void:
	set_button_state(new_game_button, state)
	set_button_state(about_button, state)
	
	set_button_state(pause_button, not state)


func _on_About_button_down() -> void:
	set_button_state(about_button, true)
	about.popup_centered()
	emit_signal("button_pressed", Action.ABOUT)


func _on_NewGame_button_down() -> void:
	emit_signal("button_pressed", Action.NEW_GAME)


func _on_Pause_button_down() -> void:
	emit_signal("button_pressed", Action.PAUSE)


func _on_AboutDialog_popup_hide() -> void:
	set_button_state(about_button, false)


func _on_Music_value_changed(value) -> void:
	music_db = linear2db(value)
	emit_signal("button_pressed", Action.MUSIC)


func _on_Sound_value_changed(value) -> void:
	sound_db = linear2db(value)
	emit_signal("button_pressed", Action.SOUND)
