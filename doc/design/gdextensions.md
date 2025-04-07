# Using GDExtensions

GDExtensions allows for adding native shared libraries to the godot engine.
(See [What is GDExtension?](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html)
from the godot docs for details).

Native code allows for operations that are not always available in the godot engine
and allow higher performance operations or integrating existing third party
libraries such as [Godot SQLite](https://github.com/2shady4u/godot-sqlite).

Godot also has the ability to modules which also allows for integrating C++ or
C code into the game engine. However, modules require being compiled as part
of the game engine and only support C and C++.

## Use in OpenKCC