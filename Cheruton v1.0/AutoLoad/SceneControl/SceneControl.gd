extends Node2D

onready var master_gui = preload("res://AutoLoad/levelguiMaster.tscn")
onready var arrow = preload("res://Display/MouseDesign/arrow.png")
onready var beam = preload("res://Display/MouseDesign/beam.png")

onready var levels = $Levels
onready var hud_elements = $HudLayer/Hud
onready var bg_music = $BgMusic
onready var bg_music_pitch = $BgMusic/VolPitch
onready var load_layer = $LoadLayer/Load


var curr_screen
var loot_dict = {} # Items pending transfer to inventory
var enable_save := false

var music_curr
var music_next
var fade_in := 0.14
var fade_out := 0.5
var music_state := "idle"

signal init_statbar


enum item{TYPE = 0, NAME = 1, AMOUNT = 2}

func _ready():
	randomize()
	initiate_music()
	DataResource.load_data()
	instance_gui()
	print("Yes")
	#init_cursor()

##############
# INITIALIZE #
##############

func init_music():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), DataResource.dict_settings.is_mute)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), DataResource.dict_settings.audio_master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), DataResource.dict_settings.audio_music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), DataResource.dict_settings.audio_sfx)


func init_cursor():
	Input.set_custom_mouse_cursor(arrow)
	Input.set_custom_mouse_cursor(beam, Input.CURSOR_IBEAM)

func instance_gui():
	var instanced_gui = master_gui.instance()
	SceneControl.add_child(instanced_gui)
	SceneControl.get_node("masterGui").enabled = false


################
# SCENE CHANGE #
################

# Loads the next scene
func load_screen(scene, game_scene:= false, loading_screen:= false):

	curr_screen = scene
	print( "LOADING SCREEN: ", curr_screen)
	
	get_tree().paused = true
	if(loading_screen):
		load_layer.show()

	if(hud_elements.visible):
		hud_elements.hide()

	var children = levels.get_children()
	if (!children.empty()):
		children[0].queue_free()

	var new_level = load(scene).instance()
	levels.add_child(new_level)

	if(game_scene):
		hud_elements.show()

	if(loading_screen):
		load_layer.hide()

	var new_music = levels.get_child(levels.get_child_count() - 1).bg_music_file
	print("new_music", new_music)
	change_music(new_music)

	print("Loaded")

	get_tree().paused = false

#############
# MUSIC FSM #
#############


func initiate_music():
	music_state = "init"
	music_next = null
	music_fsm()

func change_music(new_music):
	music_state = "clear"
	music_next = new_music
	music_fsm()

# Manages the background music being played

#	Idle: No music being played
#	Clear: Clears the current music being played
#	Init: Initalizes the next music stream
#	Active: Plays the current music stream

func music_fsm():
	print(music_state)
	match music_state:
		"idle":
			pass

		"clear":
			if(music_next):
				music_state = "init"
			else:
				music_state = "idle"

			if(fade_out > 0 && music_curr):
				bg_music.volume_db = -60.0
				call_deferred("music_fsm")#debug
				pass
				bg_music_pitch.play( "fade_out", -1, 1.0 / fade_out )
			else:
				bg_music.volume_db = -60.0
				call_deferred("music_fsm")

		"init":
			if(music_next):
				music_state = "active"
			else:
				music_state = "idle"

			music_curr = music_next
			bg_music.stream = music_curr

			if(fade_in > 0):
				bg_music.volume_db = .0
				call_deferred("music_fsm")#debug
				pass
				bg_music_pitch.play( "fade_in", -1, 1.0 / fade_in )
			else:
				bg_music.volume_db = 12.0
				call_deferred("music_fsm")

		"active":
			bg_music.play()


func _on_VolPitch_animation_finished(anim_name):
	music_fsm()

#func slow_music( n : int ):
#	match n:
#		0:
#			# normal mode
#			$music/pitch_control.play( "normal" )
#		1:
#			# slow down
#			$music/pitch_control.play( "slow" )
#		2:
#			# return to normal
#			$music/pitch_control.play_backwards( "slow" )
#
#func level_restart_sfx():
#	$level_restart.play()


########
# LOOT #
########

func determine_loot(map):
	var loot_count = determine_loot_count(map)
	loot_selector(map, loot_count)
	append_loot(loot_count)

# Determines the qty of tiems to be released
func determine_loot_count(map_name):
	var ItemMinCount = DataResource.dict_item_spawn[map_name].ItemMinCount
	var ItemMaxCount = DataResource.dict_item_spawn[map_name].ItemMaxCount

	randomize()
	var loot_count = randi()%((int(ItemMaxCount) - int(ItemMinCount))+ 1) + int(ItemMinCount)
	return loot_count

# Determines what items and their respective qty to be released
# Needs rework. Currently, the next loot item can only be obtained after the previous one is
func loot_selector(map_name, loot_count):
	for _i in range(loot_count):
		randomize()
		var index = 1
		var loot_chance = randi() % 100 + 1
		while(loot_chance > -1):
			# Item has been found - take note of its critical elements
			if(loot_chance <= DataResource.dict_item_spawn[map_name]["ItemChance"+ str(index)]):
				var loot = []
				loot.append(DataResource.dict_item_spawn[map_name]["ItemType"+ str(index)])
				loot.append(DataResource.dict_item_spawn[map_name]["ItemName"+ str(index)])
				#Randomize the qty of the item to be found
				loot.append(int(rand_range(float(DataResource.dict_item_spawn[map_name]["ItemMinQ" + str(index)]), float(DataResource.dict_item_spawn[map_name]["ItemMaxQ"+ str(index)]))))
				loot_dict[loot_dict.size() + 1] = loot
				break
			#Item not found, manipulate loot_chance val and compare against next index
			else:
				loot_chance -= DataResource.dict_item_spawn[map_name]["ItemChance" + str(index)]
				index += 1

# Transfers all loot present in loot_dict to dict_inventory
func append_loot(loot_count):
	var index = 1
	while loot_count:
		var item_type = loot_dict[index][item.TYPE]

		# Money
		if(loot_dict[index][0] == "Money"):
			DataResource.change_coins(int(loot_dict[index][item.AMOUNT]))

		# Non Money
		else:
			# Empty Tab
			if(DataResource.dict_inventory[item_type].size() == 0):
				var curr_size = DataResource.dict_inventory[item_type].size() + 1
				insert_data(index, curr_size)

			# Non-Empty Tab
			else:
				for i in range(1, DataResource.dict_inventory[item_type].size() + 1):
					# Item exists in inventory
					if(DataResource.dict_inventory[item_type]["Item" + str(i)].item_name == loot_dict[index][item.NAME]):
						DataResource.dict_inventory[item_type]["Item" + str(i)].item_qty += loot_dict[index][item.AMOUNT]
						break
					# Item not present
					var curr_size = DataResource.dict_inventory[item_type].size() + 1
					insert_data(index, curr_size)
		index += 1
		loot_count -= 1
	DataResource.save_rest()

# inserts item to inventory at insert_index
func insert_data(item_id, insert_index):
	var item_name = loot_dict[item_id][item.NAME]
	var stats =  {
				"item_name": loot_dict[item_id][1],
				"item_attack": DataResource.dict_item_masterlist[item_name].ItemAtk,
				"item_defense": DataResource.dict_item_masterlist[item_name].ItemDef,# stub - to update
				"item_statheal": DataResource.dict_item_masterlist[item_name].StatHeal,
				"item_healval": DataResource.dict_item_masterlist[item_name].HealVal,
				"item_value": DataResource.dict_item_masterlist[item_name].ItemValue,
				"item_details": DataResource.dict_item_masterlist[item_name].ItemDetails,
				"item_png": DataResource.dict_item_masterlist[item_name].ItemPNG,
				"item_qty": loot_dict[item_id][2],
		}
	DataResource.dict_inventory[loot_dict[item_id][item.TYPE]]["Item" + str(insert_index)] = stats

func _input(_ev):
	if Input.is_action_just_pressed("toggle_fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("save_player"):
		if(enable_save):
			DataResource.save_player()

