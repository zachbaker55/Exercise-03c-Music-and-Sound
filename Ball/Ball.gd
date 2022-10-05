extends RigidBody2D

var min_speed = 100.0
var max_speed = 600.0
var accelerate = false
var time_highlight = 0.4
var time_highlight_size = 0.3

var wobble_period = 0.0
var wobble_amplitude = 0.0
export var wobble_max = 5
var wobble_direction = Vector2.ZERO
var decay_wobble = 0.15

export var distort_effect = 0.0002

var h_rotate = 0.0

func _ready():
	contact_monitor = true
	contacts_reported = 8
	if Global.level < 0 or Global.level >= len(Levels.levels):
		Global.end_game(true)
	else:
		var level = Levels.levels[Global.level]
		min_speed *= level["multiplier"]
		max_speed *= level["multiplier"]
	

func _on_Ball_body_entered(body):
	if body.has_method("hit"):
		body.hit(self)
		accelerate = true
		$Tween.interpolate_property($Images/Highlight, "modulate:a", 1.0, 0.0, time_highlight, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		$Tween.interpolate_property($Images/Highlight, "scale", Vector2(2.0,2.0), Vector2(1.0,1.0), time_highlight_size, Tween.TRANS_BOUNCE, Tween.EASE_IN)
		$Tween.start()
		wobble_direction = linear_velocity.tangent().normalized()
		wobble_amplitude = wobble_max
	
	
func _integrate_forces(state):
	wobble()
	distort()
	comet()
	if position.y > Global.VP.y + 100:
		die()
	if accelerate:
		state.linear_velocity = state.linear_velocity * 1.1
		accelerate = false
	if abs(state.linear_velocity.x) < min_speed:
		state.linear_velocity.x = sign(state.linear_velocity.x) * min_speed
	if abs(state.linear_velocity.y) < min_speed:
		state.linear_velocity.y = sign(state.linear_velocity.y) * min_speed
	if state.linear_velocity.length() > max_speed:
		state.linear_velocity = state.linear_velocity.normalized() * max_speed


func wobble():
	wobble_period += 1
	if wobble_amplitude > 0:
		var pos = wobble_direction * wobble_amplitude * sin(wobble_period)
		$Images.position = pos
		wobble_amplitude -= decay_wobble

func distort():
	var direction = Vector2(1 + linear_velocity.length() * distort_effect, 1 - linear_velocity.length() * distort_effect)
	$Images.rotation = linear_velocity.angle()
	$Images.scale = direction
	
func comet():
	h_rotate = wrapf(h_rotate+0.1,0,1)
	var comet_container = get_node_or_null("/root/Game/Comet_Container")
	if comet_container != null:
		var sprite = $Images/Sprite.duplicate()
		sprite.modulate.s = 0.6
		sprite.global_position = global_position
		sprite.modulate.h = h_rotate
		comet_container.add_child(sprite)

func die():
	var die_sound = get_node_or_null("/root/Game/Die_Sound")
	if die_sound != null:
		die_sound.play()
	queue_free()
