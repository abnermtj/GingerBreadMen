extends groundState

const SLIDE_FRICTION = 2
const MIN_VEL = 100 # should somewhat higher than min run speed (to not goto idle straight away)(in $run) before turning to run
const SLIDE_PWR = 50
export (Curve) var attachment_curve

var initial_vel
var relative_vel

# Animation Player handles collsion
func enter():
	owner.switch_col()
	initial_vel = owner.velocity
	relative_vel = 0.01
	owner.play_anim("slide") # change to later on

func update(delta):
	relative_vel = attachment_curve.interpolate(relative_vel)

	owner.velocity = initial_vel * (1-relative_vel) + SLIDE_PWR*Vector2(get_input_direction().x,0)

	print(owner.slide_blocked)
	# player needss to move a certain time before can slide back up
	if ((not Input.is_action_pressed("slide") and abs(owner.velocity.x) < abs(initial_vel.x)/2\
	 or abs(owner.velocity.x) < MIN_VEL))\
	 and not owner.slide_blocked:
		print (owner.get_node("slideRay").is_colliding())
		emit_signal("finished", "run")
	owner.move_with_snap()
	.update(delta)

func exit():
	owner.switch_col()