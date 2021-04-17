extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var fruits = []
var started = false

func init(fruits, fruit_data):
	self.fruits = fruits
	pass

func _process(delta):	
	if started:
		if fruits.size() > 0:
			var next_fruit = fruits.pop_front()
			
		pass	
	
