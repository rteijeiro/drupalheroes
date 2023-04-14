extends Node2D

@onready var Globals = get_node("/root/Global") # Global variables.
@onready var PlayerName = $CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/Name
@onready var PlayerTime = $CanvasLayer/MarginContainer/VBoxContainer/Time
@onready var Submit = $CanvasLayer/MarginContainer/VBoxContainer/HBoxContainer/Submit
@onready var Thanks = $CanvasLayer/MarginContainer/VBoxContainer/Thanks
@onready var Menu = $CanvasLayer/MarginContainer/VBoxContainer/Menu


##
# Sets focus on PlayerName textbox and updates PlayerTime label.
##
func _ready():
	PlayerName.grab_focus()
	PlayerTime.text = var_to_str(Globals.time)


##
# Sends a POST request with the player time and name.
##
func _submit_score():
	# Creates an HTTP request node and connect its completion signal.
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(self._push_score_http_request_completed)
	
	# Sets the HTTP request headers.
	var headers = [
		'Accept: application/vnd.api+json',
		'Content-Type: application/vnd.api+json',
		'Authorization: Basic dXNlcjpwYXNz'
	]
	
	# POST request data including player name and time.
	var score_data = {
		"data": {
			"type": "node--score",
			"attributes": {
				"title": PlayerName.text,
				"field_time": {
					"value": PlayerTime.text
				}
			}
		}
	}

	# Performs the HTTP request to retrieve all Heroes including avatar field.
	var error = http_request.request("http://godot.ddev.site/jsonapi/node/score", headers, HTTPClient.METHOD_POST, JSON.stringify(score_data))
	
	# Catches request error.
	if error != OK:
		push_error("An error occurred in the HTTP request from get_heroes() method.")


##
# Called when the HTTP POST request is completed.
##
func _push_score_http_request_completed(result, response_code, _headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("Score POST HTTPRequest error response code : " + var_to_str(response_code))
		_display_message(PlayerName.text)
	else:
		# Gets POST request response in JSON format.
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var response = json.get_data()
		
		# Sets the congrats message using player name.
		var message = response["data"]["attributes"]["title"]
		_display_message(message)


##
# Submits score.
##
func _on_submit_pressed():
	_submit_score()


##
# Restarts the game.
##
func _on_restart_pressed():
	get_tree().change_scene_to_file("res://start.tscn")


##
# Hides submit elements and displays congrats message and restart button.
##
func _display_message(player_name: String):
	Thanks.text = "Congrats " + player_name + "!"
	PlayerName.hide()
	Submit.hide()
	Thanks.show()
	Menu.show()
