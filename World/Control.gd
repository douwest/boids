extends Control

onready var alignment_slider = $VBoxContainer/Alignment/AlignmentSlider
onready var cohesion_slider = $VBoxContainer/Cohesion/CohesionSlider
onready var separation_slider = $VBoxContainer/Separation/SeparationSlider
onready var avoidance_slider = $VBoxContainer/Avoidance/AvoidanceSlider

func _ready():
	alignment_slider.value = BoidProperties.alignment_weight
	cohesion_slider.value = BoidProperties.cohesion_weight
	separation_slider.value = BoidProperties.separation_weight
	avoidance_slider.value = BoidProperties.avoidance_weight

func _on_AlignmentSlider_value_changed(value):
	BoidProperties.alignment_weight = value


func _on_CohesionSlider_value_changed(value):
	BoidProperties.cohesion_weight = value


func _on_SeparationSlider_value_changed(value):
	BoidProperties.separation_weight = value


func _on_AvoidanceSlider_value_changed(value):
	BoidProperties.avoidance_weight = value
