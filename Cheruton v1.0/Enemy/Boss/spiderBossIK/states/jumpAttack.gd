extends baseState

const JUMP_VEL = -4500
const GRAVITY = 4000
enum stages {ANTICIPATION  = 0, JUMP = 1, LAND = 2, RECOVER = 3}

var timers_dict = {"ANTICIPATION" : 1.2}
var stage : int
var timer : float
var legs_repositioned : bool

func enter():
	stage = stages.ANTICIPATION

	for leg in owner.legs: # setup rihght before jump attack
		var desired_pos = leg.get_collision_point()
		if  desired_pos: leg.step(desired_pos)
	timer = timers_dict["ANTICIPATION"]
	legs_repositioned = false
	owner.set_body_collision(2)
	owner.diag_ray_cast_enable = false
	owner.floor_ray_cast_enable = false

	owner.desired_head_pos.y = owner.default_sprite_pos[0].y + 80
	owner.desired_butt_pos.y = owner.default_sprite_pos[3].y -40

func update(delta):
#	print(stage, owner.velocity)
	match stage:
		stages.ANTICIPATION:
			timer -= delta
			if timer < 0:
				stage = stages.JUMP
				owner.velocity = Vector2(0, JUMP_VEL)
				owner.desired_head_pos.y = owner.default_sprite_pos[0].y - 100
				owner.desired_butt_pos.y = owner.default_sprite_pos[3].y + 40
				return


			owner.velocity.x = lerp(owner.velocity.x , 0 , delta)
			owner.velocity.y = lerp(owner.velocity.y , 400 , delta)

		stages.JUMP:
			owner.velocity.y += GRAVITY * delta
			var player_pos = owner.player.global_position
			owner.velocity.x = (player_pos.x - owner.global_position.x ) * .75

			# setups landing of boss by preplacing where his legs should be
			if not legs_repositioned and owner.velocity.y > 0:
				legs_repositioned = true
				owner.hide()
				var save_pos = owner.global_position
				owner.global_position = player_pos + Vector2(0, -300)

				for leg in owner.legs:
					leg.force_raycast_update()
					leg.set_offset(Vector2()) # vector2() passed assumed to be the velocity of the spider as velocity.x is too great during the jump and overshoots the ideal leg landing position
					var col_point = leg.get_collision_point()
					if col_point: leg.step(col_point)


				owner.global_position = save_pos
				owner.show()

			if owner.is_on_floor() and owner.velocity.y > 0:
				stage = stages.LAND
				owner.jump_hurt_box_col_shape.disabled = false
				owner.velocity = Vector2(0,0)
				owner.desired_head_pos.y = owner.default_sprite_pos[0].y + 100
				owner.desired_butt_pos.y = owner.default_sprite_pos[3].y - 40

		stages.LAND:
			owner.jump_hurt_box_col_shape.disabled = true

			owner.velocity.y = lerp(owner.velocity.y, -200, delta/2)

			if not owner.ground_check.is_colliding(): # need more ray casts in the future if need to stand up at a corner, cuz the middle of body may not be on the floor side
				stage = stages.RECOVER

		stages.RECOVER:
			emit_signal("changeState", "run")

	owner.move()
func exit():
	owner.set_body_collision(0)
	owner.diag_ray_cast_enable = true
	owner.floor_ray_cast_enable = true

	owner.desired_head_pos.y = owner.default_sprite_pos[0].y
	owner.desired_butt_pos.y = owner.default_sprite_pos[3].y
