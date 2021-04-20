extends Control

signal start_game

var colors = [
	Color.red,
	Color.green,
	Color.blue,
	Color.yellow,
	Color.white,
	Color.pink,
	Color.orange,
	Color.purple
]

var color_index = 0
var color = Color.purple
var color_change_amount = 0

func _ready():
	$Button.connect("pressed", self, "_button_pressed")
	

func _button_pressed():
	emit_signal("start_game")

func _process(delta):	
	
	var target_color = colors[color_index]
	
	var red_diff = color.r - target_color.r
	var blue_diff = color.b - target_color.b
	var green_diff = color.g - target_color.g
	
	var new_color = color.linear_interpolate(target_color, color_change_amount)
	
	$GameTitle.add_color_override("font_color", new_color)
	
	color = new_color
	
	color_change_amount += delta * 0.01
	
	if new_color.is_equal_approx(target_color) :
		color_change_amount = 0
		color_index += 1
		if color_index >= colors.size():
			color_index = 0
	
	
	
	
