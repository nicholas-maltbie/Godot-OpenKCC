extends GutTest

func before_all():
	gut.p("Runs once before all tests")

func before_each():
	gut.p("Runs before each test.")

func after_each():
	gut.p("Runs after each test.")

func after_all():
	gut.p("Runs once after all tests")

func test_create_nickgdexample_free():
	var example = NickGDExample.new();
	example.free()
	assert_no_new_orphans()
