# Exercise-03c-Music-and-Sound

Exercise for MSCH-C220

A demonstration of this exercise is available at [https://youtu.be/gfhskDcihjg](https://youtu.be/gfhskDcihjg).

This exercise is the third installment as you to experiment with juicy features to our brick-breaker game. The exercise will provide you with the next several features that should move you towards the implementation of Project 03, including adding music and sound effects.

Fork this repository. When that process has completed, make sure that the top of the repository reads [your username]/Exercise-03c-Music-and-Sound. Edit the LICENSE and replace BL-MSCH-C220-F22 with your full name. Commit your changes.

Press the green "Code" button and select "Open in GitHub Desktop". Allow the browser to open (or install) GitHub Desktop. Once GitHub Desktop has loaded, you should see a window labeled "Clone a Repository" asking you for a Local Path on your computer where the project should be copied. Choose a location; make sure the Local Path ends with "Exercise-03c-Music-and-Sound" and then press the "Clone" button. GitHub Desktop will now download a copy of the repository to the location you indicated.

Open Godot. In the Project Manager, tap the "Import" button. Tap "Browse" and navigate to the repository folder. Select the project.godot file and tap "Open".

If you run the project, you will see a main menu followed by a simple brick-breaker game. We will now have an opportunity to start making it "juicier".

---

## Recording Music and Sounds

The first part of the assignment is to record four (short) sound effect in Audacity. Save them as wall.wav, paddle.wav, brick.wav, and die.wav (for when the ball hits the wall, paddle, and brick, and when the ball falls off the screen), and copy them into the Assets folder for the project.

You will then need to write a simple melody in MuseScore. It doesn't have to be pretty or elaborate. Export the music as an mp3 file (music.mp3) and copy it into the Assets folder for the project.

Back in Godot, add four AudioStreamPlayer nodes to Game. Name them Music, Wall_Sound, Brick_Sound, Paddle_Sound, and Die_Sound.

Add res://Assets/music.mp3 as the Stream for the Music node. In the Import tab, make sure it is set to loop (reimport if that is not the case). In the Inspector, set Autoplay=On

This is how you will play the sound when the ball hit the wall. In `res://Wall/Wall.gd`, add the following to the end of the `hit()` method:
```
func hit(_ball):
	$ColorRect.color = Color8(201,42,42)
	var wall_sound = get_node_or_null("/root/Game/Wall_Sound")
	if wall_sound != null:
		wall_sound.play()
```

You will, likewise, need to trigger the audio in `res://Brick/Brick.gd` and `res://Paddle/Paddle.gd`. In `res://Ball/Ball.gd`, the die function should appear as follows:
```
func die():
	var die_sound = get_node_or_null("/root/Game/Die_Sound")
	if die_sound != null:
		die_sound.play()
	queue_free()
```

## Bricks

If any of the bricks are hit, we want the remaining bricks to cycle through the colors, fanning out from the point of impact. That will require us to track a few things in Global.gd. I have already added a few variables, but this will need to be the new content of `_physics_process`:
```
func _physics_process(_delta):
	if color_rotate >= 0:
		color_rotate -= color_rotate_index
		color_rotate_index *= 1.05
	else:
		color_rotate_index = 0.1
	sway_index += sway_period
```

We are going to rotate the colors in the bricks and make them sway with the music.

Instead of defining the colors for the $ColorRect one at a time, we are going to define them as elements of a list. In the initial variables (after line 19), add the following:
```
var colors = [
	Color8(224,49,49)
	,Color8(255,146,43)
	,Color8(255,212,59)
	,Color8(148,216,45)
	,Color8(34,139,230)
	,Color8(132,94,247)
	,Color8(190,75,219)
	,Color8(134,142,150)
]
```

Then, the `_ready()` callback will now look like this:
```
func _ready():
	randomize()
	position.x = new_position.x
	position.y = -100
	$Tween.interpolate_property(self, "position", position, new_position, time_appear + randf()*2, Tween.TRANS_BOUNCE, Tween.EASE_IN_OUT)
	$Tween.start()
	if score >= 100: color_index = 0
	elif score >= 90: color_index = 1
	elif score >= 80: color_index = 2
	elif score >= 70: color_index = 3 
	elif score >= 60: color_index=  4
	elif score >= 50: color_index = 5
	elif score >= 40: color_index = 6
	else: color_index = 7
	$ColorRect.color = colors[color_index]
	sway_initial_position = $ColorRect.rect_position
	sway_randomizer = Vector2(randf()*6-3.0, randf()*6-3.0)
```

Then, replace the `pass` statement on line 48 with the following:
```
		color_distance = Global.color_position.distance_to(global_position)  / 100
		if Global.color_rotate >= 0:
			$ColorRect.color = colors[(int(floor(color_distance + Global.color_rotate))) % len(colors)]
			color_completed = false
		elif not color_completed:
			$ColorRect.color = colors[color_index]
			color_completed = true
		var pos_x = (sin(Global.sway_index)*(sway_amplitude + sway_randomizer.x))
		var pos_y = (cos(Global.sway_index)*(sway_amplitude + sway_randomizer.y))
		$ColorRect.rect_position = Vector2(sway_initial_position.x + pos_x, sway_initial_position.y + pos_y)

```

Finally, if a brick is hit, we need to set the Global color_rotate and color_position variables. In `res://Brick/Brick.gd`:
```
func hit(_ball):
	Global.color_rotate = Global.color_rotate_amount
	Global.color_position = _ball.global_position
	die()
```

## Comet Trail

To create a comet trail effect, we simply have to make copies of the ball's sprite and then change their size (and color and transparency) over time. In `res://Game.tscn`, create a new Node2D and name it Comet_Container. Move it up in the Scene panel so it is the top child under Game.

In `res://Ball/Ball.tscn`, add the following to the new `comet()` function:
```
func comet():
	h_rotate = wrapf(h_rotate+0.01, 0, 1)
	var comet_container = get_node_or_null("/root/Game/Comet_Container")
	if comet_container != null:
		var sprite = $Images/Sprite.duplicate()
		sprite.global_position = global_position
		sprite.modulate.s = 0.6
		sprite.modulate.h = h_rotate
		comet_container.add_child(sprite)
```

Then attach a new script (`res://Ball/Comet_Container.gd`) to the Comet_Container node. That script should be as follows:
```
extends Node2D


func _physics_process(_delta):
	for c in get_children():
		if c.modulate.a <= 0 or c.modulate.v <= 0:
			c.queue_free()
		c.scale *= 0.99
		c.modulate.a -= 0.03
		c.modulate.v -= 0.01
		c.modulate.h += 0.02
```

## The Main Menu

In `res://UI/Main_Menu.tscn` add a new AudioStreamPlayer node and name it Ball_Sound. Drag `res://Assets/wall.wav` to the Stream field in the Inspector.

Edit `res://UI/Boundary.gd` and add the following to the `hit(ball)` function:
```
func hit(ball):
	ball.max_speed *= 1.05
	ball.min_speed *= 1.05
	ball.max_speed = clamp(ball.max_speed, ball.max_speed, 1500)
	ball.min_speed = clamp(ball.min_speed, ball.min_speed, ball.max_speed)
	var ball_sound = get_node_or_null("/root/Main_Menu/Ball_Sound")
	if ball_sound != null:
		ball_sound.play()
```

Then, right-click on the Main_Menu node and Instance Child Scene. Add a second `res://Ball/Ball.tscn`, position it at (760,560) and set its Linear Velocity to (-100,-500).

---

Test the game and make sure it is working correctly. You should be able to see the new effects and hear the music and sound effects as you play.

Quit Godot. In GitHub desktop, you should now see the updated files listed in the left panel. In the bottom of that panel, type a Summary message (something like "Completes the exercise") and press the "Commit to master" button. On the right side of the top, black panel, you should see a button labeled "Push origin". Press that now.

If you return to and refresh your GitHub repository page, you should now see your updated files with the time when they were changed.

Now edit the README.md file. When you have finished editing, commit your changes, and then turn in the URL of the main repository page (https://github.com/[username]/Exercise-03c-Music-and-Sound) on Canvas.

The final state of the file should be as follows (replacing my information with yours):
```
# Exercise-03c-Music-and-Sound

Exercise for MSCH-C220

The third installment, adding music, sound effects, and a few more "juicy" features to a simple brick-breaker game.

## To play

Move the paddle using the mouse. Help the ball break all the bricks before you run out of time.


## Implementation

Built using Godot 3.5

Music recorded in MuseScore 3.6

Sound effects recorded in Audacity 3.2

## References
 * [Juice it or lose it — a talk by Martin Jonasson & Petri Purho](https://www.youtube.com/watch?v=Fy0aCDmgnxg)
 * [Puzzle Pack 2, provided by kenney.nl](https://kenney.nl/assets/puzzle-pack-2)
 * [Open Color open source color scheme](https://yeun.github.io/open-color/)
 * [League Gothic Typeface](https://www.theleagueofmoveabletype.com/league-gothic)
 * [Orbitron Typeface](https://www.theleagueofmoveabletype.com/orbitron)
 
 ## Future Development

Adding a face, Shaders, Powerups, etc.

## Created by 

Jason Francis
```
