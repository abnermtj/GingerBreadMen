extends airState
#NOTE some keyboards cannot detect pressing up,left and space simulatenously google NKRO

const JUMP_RELEASE_SLOWDOWN = .72 #after releasing jump key how much to slow down by 0 to 1
const JUMP_TERMINAL_VELOCITY = 10000
const NORMAL_GRAV_MULTIPLIER = .42
const MIN_BOUNCE_POWER = 666
const MIN_ENTER_VELOCITY_X = 420
const JUMP_VEL = -666
const CORNER_CORRECTION_DISPLACEMENT = 7

var keypress_timer # timer that allaws paper to keep boosting jump height
var dash_timer
var enter_velocity
var input_dir
var bounce_boost
var grav_multiplier

func enter() -> void:
	enter_velocity = owner.velocity
	if MIN_ENTER_VELOCITY_X > abs(enter_velocity.x): # x can't go faster than enter velocity.x
		enter_velocity.x = MIN_ENTER_VELOCITY_X

	owner.has_jumped = true

	var prev_state_name = get_parent().previous_state.name

	grav_multiplier = NORMAL_GRAV_MULTIPLIER
	bounce_boost = false
	if owner.bounce_boost:
		owner.velocity.y = -owner.velocity.y*.7  # reverse dir
		if abs(owner.velocity.y) < MIN_BOUNCE_POWER:
			owner.velocity.y = MIN_BOUNCE_POWER * sign(owner.velocity.y)
		bounce_boost = true
		owner.bounce_boost = false
		grav_multiplier = 1
	elif prev_state_name != "hook":
		owner.velocity.y = JUMP_VEL # old speed kept
		owner.play_anim_fx("jump")

	if prev_state_name == "wallslide": # wall jump
		input_dir = get_input_direction()
		owner.velocity.x = -JUMP_VEL*input_dir.x

	owner.move() # instant feedback
	owner.play_anim("jump")
	owner.play_sound("jump")
	keypress_timer = 0.2
	dash_timer = .1

func update( delta ):
	owner.velocity.y = min( JUMP_TERMINAL_VELOCITY , owner.velocity.y + owner.GRAVITY * grav_multiplier * delta)# use delta for all acceleration based movements

	keypress_timer -= delta
	dash_timer -= delta
	if keypress_timer < 0 or Input.is_action_just_released( "jump" ):
		keypress_timer = -1.0
		if not bounce_boost:
			owner.velocity.y *= JUMP_RELEASE_SLOWDOWN

	# steering here
	input_dir = get_input_direction()
	update_look_direction(input_dir)
	# corner correction
	var corner_dir = owner.is_there_corner_above()
	if corner_dir == 1: # on the right, move left
		owner.position.x -= CORNER_CORRECTION_DISPLACEMENT
	elif corner_dir == -1: #left
		owner.position.x += CORNER_CORRECTION_DISPLACEMENT
	if input_dir.x: # tend to input dir if steering
		owner.velocity.x = clamp ((owner.velocity.x + input_dir.x*owner.AIR_ACCEL), -abs(enter_velocity.x), abs(enter_velocity.x))
	else: # tend .x to 0 if not steerings
		owner.velocity.x = lerp( owner.velocity.x, 0, owner.AIR_ACCEL * delta )

	owner.move()

	# Result of movement
	if	 owner.is_on_ceiling():
		owner.velocity.y = 0.0
		emit_signal("finished","fall")
	else:
		if owner.velocity.y > 0:
			if owner.is_almost_at_a_platform():
				owner.position.y -= 10
			emit_signal("finished","fall")

	if Input.is_action_just_pressed("dash") and owner.can_dash and dash_timer < 0:
		emit_signal("finished", "dash")
	.update(delta)

