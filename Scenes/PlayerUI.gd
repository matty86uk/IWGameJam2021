extends Control

var blink_delay = 0.5
var last_blink = 0
var blink_time = 0

onready var dot = $CamPanel/Label/Dot

func _process(delta):
	if OS.get_unix_time() > blink_time + blink_delay:
		blink_time = OS.get_unix_time()
		if dot.visible:
			dot.hide()
		else:
			dot.show()
	pass

