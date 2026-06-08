extends Node

func _ready() -> void:
	var packed_scene: PackedScene = load("res://scenes/main.tscn")
	var scene: Node = packed_scene.instantiate()
	add_child(scene)
	await get_tree().create_timer(3.0).timeout
	var img: Image = get_viewport().get_texture().get_image()
	img.save_png("res://artifacts/screenshot.png")
	print("SCREENSHOT_OK", img.get_width(), "x", img.get_height())
	await get_tree().create_timer(0.2).timeout
	get_tree().quit()
