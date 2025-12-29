# EndCredits.gd
#######################################################
# Beigu titru skripts.
# Attēlo ritošus titrus ar automātisku vertikālu
# kustību un fade efektiem, pēc tam atgriežas izvēlnē.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.12.15. - Izveidoti beigu titri
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Control

@onready var credits_container: VBoxContainer = $CreditsContainer
@onready var fade_rect: ColorRect = $FadeRect

var scroll_speed: float = 60.0
var auto_scroll: bool = false
var credits_finished: bool = false
var start_y: float = 0.0

# Inicializācija - sāk ar melnu ekrānu un iestata pozicīju
func _ready() -> void:
	# Sāk ar pakāpenisku parādīšanos no melna
	fade_rect.color.a = 1.0
	
	# Novieto titrus zem ekrāna
	start_y = get_viewport_rect().size.y
	credits_container.position.y = start_y
	
	# Pakāpeniska parādīšanās
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 1.5)
	
	# Sāk ritošanu pēc aizturēšanas
	await get_tree().create_timer(1.5).timeout
	auto_scroll = true

# Apstrādā katru kadru - ritina titrus uz augšu
func _process(delta: float) -> void:
	if auto_scroll and not credits_finished:
		# Virzit titrus uz augšu
		credits_container.position.y -= scroll_speed * delta
		
		# Pārbauda, vai esam ritinajuši garām visam
		var end_point = -(credits_container.size.y - get_viewport_rect().size.y / 2)
		if credits_container.position.y <= end_point:
			credits_finished = true
			_show_thank_you()

# Apstrādā lietotāja ievadi - atļauj izlaist titrus
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_return_to_menu()

# Parāda pateicības ziņojumu un atgriežas izvēlnē
func _show_thank_you() -> void:
	await get_tree().create_timer(3.0).timeout
	_return_to_menu()

# Atgriežas galvenajā izvēlnē ar fade efektu
func _return_to_menu() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
