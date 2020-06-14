extends KinematicBody2D

const SPEED_THROW_START = 2000
const SPEED_RETURN = 1450
const MAX_AIR_TIME = .6
const SPIN_SPEED = 2 # spins /s
const Y_LEVEL_FACTOR = 3 # swords tends to the player.pos.y during return

enum sword_states { SHOOT = 0, HIT = 1, RETURN = 2, HIDDEN = 3}

onready var sword_state = sword_states.HIDDEN
onready var bodyRotation = $bodyRotation
onready var airSprite = $bodyRotation/air
onready var hitSprite = $bodyRotation/hit

var velocity : Vector2
var angular_velocity : float
var cur_player_pos : Vector2
var state
var active : bool
var air_timer : float

signal sword_result

func _ready():
	bodyRotation.hide()
	state = sword_states.HIDDEN
	angular_velocity = SPIN_SPEED

func _on_flyingSword_command(command, arg):
	hitSprite.hide()
	airSprite.show()
	bodyRotation.show()

	if command == 0:
		set_collision_mask_bit(0,1)
		global_position =  DataResource.dict_player.player_pos
		active = true
		air_timer = MAX_AIR_TIME
		velocity = arg.normalized() * SPEED_THROW_START # arg is direction
		state = sword_states.SHOOT
	elif command == 1:
		state = sword_states.RETURN

func _physics_process(delta):
	if not active: return

	cur_player_pos = DataResource.dict_player.player_pos
	var bodies_in_collection_area = $collectionArea.get_overlapping_bodies()
	var bodies_in_limit_area = $limitArea.get_overlapping_bodies()

	if state == sword_states.HIT:
		if bodies_in_collection_area:
			state = sword_states.RETURN
		if not bodies_in_limit_area:
			state = sword_states.RETURN

	match state:
		sword_states.SHOOT:
			bodyRotation.rotate(angular_velocity)

			air_timer -= delta
			if air_timer < 0 :
				state = sword_states.RETURN
				return

			if move_and_collide(velocity*delta):
				hitSprite.show()
				airSprite.hide()
				state = sword_states.HIT
				emit_signal("sword_result", 0, global_position)

		sword_states.RETURN:
			set_collision_mask_bit(0,0)
			bodyRotation.rotate(angular_velocity)

			var direction = cur_player_pos - global_position # go towards player
			velocity = direction.normalized() * SPEED_RETURN + Vector2(0,Y_LEVEL_FACTOR * (cur_player_pos.y-global_position.y)) # curves the return
			move_and_collide(velocity * delta)

			if (global_position - cur_player_pos).length() < 20:
				state = sword_states.HIDDEN
			emit_signal("sword_result", 1, Vector2())
		sword_states.HIDDEN:
			bodyRotation.hide()
			active = false

			emit_signal("sword_result", 2, Vector2())
