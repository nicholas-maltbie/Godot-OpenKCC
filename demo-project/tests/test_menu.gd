extends GutTest

const MenuManager = preload("res://scripts/menu_manager.gd")
const menu_scene = preload("res://scenes/menu.tscn")

var _menu:MenuManager
var _sender

func before_all():
	pass

func before_each():
	_menu = menu_scene.instantiate()
	_sender = InputSender.new(_menu)
	add_child_autofree(_menu)

func after_each():
	_sender.release_all()
	_sender.clear()

func after_all():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func test_menu_toggle():
	# Assert that menu starts off closed
	assert_false(_menu.actions.visible)
	assert_false(_menu.menu_open)

	# Toggle manually via input bus
	MenuBus.toggle_menu.emit()
	assert_true(_menu.actions.visible)
	assert_true(_menu.menu_open)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_VISIBLE)
	MenuBus.toggle_menu.emit()
	assert_false(_menu.actions.visible)
	assert_false(_menu.menu_open)
	assert_eq(Input.get_mouse_mode(), Input.MOUSE_MODE_CAPTURED)

func test_menu_on_input():
	# Assert that menu starts off closed
	assert_false(_menu.menu_open)

	# Toggle menu via input
	_sender.action_down("Exit")
	_sender.action_up("Exit")
	assert_true(_menu.menu_open)
	_sender.action_down("Exit")
	_sender.action_up("Exit")
	assert_false(_menu.menu_open)
