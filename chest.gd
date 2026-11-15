extends Area2D
@onready var chesto = $chesto
func _ready():
	await get_tree().process_frame
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		var main_maze = get_parent()
		if main_maze and main_maze.has_method("add_chest_score"):
			main_maze.add_chest_score()
		print("Chest Collected")
		chesto.play()
		
		
		if has_node("Sprite2D"):
			$Sprite2D.visible = false
		elif has_node("AnimatedSprite2D"):
			$AnimatedSprite2D.visible = false
			
		
		set_deferred("monitoring", false)

		
		await chesto.finished
		queue_free()
