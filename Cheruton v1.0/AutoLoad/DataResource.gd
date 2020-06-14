extends Node

const MAIN = "res://SaveData/player-data.json"
const MASTERLIST = "res://SaveData/item-masterlist.json"

var current_scene = null

# Main Dict
var dict_main = {}
var dict_inventory = {}
var dict_player = {}
var dict_settings = {}

# Masterlist Dict
var dict_masterlist = {}
var dict_item_masterlist = {}
var dict_item_spawn = {}
var dict_item_shop = {}
# Stores any unsaved data regarding player stats
var temp_dict_player = {}

func load_data():
	#Editable
	dict_main = load_dict(MAIN)
	dict_masterlist = load_dict(MASTERLIST)
	dict_player = dict_main.player.main
	dict_settings = dict_main.settings.main
	dict_inventory = dict_main.inventory
	temp_dict_player = dict_player
	dict_item_shop = dict_masterlist.item_shop[temp_dict_player.stage]

	#Non-Editable
	dict_item_spawn = dict_masterlist.item_spawn
	dict_item_masterlist = dict_masterlist.item_masterlist

func load_dict(FilePath):
	var DataFile = File.new()
	if(FilePath == MAIN && !DataFile.file_exists(FilePath)): # create new save
		save_data(FilePath, dict_main)
		reset_all()
	DataFile.open(FilePath, File.READ)
	#DataFile.open_encrypted_with_pass(FilePath, File.READ, "mypass")
	var data = JSON.parse(DataFile.get_as_text())
	DataFile.close()
	print("Data Loaded!")
	return data.result

func save_player():
	dict_player = temp_dict_player
	save_data(MAIN, dict_main)

func save_rest():
	save_data(MAIN, dict_main)


func save_data(FILE, dictionary):
	var file = File.new()
	file.open(FILE, File.WRITE)
	#file.open_encrypted_with_pass(FILE, File.WRITE, "mypass")
	file.store_string(to_json(dictionary))
	file.close()

func restore_last_save():
	temp_dict_player = dict_player

func reset_all():
	dict_main = {"player": {"main": {}}, "settings": {"main": {}}, "inventory": {} }
	dict_main.player.main = dict_player
	dict_main.settings.main = dict_settings
	dict_main.inventory = dict_inventory
	reset_player()
	reset_settings()
	reset_inventory()

func reset_player():
	dict_player.exp_curr = 0
	dict_player.exp_max = 60
	dict_player.health_curr = 50
	dict_player.health_max = 50
	dict_player.level = 1
	dict_player.coins = 100
	dict_player.Weapons_item = null
	dict_player.Apparel_item = null
	dict_player.stage = "stage1"
	save_player()

func reset_settings():
	dict_settings.audio_master = -10
	dict_settings.audio_music = -10
	dict_settings.audio_sfx = -10
	dict_settings.is_mute = false
	save_rest()

func reset_inventory():
	dict_inventory.Weapons =  {}
	dict_inventory.Apparel = {}
	dict_inventory.Consum = {}
	dict_inventory.Misc = {}
	dict_inventory["Key Items"] = {}
	save_rest()
