extends Node

export var min_speed: float = 2
export var max_speed: float = 5

export var min_turn_speed: float = 0.1
export var max_turn_speed: float = 0.6

export var num_collision_rays: int = 25
export var collision_depth: float = 1.5

export var turn_fraction: float = .5
export var turn_speed: float = 1.0

export var look_back: float = -0.85 #when to prune from z (sphere > cone raycast parameter)

export var cohesion_weight: float = 0.5
export var avoidance_weight: float = 1
export var alignment_weight: float = 0.5
export var separation_weight: float = 0.5
