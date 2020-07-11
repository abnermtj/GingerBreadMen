extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var bar = $Bar
onready var tween = $Tween
#onready var bar_type = get_parent().name

func init_bar():
#	match bar_type:
#		"Attack":
#			bar.value = 25#stub
#		"Defense":
#			bar.value = 50#stub
	bar.value = 60#stub

func change_bar_value(value):
	change_bar_colour(value)
	animate_bar(bar.value, value)


func change_bar_colour(value):
	if(value > bar.value):
		bar.set_tint_progress(Color(0, 1, 0))   # Green
	elif(value < bar.value):
		bar.set_tint_progress(Color(1, 0, 0))   # Red
	else:
		bar.set_tint_progress(Color(1, 1, 1))   # White

func animate_bar(start, end):
	tween.interpolate_property(bar, "value", start, end, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()