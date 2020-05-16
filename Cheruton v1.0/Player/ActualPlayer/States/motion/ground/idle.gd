extends groundState

func enter():
	owner.play_anim("idle")

func handle_input(event):
	return .handle_input(event)

func update(delta):
	 # change to move_and_slide_with_snap if ever using moving platforms
	owner.velocity = Vector2.DOWN  * 5  # this vector canot be just 1 unit else there may sometime be but in collision detection
	owner.move() # DOWN so we have collision response
	if not owner.is_on_floor():
		emit_signal("finished","fall")
	var input_direction = get_input_direction()
	if input_direction.x:
		emit_signal("finished", "run")

func _on_animation_finished(anim_name):
	if anim_name == "idle":
		owner.play_anim("idle_continious")
