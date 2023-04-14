extends Node2D

# Dictionary to store all Heroes data in the following format:
# heroes[hero_id] = { name, avatar }
var heroes = {}
var game_started = false

@onready var Globals = get_node("/root/Global") # Global variables.
@onready var Hero = preload("res://hero.tscn") # Preloads Hero scene for instantiation.
@onready var TimeCount = $HUD/MarginContainer/HBoxContainer/TimeCount # Time counter label.
@onready var HeroesCount = $HUD/MarginContainer/HBoxContainer/HeroesCount # Heroes counter label.


##
# Retrieves all heroes to initiate the game.
##
func _ready():
	_start_game()


##
# Updates the time and the heroes counters' labels.
##
func _process(delta):
	Globals.time += delta
	TimeCount.text = "Time: " + var_to_str(Globals.time)
	HeroesCount.text = "Heroes: " + var_to_str(Globals.heroes_count)

	if Globals.heroes_count == 0 and game_started:
		$Music.stop()
		get_tree().change_scene_to_file("res://score.tscn")


##
# Prepares the game to get it started.
##
func _start_game():
	Globals.time = 0
	Globals.heroes_count = 0
	$Music.play()
	get_heroes()


##
# Performs a GET request to a JSON:API endpoint in Drupal including the avatar field:
# http://godot.ddev.site/jsonapi/node/hero?include=field_avatar
##
func get_heroes():
	# Creates an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._get_heroes_http_request_completed)
	
	# Sets the HTTP request headers.
	var header = ['Accept: application/vnd.api+json']

	# Performs the HTTP request to retrieve all Heroes including avatar field.
	var error = http_request.request("http://godot.ddev.site/jsonapi/node/hero?include=field_avatar", header, HTTPClient.METHOD_GET)
	
	# Catches request error.
	if error != OK:
		push_error("An error occurred in the HTTP request from get_heroes() method.")


##
# Called when the Get Heroes HTTP request is completed.
# Processes the JSON response and creates a hero object including the hero name and avatar.
# At the end calls get_avatars() function to fetch all hero avatar files.
##
func _get_heroes_http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Get Heroes HTTPRequest error response code : " + var_to_str(response_code))
		_load_demo_game()
	else:
		# Gets response data in JSON format.
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		
		# Gets all avatar image URLs from included data in response.
		var avatars = {}
		for avatar in response["included"]:
			avatars[avatar["id"]] = avatar["attributes"]["uri"]["url"]


		# Gets all heroes data from response.
		for hero in response["data"]:
			var file_id = hero["relationships"]["field_avatar"]["data"]["id"]
			var filename = "http://godot.ddev.site" + avatars[file_id]
			heroes[hero["id"]] = {
				"name": hero["attributes"]["title"],
				"url": filename
			}

		await get_avatars()


##
# Retrieves all hero avatars performing a GET request and sending the hero name and avatar image
# to the _create_hero() function to create the hero node and add it to the game.
##
func get_avatars():
	# Creates an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._get_avatars_http_request_completed)
	
	# Sets the HTTP request headers.
	var header = []

	for hero in heroes:
		
		# Performs the HTTP request to retrieve all Heroes including avatar field.
		var error = http_request.request(heroes[hero]["url"], header, HTTPClient.METHOD_GET)

		# Catches request error.
		if error != OK:
			push_error("An error occurred in the HTTP request from get_heroes() method.")
			
		var avatar = await http_request.request_completed

		_create_hero(heroes[hero]["name"], avatar[3])
		_create_hero(heroes[hero]["name"], avatar[3])


##
# Called when the Get Avatars HTTP request is completed.
##
func _get_avatars_http_request_completed(result, response_code, _headers, _body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Get Avatars HTTPRequest error response code : " + var_to_str(response_code))
	else:
		if Globals.heroes_count > 0:
			game_started = true


##
# Creates image texture from avatar image data and adds it to a hero node.
# The hero node type is set using the hero name and added to the game in a random position.
##
func _create_hero(hero_name, hero_avatar):
	Global.heroes_count += 1
		
	var image = Image.new()
	var image_error = image.load_png_from_buffer(hero_avatar)
	if image_error != OK:
		push_error("Couldn't load the image.")

	var texture = ImageTexture.create_from_image(image)

	var hero = Hero.instantiate()
	
	hero.type = hero_name
	hero.get_node("Avatar").set_texture(texture)
	hero.position = Vector2(randi_range(100, 2500), randi_range(100, 1300))
	add_child(hero)


##
# Creates a game with sample nodes.
##
func _load_demo_game():
	
	# Loads 10 sample nodes.
	for i in range(10):
		Global.heroes_count += 1

		var hero = Hero.instantiate()
		
		hero.type = "Empty"
		hero.position = Vector2(randi_range(100, 2500), randi_range(100, 1300))
		add_child(hero)

	game_started = true
