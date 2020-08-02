extends GridContainer
# Factory in charge of creating ShapeData objects (our falling blocks)
#
# - Rotating a shape 90º clockwise is rotating the x-axis until it becomes 
#	the y-axis and the y-axis until it becomes the x-axis (we need to invert
#	its indexes).
# - Rotatimg a shape 90º counter-clockwise is rotating the  x-axis until it 
#	becomes the y-axis (we need to invert its indexes) and the y-axis
#	until it becomes the x-axis.
#
#   - Clockwise rotation: 		- Anti-clockwise rotation:
#		x = -y, y = x				x = y, y = -x
#
#  -2 -1  1  2			-2 -1  1  2 
# |  |  |  |  | -2		|  |  |##|  | -2     
# |##|##|##|##| -1		|  |  |##|  | -1  (Y axis)
# |  |  |  |  |  1		|  |  |##|  |  1
# |  |  |  |  |  2		|  |  |##|  |  2
# 
#	(X axis)				 (X axis)
#
#   -1  0  1 		 	-1  0  1 
#  |##|##|  | -1			|  |  |##| -1
#  |  |##|##|  0			|  |##|##|  0  (Y axis)
#  |  |  |  |  1			|  |##|  |  1
#

var _shapes: Array = []
var _index: int = 0


func _ready() -> void:
	
	# Init the random number generator seed, used for shuffling shapes
	randomize()
	
	for child in get_children():
		
		var block_shape: GridContainer = child as GridContainer
		
		var shape_data = ShapeData.new()
		shape_data.name = block_shape.name
		shape_data.color = block_shape.modulate
		
		# grid coords go around 0 for ease rotation (pos/neg, neg/pos)
		# e.g -2, -1, 1, 2 (even sized grid)
		# e.g. -1, 0, 1 (odd sized grid)
		var max_coord: int = block_shape.columns / 2
		shape_data.coords = range(-max_coord, max_coord + 1)
		
		# remove the zero coordinate for even-sized grids
		if block_shape.columns % 2 == 0:
			# max_coord is columns/2, i.e. the zero coordinate 
			shape_data.coords.remove(max_coord)
		#print(shape_data.coords)
		shape_data.grid = _get_grid(
				block_shape.get_children(), 
				block_shape.columns)
		
		_shapes.append(shape_data)


func get_shape() -> ShapeData:
	
	# TODO this approach will return all possible shapes before
	# repeating the same shape. Improve this to return a random
	# shape each time or maybe use a probability for each shape.
	if _index == 0:
		_shapes.shuffle()
		_index = _shapes.size()
	
	_index -= 1
	
	# Create a copy of the corresponding shape and return it
	var s := ShapeData.new()
	s.name = (_shapes[_index] as ShapeData).name
	s.color = (_shapes[_index] as ShapeData).color
	s.coords = (_shapes[_index] as ShapeData).coords
	s.grid = (_shapes[_index] as ShapeData).grid
	
	return s


func _get_grid(cells: Array, cols: int) -> Array:
	# returns an array of rows. Each row is an array of booleans representing
	# whether the given cell is filled (True) or empty (False).
	
	var grid: Array = []
	
	for nrow in range(cells.size() / cols):
		var row: Array = []
		for ncol in range(cols):
			row.append((cells[(nrow * cols) + ncol] as TextureRect).modulate.a > 0)
		
		grid.append(row)
			
			
#	var i: int = 0
#
#	for cell in cells:
#		row.append((cell as TextureRect).modulate.a > 0)
#		i += 1
#		if i == cols:
#			grid.append(row)
#			i = 0
#			row = []
	
	return grid
	
