# level_config.gd
#######################################################
# Līmeņa konfigurācijas skripts.
# Ļauj katram līmenim ieslēgt/izslēgt dimensiju
# pārslēgšanu (piemēram, tutorial līmenī).
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.11.10. - Izveidota līmeņu konfigurācija
# Mainīts:   v1.1; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Node

# Pievieno šo skriptu līmeņa saknes mezglam,
# lai konfigurētu dimensiju pārslēgšanu šim līmenim

@export var enable_dimension_switching: bool = true

# Inicializācija - iestata dimensiju pārslēgšanas stāvokli
func _ready() -> void:
	var GS = get_node_or_null("/root/GameState")
	if GS:
		GS.set_dimension_switching(enable_dimension_switching)
		# Atiestata uz Despair dimensiju līmeņa sākumā, ja pārslēgšana ir atslēgta
		if not enable_dimension_switching:
			GS.current_dimension = GS.Dimension.DESPAIR
