extends Control

@onready var credits_container: VBoxContainer = $CreditsContainer
@onready var fade_rect: ColorRect = $FadeRect

var scroll_speed: float = 60.0
var auto_scroll: bool = false
var credits_finished: bool = false
var start_y: float = 0.0

func _ready() -> void:
	# Start with fade in from black
	fade_rect.color.a = 1.0
	
	# Position credits below the screen
	start_y = get_viewport_rect().size.y
	credits_container.position.y = start_y
	
	# Fade in
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.5)
	
	# Start scrolling after delay
	await get_tree().create_timer(1.5).timeout
	auto_scroll = true

func _process(delta: float) -> void:
	if auto_scroll and not credits_finished:
		# Move credits up
		credits_container.position.y -= scroll_speed * delta
		
		# Check if we've scrolled past everything
		var end_point = -(credits_container.size.y - get_viewport_rect().size.y / 2)
		if credits_container.position.y <= end_point:
			credits_finished = true
			_show_thank_you()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_return_to_menu()

func _show_thank_you() -> void:
	await get_tree().create_timer(3.0).timeout
	_return_to_menu()

func _return_to_menu() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
