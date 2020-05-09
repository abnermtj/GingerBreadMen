extends baseFSM

func _ready():
	states_map = {
		"idle": $idle,
		"run": $run,
		"jump": $jump,
		"stagger": $stagger,
		"attack": $attack,
		"fall": $fall,
		"roll": $roll,
	}

func _change_state(state_name):
	if state_name == "fall" or state_name == "jump":
		owner.on_floor = false
	else:
		#print("here")
		owner.on_floor = true
	print ("onfloor is ", owner.on_floor)
	print("changing to ", state_name)
	"""
	The base state_machine interface this node extends does most of the work
	"""
	if not _active:
		return
	print (owner.has_jumped)
	if (state_name in ["stagger", "jump", "attack"]):  # these are allowed to be placed ontop of other states
		states_stack.push_front(states_map[state_name])
	._change_state(state_name)

func _input(event):
	"""
	only attack can overwrite any other state
	"""
#	if event.is_action_pressed("attack"):
#		if current_state == $Attack:
#			return
#		_change_state("attack")
#		return
	current_state.handle_input(event)
