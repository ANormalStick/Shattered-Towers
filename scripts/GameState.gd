# GameState.gd
#######################################################
# Globālais spēles stāvokļa pārvaldnieks (Autoload).
# Glabā un pārvalda pašreizējo dimensiju, atslēgas
# sistēmu un dimensiju pārslēgšanas stāvokli.
#######################################################
# Autors:    Jānis Mārtiņš Īvāns (JI23010)
# Radīts:    v1.0; 2025.09.24. - Dimensiju sistēma
# Mainīts:   v1.1; 2025.12.15. - Pievienota atslēgu sistēma
# Mainīts:   v1.2; 2025.12.29. - Koda formatēšana un komentāri
#######################################################

extends Node

signal dimension_changed(new_dimension: int)

enum Dimension { HOPE, DESPAIR }
var current_dimension: int = Dimension.DESPAIR

# Atslēgu/Durvju sistēma
var has_key: bool = false

# Dimensiju pārslēgšanas kontrole
var dimension_switching_enabled: bool = true

# Pārslēdz starp dimensijām
func switch_dimension():
	if not dimension_switching_enabled:
		return
	current_dimension = Dimension.HOPE if current_dimension == Dimension.DESPAIR else Dimension.DESPAIR
	emit_signal("dimension_changed", current_dimension)

# Atgriež true, ja pašreizējā dimensija ir Hope
func is_hope() -> bool:
	return current_dimension == Dimension.HOPE

# Izsauc, ielādējot jaunu līmeni, lai atiestatītu atslēgu stāvokli
func reset_level_state() -> void:
	has_key = false

# Ieslēdz vai izslēdz dimensiju pārslēgšanu (1. līmenim)
func set_dimension_switching(enabled: bool) -> void:
	dimension_switching_enabled = enabled
