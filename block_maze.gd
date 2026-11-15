
extends Node2D
var chests_opened_count=0 
var chest_label: Label
var win_button: Button
@onready var tilemaplayer = $TileMapLayer
const CHEST_SCENE = preload("res://chest.tscn")
const CHEST_COUNT = 5
const ROWS = 25
const COLS = 25
const WALL = Vector2i(0, 0)
const PATH = Vector2i(1, 0)
const TILE_SIZE = 16
var maze = []
var generate_button: Button

func _ready() -> void:
	setup_ui()
	generate_maze()
	
func setup_ui():
	generate_button = Button.new()
	generate_button.text = "Generate Maze"
	generate_button.position = Vector2(0, 0)
	generate_button.size = Vector2(150,30)
	generate_button.connect("pressed", Callable(self, "_on_generate_maze_pressed"))
	$CanvasLayer.add_child(generate_button)
	
	chest_label = Label.new()
	chest_label.name = "ChestLabel"
	chest_label.text = "Chests: 0 / 5"
	chest_label.position = Vector2(0, 40)
	$CanvasLayer.add_child(chest_label)
	
	win_button = Button.new()
	win_button.text = "YOU WIN! Click to Restart"
	win_button.position = Vector2(160, 0) # Placed right next to the generate button
	win_button.size = Vector2(180, 30)
	win_button.visible = false # Hidden until you win
	win_button.connect("pressed", Callable(self, "_on_win_pressed"))
	$CanvasLayer.add_child(win_button)
	
	
func _on_generate_maze_pressed():
	generate_maze()
	
func update_hud():
	if chest_label:
		chest_label.text = "Chests: " + str(chests_opened_count) + " / " + str(CHEST_COUNT)
func reset_maze():
	maze = []
	for r in range(ROWS):
		var row = []
		for c in range(COLS):
			row.append(1)
		maze.append(row)
	
func generate_maze():
	if win_button:
		win_button.visible = false
	if generate_button:
		generate_button.visible = true
	for child in get_children():
		if child.name == "ExitArea" or child.is_in_group("chest"):
			chests_opened_count = 0
			update_hud()
			child.queue_free()
			

	reset_maze()
	var start_row = 1
	var start_col = 1
	maze[start_row][start_col] = 0
	
	carve_passage(start_row, start_col)
	maze[ROWS - 2][COLS - 1] = 0
	print(maze)
	draw_maze()
	spawn_exit_zone()
	spawn_chests()
	
func carve_passage(row, col):
	var directions = [
		[-2, 0],
		[0, 2], 
		[2, 0], 
		[0, -2] 
	]
	
	directions.shuffle()
	
	for dir in directions:
		var dr = dir[0]
		var dc = dir[1]
		
		var new_row = row + dr
		var new_col = col + dc
		
		if (
			new_row > 0 and
			new_row < ROWS - 1 and
			new_col > 0 and
			new_col < COLS - 1 and 
			maze[new_row][new_col] == 1 
		):
			maze[new_row][new_col] = 0
			maze[row + dr / 2 ][col + dc / 2] = 0
			carve_passage(new_row, new_col)

func draw_maze():
	tilemaplayer.clear()
	
	for r in range(ROWS):
		for c in range(COLS):
			var tile_type = WALL if maze[r][c] == 1 else PATH
			tilemaplayer.set_cell(Vector2i(c, r), 0, tile_type)


func _process(delta: float) -> void:
	pass
	
func _on_button_pressed() -> void:
	generate_maze()

func spawn_exit_zone():
	var exit_area = Area2D.new()
	exit_area.name = "ExitArea"

	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	col.shape = rect
	exit_area.add_child(col)

	# Adds a green visual square at the exit
	var visual = ColorRect.new()
	visual.size = Vector2(16, 16)
	visual.position = -visual.size / 2
	visual.color = Color.GREEN
	exit_area.add_child(visual)

	exit_area.position = tilemaplayer.map_to_local(Vector2i(COLS - 1, ROWS - 2))
	exit_area.body_entered.connect(_on_exit_reached)
	add_child(exit_area)

func _on_exit_reached(body: Node2D):
	if body.is_in_group("player"):
		if chests_opened_count >= 5:
			print("YOU WIN!")
			generate_button.visible = false
			win_button.visible = true # Shows your new win button!
		else:
			print("Not enough chests! You lose, restarting...")
			get_tree().reload_current_scene()


func spawn_chests():
	var spawned_positions = []
	var player_cell = Vector2i(2, 2)

	while spawned_positions.size() < CHEST_COUNT:
		var row = randi_range(1, ROWS - 2)
		var col = randi_range(1, COLS - 2)

		var cell = Vector2i(col, row)
		if maze[row][col] == 0 and cell != player_cell:
			if not spawned_positions.has(cell):
				spawned_positions.append(cell)

				var chest = CHEST_SCENE.instantiate()
				chest.add_to_group("chest")

				# Get the exact centre of the maze tile
				var local_pos = tilemaplayer.map_to_local(cell)

				# Convert to the maze parent's coordinate system
				chest.position = to_local(tilemaplayer.to_global(local_pos))

				add_child(chest)
				chest.z_index = 10

				print("Chest spawned at grid: ", cell)
				print("Chest pixel position: ", chest.position)
func add_chest_score():
	chests_opened_count += 1
	print("Chests opened: ", chests_opened_count)
	update_hud() # <-- This updates the UI label immediately!

func _on_checkpoint_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
	
func _on_win_pressed():
	get_tree().reload_current_scene()
