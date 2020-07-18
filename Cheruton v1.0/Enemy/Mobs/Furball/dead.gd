extends baseState

const SPEED = 3200
const FREEZE_TIME = .02

var timer : float
func enter():
	var obj_pos = owner.hitter.global_position
	var move_dir = (owner.global_position - obj_pos ).normalized()

	owner.shake_camera(.06, 20.0, 42, -move_dir)
	owner.play_anim("die")
	get_tree().paused = false

	owner.velocity.x =  SPEED * move_dir.x

	timer = FREEZE_TIME


func update(delta):
	timer -= delta
	if timer > 0 : return

	owner.velocity.x = lerp(owner.velocity.x,0 , delta * 4)
	owner.velocity.y = clamp(owner.velocity.y + owner.GRAVITY/3 * delta, -INF, owner.TERMINAL_VELOCITY)

	owner.move()
