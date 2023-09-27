# OpenKCC Godot

## Style Guide

Style guides used for project by language:

* GDScript : [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
* C# : [C# Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_style_guide.html)
* C++ : [Code Style Guides : C++ and Objective-C](https://docs.godotengine.org/en/stable/contributing/development/code_style_guidelines.html#c-and-objective-c)

## Project Setup

Install Godot v4.1.1-stable, then make sure to setup the build tools for the project.
Setup guide for required tools by platform: [Building from Source](https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html)

Using the GDExtensions to develop with C++, see [GDExtension C++ example](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_cpp_example.html)
for details.

```PowerShell
# Setup godot-cpp
git -C godot-cpp submodule update --init

# Setup build platform tools for windows and javascript environment
scons --directory godot-cpp

# Build openkcc libraries for your development platform.
scons
scons target=editor
```

## Build

Build project export using godot via [cli](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
or via the editor.

### Build Windows Platform

See setup guide [Compiling for Windows](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_windows.html)
with godot.

```PowerShell
# Build libraries for openkcc
scons --directory godot-cpp platform=windows
scons platform=windows

# Export debug windows-desktop build
godot -v -e --path openkcc --headless --quit
mkdir -p builds/Windows
godot --path openkcc --headless --export-debug windows-desktop
```

### Build Web Platform

See setup guide [Compiling for Web](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html)
with godot.

Requires a custom extension built [Compiling for the Web: GDExtension](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html#gdextension)

> The default export templates do not include GDExtension support for performance and compatibility reasons. See the [export page](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#doc-javascript-export-options) for more info.
> You can build the export templates using the option `dlink_enabled=yes` to enable GDExtension support:

```PowerShell
## Fixes for JavaScript/Web support
git -C godot-cpp apply --ignore-space-change --ignore-whitespace ../patches/fixed_javascript_build.patch

# Build libraries for openkcc
scons --directory godot-cpp platform=javascript
scons platform=javascript

# Export debug web build
godot -v -e --path openkcc --headless --quit
mkdir -p builds/WebGL
godot --path openkcc --headless --export-debug web
cp openkcc/coi-serviceworker.min.js builds/WebGL/coi-serviceworker.min.js
```

Host website for local testing via [python -m http.server](https://docs.python.org/3/library/http.server.html)

```PowerShell
python -m http.server --directory builds/WebGL
```
