# OpenKCC Godot

## Style Guide

Style guides used for project by language:

* GDScript : [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
* C# : [C# Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_style_guide.html)
* C++ : [Code Style Guides : C++ and Objective-C](https://docs.godotengine.org/en/stable/contributing/development/code_style_guidelines.html#c-and-objective-c)

## Project Setup

Install Godot v4.1.1, then make sure to setup the build tools for the project.
Setup guide for required tools by platform: [Building from Source](https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html)

Using the GDExtensions to develop with C++, see [GDExtension C++ example](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_cpp_example.html)
for details.

```PowerShell
git submodule update --init

cd godot-cpp
godot --dump-extension-api extension_api.json
mv -Force extension_api.json ../extension_api.json

# Setup build platform tools for windows
#   -j16 flag for multi threading, use -jN where N is number of processors available
scons platform=windows custom_api_file=../extension_api.json -j16

# Setup build platform tools for javascript (including WebGL)
#   make sure you have Emscripten 1.39.9 installed and activated
scons platform=javascript custom_api_file=../extension_api.json -j16
```

## Build

Build project export using godot via [cli](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
or via the editor.

### Build Windows Platform

```PowerShell
# Build libraries for openkcc
scons platform=windows
godot --path openkcc --headless --export-debug windows-desktop ../builds/WebGL/OpenKCC

# Release build
scons platform=windows target=template_release
godot --path openkcc --headless --export-release windows-desktop ../builds/Windows/OpenKCC.exe
```

### Build Web Platform

Note, the web export uses the [Export Template](https://docs.godotengine.org/en/stable/tutorials/export/exporting_projects.html#export-templates)
for web v4.1.1 (not the mono version).

```PowerShell
# Build libraries for openkcc
scons platform=javascript
godot --path openkcc --headless --export-debug web ../builds/WebGL/OpenKCC.html

# Release build
scons platform=javascript target=template_release
godot --path openkcc --headless --export-release web ../builds/WebGL/OpenKCC.html
```

Host website for local testing via [npx](https://docs.npmjs.com/cli/v7/commands/npx)

```PowerShell
npx local-web-server `
  --cors.embedder-policy "require-corp" `
  --cors.opener-policy "same-origin" `
  --directory builds/WebGL
```
