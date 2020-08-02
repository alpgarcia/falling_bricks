class_name Main
extends Control


enum GameState {
	STOPPED,
	PLAYING,
	PAUSED
}

enum Rotate {
	NONE,
	LEFT,
	RIGHT
}

const ENABLED := false
const DISABLED := true

const MAX_LEVEL := 100

const START_POS := 15
const END_POS := 25

const TICK_SPEED := 1.0
const FAST_MULTIPLE := 10

const WAIT_TIME := 0.15
const REPEAT_DELAY := 0.05
const CLEANING_DELAY := 0.3
const LOCK_DELAY := 1.0

var state = GameState.STOPPED
var music_position := 0.0

var grid = []
var cols: int
var shape: ShapeData
var next_shape: ShapeData
var pos := 0
var count := 0
var bonus := 0

var lock_timer_consumed := false

onready var gui := $GUI as GUI
onready var music_player := $MusicPlayer as AudioStreamPlayer2D
onready var ticker := $Ticker as Timer
onready var left_timer := $LeftTimer as Timer
onready var right_timer := $RightTimer as Timer
onready var lock_timer := $LockTimer as Timer


func _ready() -> void:
	cols = gui.play_area_grid.get_columns()
	gui.set_button_states(ENABLED)
	gui.reset_stats()
	

func _input(event):
	if state == GameState.PLAYING:
		if event.is_action_pressed("ui_page_up"):
			increase_level()
			
		if event.is_action_pressed("ui_down"):
			bonus = 2
			soft_drop()
		
		if event.is_action_released("ui_down"):
			bonus = 0
			normal_drop()
		
		if event.is_action_pressed("ui_up"):
			hard_drop()
		
		if event.is_action_pressed("ui_left"):
			move_left()
			left_timer.start(WAIT_TIME)
		
		if event.is_action_released("ui_left"):
			left_timer.stop()
		
		if event.is_action_pressed("ui_right"):
			move_right()
			right_timer.start(WAIT_TIME)
		
		if event.is_action_released("ui_right"):
			right_timer.stop()
		
		if event.is_action_pressed("ui_rotate_left"):
			# TODO play a sound if can/can't move?
			var moved := move_shape(pos, Rotate.LEFT)
			# a succesful move gives extra moving time to undo the
			# movement or perform new ones.
			_check_lock_timer(moved)
		
		if event.is_action_pressed("ui_rotate_right"):
			# TODO play a sound if can/can't move?
			var moved := move_shape(pos, Rotate.RIGHT)
			# a succesful move gives extra moving time to undo the
			# movement or perform new ones.
			_check_lock_timer(moved)
			
		if event.is_action_pressed("ui_cancel"):
			_game_over()
			
		if event is InputEventKey:
			get_tree().set_input_as_handled()


func clear_grid() -> void:
	grid.clear()
	grid.resize(gui.play_area_grid.get_child_count())
	for i in grid.size():
		grid[i] = false
	gui.clear_all_cells()


func add_to_score(rows_cleared: int) -> void:
	gui.lines += rows_cleared
	var rows_score = 10 * int(pow(2, rows_cleared - 1))
	gui.score += rows_score
	print("Added %d to score." % rows_score)
	update_high_score()


func update_high_score() -> void:
	if gui.score > gui.hi_score:
		gui.hi_score = gui.score


func move_left() -> void:
	
	var shift := 0
	# line shape 4th rotation is shifted -1 columns with respect to
	# the grid position we will draw it, so it can be moved to the left 
	# one position less than the rest.
	if shape.coords.size() == 4 and shape.grid[0][1]:
		shift = -1
	
	if (pos + shift) % cols > 0:
		# TODO play a sound if can/can't move?
		move_shape(pos - 1)


func move_right() -> void:
	
	var shift := 0
	# line shape 4th rotation is shifted -1 columns with respect to
	# the grid position we will draw it, so it can be moved to the right 
	# one position more than the rest.
	if shape.coords.size() == 4 and shape.grid[0][1]:
		shift = -1
	
	if (pos + shift) % cols < cols - 1:
		# TODO play a sound if can/can't move?
		move_shape(pos + 1)


func new_shape() -> void:
	print("New Shape")
	if next_shape:
		shape = next_shape
	else:
		shape = ShapesFactory.get_shape()
	
	next_shape = ShapesFactory.get_shape()
	gui.set_next_shape(next_shape)
	pos = START_POS
	add_shape_to_grid()
	normal_drop()
	level_up()


func level_up() -> void:
	# TODO use number of lines to increase level
	count += 1
	if count % 10 == 0:
		increase_level()


func increase_level() -> void:
	if gui.level < MAX_LEVEL:
		gui.level += 1
		ticker.set_wait_time(TICK_SPEED / gui.level)


func normal_drop() -> void:
	ticker.start(TICK_SPEED / gui.level)


func soft_drop() -> void:
	ticker.stop()
	ticker.start(TICK_SPEED / (gui.level * FAST_MULTIPLE))


func hard_drop() -> void:
	ticker.stop()
	ticker.start(TICK_SPEED / 1000)


func move_shape(new_pos: int, dir := Rotate.NONE) -> bool:
	# Move the shape to the new position if it is a valid move.
	
	# Remove the shape from the grid so their own tiles doesn't
	# prevent the movement
	remove_shape_from_grid()
	
#	print("New Pos %d - Row: %d Col: %d" %
#			 [new_pos, (new_pos / cols), (new_pos % cols)])
	
	# Rotate the shape if requested
	var undo_dir = rotate(dir)
	# Check if the shape can be placed at the new grid position
	var valid = is_valid(new_pos)
	
	if valid:
		pos = new_pos
	else:
		# warning-ignore:return_value_discarded
		rotate(undo_dir)
		
	add_shape_to_grid()
	
	return valid

func rotate(dir: int) -> int:
	# Returns the oposite direction to allow to undo the rotation.
	# dir: either `LEFT` or `RIGHT` (enum values)
	
	match dir:
		Rotate.LEFT:
			shape.rotate_left()
			dir = Rotate.RIGHT
			
		Rotate.RIGHT:
			shape.rotate_right()
			dir = Rotate.LEFT
	
	return dir


func _check_lock_timer(moved: bool) -> void:
	# A succesful move gives extra moving time to undo the
	# movement or perform new ones.
	if moved and not lock_timer.is_stopped():
		lock_timer.start(LOCK_DELAY)	

func _remove_rows(index: int, rows: int) -> void:
	add_to_score(rows)
	print("Rows: %d" % rows)
	
	var num_cells := rows * cols
	# hide cells
	for n in num_cells:
		gui.play_area_grid.get_child(index + n + 1).modulate = Color(0)
	# brief pause before moving cells down to show the gap
	yield(get_tree().create_timer(CLEANING_DELAY), "timeout")
	
	# move cells down to fill in the gap
#	while index >= 0:
	for from in range(index, -1, -1):
		var to := from + num_cells
		grid[to] = grid[from]
#		# draw the tile only if it is fixed, falling shapes must be ignored
#		# by this process. In other case, draw an empty tile.
		if grid[to]:
			gui.play_area_grid.get_child(to).modulate = \
					gui.play_area_grid.get_child(from).modulate
		else:
			gui.play_area_grid.get_child(to).modulate = Color(0)
			
		# clear the top row
#		if from == 0:
#			grid[from] = false
#			gui.play_area_grid.get_child(from).modulate = Color(0)
		

func sleep(value := true):
	get_tree().paused = value
	if value:
		ticker.stop()
	else:
		ticker.start(TICK_SPEED / gui.level)


func _check_rows() -> void:
	# Iterate cell by cell from bottom to top.
	# - If all cols are occupied, increase row count.
	# - If empty cell found, skip that row.
	
	var rows := 0
	var x := 0
	var i: int = grid.size() - 1
	while i >= 0:
		if grid[i]:
			# increase column count 
			x += 1
			# complete row found
			if x == cols:
				rows += 1
				x = 0
				
			# move index to the next grid position
			i -= 1
			
		else:
			# reset index to the rightmost position of the row
			i += x
			if rows > 0:
				# TODO it may be better to remove all lines together at the
				# end to avoid to hide them in groups if there are
				# non-completed lines in between.
				yield(_remove_rows(i, rows), "completed")
			else:
				i -= cols
				
			# restart row counter as there are no more consecutive rows
			rows = 0
			# reset column count, set the index to next row
			x = 0


func add_shape_to_grid() -> void:
	# warning-ignore:return_value_discarded
	_place_shape(pos, true, false, shape.color)
	
	
func remove_shape_from_grid() -> void:
	# warning-ignore:return_value_discarded
	_place_shape(pos, true)


func lock_shape_to_grid() -> void:
	# warning-ignore:return_value_discarded
	_place_shape(pos, false, true)


func is_valid(index: int) -> bool:
	return _place_shape(index)


func _place_shape(index: int, add_tiles := false, lock := false, 
		color := Color(0)) -> bool:
	# index: grid position to insert the shape.
	# add_tiles: true for drawing the shape to the grid.
	# lock: lock the shape to the grid.
	# color: color of the shape. Use default value to erase the shape.
	
	# TODO take care because shape is global and could be not set which
	# will raise an exception here.
	
	var valid := true
	# Remember that shape coords are arond 0:
	# [-1, 1], [-1, 0, 1], [-2, -1, 1, 2]
	# so we loop through them using the range from 0 to their size
	# and the offset to place it in the grid around its center.
	var size: int = shape.coords.size()
	var offset = shape.coords[0]
	
	# The 4th rotation of the LINE SHAPE is drawn shifted -1 positions
	# with respect to the other 3 rotations. We need that shift to be able
	# to correctly calculate the righmost column:
	#   - Grid's column range = [1, 10]
	#   - Cols = 10
	#   - Columns range = [0, 9]
	#   - Base column of the shape = 1:
	#     [ -2 -1  1  2]
	#           X
	#           X
	#           X
	#           X
	#   - Thus, this is the only shape that can be placed at column 10
	#     of the grid because all its tiles are aligned one column at the
	#	  left . Without shift, that position wouldn't be valid:
	#
	#         index    columns    shape column    coords offset   NOT VALID
	#      (    10   %    10  ) +      1        +      -2       =   -1
	#
	#   - Then we need to shift the index and the coords offset to calculate
	#     the 10th column correctly:
	#         index     columns    shape column   coords offset   VALID
	#      ((10 + -1) %   10  ) +      1        +   (-2 - -1)   =  9
	#
	#
	var shift := 0
	if size == 4 and shape.grid[0][1]:
		shift = -1
	
	for row in size:
		for col in size:
			# check for tile in the given position of the shape's grid
			if shape.grid[row][col]:
				# calculate grid position for column y and row x
				var grid_pos = index + ((row + offset) * cols) + (col + offset)
				
				if lock:
					grid[grid_pos] = true
				
				# check whether the calculated pos is visible (on the grid)
				else:
					# column + tile position (local to the shape)
					var new_col = \
							((index + shift) % cols) \
							+ col + (offset - shift)
#					print("INDEX %d COL %d COL OFFSET %d = NEW COL %d" 
#							% [index, col, offset, new_col])
					# Check playing area limits and collisions:
					# - Values smaller than 0 for `grid_pos` are
					#   allowed for shapes that are not entirely in
					#   the play area (those entering from the top).
					# - These `grid_pos` values (< 0) are not in the
					#   playing grid, so they can't be checked for collisions.
					if new_col < 0 \
							or new_col >= cols \
							or grid_pos >= grid.size() \
							or (grid_pos >= 0 and grid[grid_pos]):
						valid = false
#						print("Index %d, col %d not valid." % [grid_pos, new_col])
						break
						
					if add_tiles and grid_pos >= 0:
						gui.play_area_grid.get_child(grid_pos).modulate = color
		
		# exit if we already detected that we can't place the shape
		# (basically one of its tiles can't be placed because the corresponding
		# grid position is already filled by another shape's tile)
		if not valid:
			break
	
	return valid


func _start_game() -> void:
	print("Game playing.")
	gui.set_button_states(DISABLED)
	state = GameState.PLAYING
	music_position = 0.0
	_play_music()
	
	lock_timer_consumed = false
	
	clear_grid()
	gui.reset_stats(gui.hi_score)
	
	new_shape()


func _pause_game():
	if state == GameState.PLAYING:
		print("Game paused.")
		state = GameState.PAUSED
		sleep()
		gui.set_button_text(gui.pause_button, "Resume")
		_pause_music()
		
	else:
		print("Game resumed.")
		state = GameState.PLAYING
		sleep(false)
		gui.set_button_text(gui.pause_button, "Pause")
		_play_music()


func _game_over() -> void:
	ticker.stop()
	left_timer.stop()
	right_timer.stop()
	gui.set_button_states(ENABLED)
	_pause_music()
	state = GameState.STOPPED
	print("Game Stopped.")


func _pause_music() -> void:
	if music_player.is_playing():
		music_position = music_player.get_playback_position()
		music_player.stop()
		print("Music stopped.")


func _play_music() -> void:
	if not music_player.is_playing():
		music_player.play(music_position)


func _on_GUI_button_pressed(action: int) -> void:
	match action:
		GUI.Action.NEW_GAME:
			_start_game()
			
		GUI.Action.PAUSE:
			_pause_game()
			
		GUI.Action.MUSIC:
			# Update the music player volume
			music_player.volume_db = gui.music_db
			print("Music changed. Level: %f db" % gui.music_db)
			
		GUI.Action.SOUND:
			print("Sound changed. Level: %f db" % gui.sound_db)


func _on_Ticker_timeout():
#	print("Ticker. Pos %d - Row: %d Col: %d" %
#			 [pos, (pos / cols), (pos % cols)])
	var new_pos = pos + cols
	if move_shape(new_pos):
		gui.score += bonus
		update_high_score()
		
	else:
		if new_pos <= END_POS:
			_game_over()
		
		# before locking the shape to the grid we let the user a short
		# time to allocate the shape.	
		elif lock_timer.is_stopped() and not lock_timer_consumed:
			# order matters: if we stop the timer first, one could
			# check the timer stopped and not consumed, and thus start
			# the lock timer again.
			# This way we make sure it is always consumed,
			# so we won't start the timer again.
			lock_timer_consumed = true
			lock_timer.start(LOCK_DELAY)
		
		# once the lock timer is stopped and we are sure the user consumed 
		# this extra time, the shape will be locked to the grid.
		elif lock_timer.is_stopped() and lock_timer_consumed:
			# Sleep while checking rows to avoid next shape to start
			# falling down.
			# Pause.Mode of MusicPlayer is set to Process to keep the music playing
			# regardless of the pause
			sleep()
			
			lock_shape_to_grid()
		
			var cleaning_rows = _check_rows()
			if cleaning_rows:
				# Prevent to add the new shape until completed rows are
				# cleaned
				yield(cleaning_rows, "completed")
			
			sleep(false)
			
			lock_timer_consumed = false
			new_shape()


func _on_LeftTimer_timeout():
	left_timer.wait_time = REPEAT_DELAY
	move_left()


func _on_RightTimer_timeout():
	right_timer.wait_time = REPEAT_DELAY
	move_right()


func _on_LockTimer_timeout():
	lock_timer.stop()
	
	
