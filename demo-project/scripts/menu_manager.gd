extends Node

@export var actions:CanvasItem
@export var quit_button:Button
@export var resume_button:Button

# Is the menu open
var menu_open:bool = false

func _ready() -> void:
	actions.set_visible(false)
	MenuBus.toggle_menu.connect(_toggle_menu)
	resume_button.pressed.connect(_toggle_menu)
	quit_button.pressed.connect(_quit_game)

func _exit_tree():
	MenuBus.toggle_menu.disconnect(_toggle_menu)

func _input(event:InputEvent) -> void:
	if event.is_action_pressed("Exit"):
		# Set mouse to captured mode on input form player
		# This needs to be done in _input for web support
		MenuBus.toggle_menu.emit()

func _toggle_menu() -> void:
	menu_open = !menu_open
	actions.set_visible(menu_open)
	_capture_mouse()

func _quit_game() -> void:
	get_tree().quit(0)

func _capture_mouse() -> void:
	if menu_open:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		MenuBus.menu_opened.emit()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		MenuBus.menu_closed.emit()
