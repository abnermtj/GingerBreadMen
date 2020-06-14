extends Node2D

# lerp coefficients
const SHOOT_OFFSET_INCREASE = -1
const SHOOT_AMP_DECREASE = 2.3
const SHOOT_WID_DECREASE = 2.4
const LINE_WIDTH = 12

var length_divisor = 1 #used to get the number of points in the line, we then connect those points via polyline

var stage
const INITIAL_SHOOT = 1
const JUST_HOOKED = 2
const RETRACT = 3

var color_outline = Color(0.07843, 0.0627, 0.125)
var color_inner = Color(.9,.9,.9)
export (Curve) var attachment_curve

var length
var c = 1 # set in player function # similar to offset
var s = .68 #  inverse wave length # 2
var w = 1# wave length
var a = 1# amplitude
var rng = RandomNumberGenerator.new()

func _draw(): # gets called once initially then again when update() is called
	var points_arr = PoolVector2Array() # an array specifically to hold Vector2

	length = c
	var d = c/(w+(1-s)*w)
	for point_idx in range (length/length_divisor):
		var y_pos = (-4 * pow(2, point_idx/c - 0.5) + 1) * a * sin(((point_idx-c) * d * PI) / c) * s # makes the link wobble during travel
		points_arr.push_back(Vector2(point_idx*length_divisor, y_pos))
	if points_arr.size()> 1:
		draw_polyline(points_arr,color_outline, LINE_WIDTH)
		draw_polyline(points_arr,color_inner, LINE_WIDTH-10)

func start():
	rng.randomize()
	var rand_num1 = rng.randf_range(-3, 3)
	var rand_num2 = rng.randf_range(-4, 4)
	var rand_num3 = rng.randf_range(-.1, .1)
	stage = INITIAL_SHOOT
	w = 7 + rand_num1
	a = 18 +rand_num2
	s = .68 + rand_num3

func release():
	stage = RETRACT
	a = 0

func _process(delta):
	if not visible:
		return
	if stage == INITIAL_SHOOT:
		length_divisor = 1
		s = lerp(s, 1, delta*SHOOT_OFFSET_INCREASE)
		a = lerp(a, 1, delta*SHOOT_AMP_DECREASE)
		w = lerp(w, w*16, delta*SHOOT_WID_DECREASE)
		if owner.chain_state == owner.chain_states.HOOKED:
			stage = JUST_HOOKED
			s = .4
	elif stage == JUST_HOOKED:
		s = attachment_curve.interpolate(s)
		a = 40
		length_divisor = lerp(length_divisor,c/100,delta) # 'c' boosts performance by reducing points
	elif stage == RETRACT:
		length_divisor = 1
	update()
