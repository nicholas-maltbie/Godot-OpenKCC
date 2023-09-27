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
# Setup godot-cpp
git -C godot-cpp submodule update --init
git -C godot-cpp apply --ignore-space-change --ignore-whitespace ../patches/always_build_fix.patch
git -C godot-cpp apply --ignore-space-change --ignore-whitespace ../patches/1165.patch

# Optional
## Build only the necessary classes
git -C godot-cpp apply --ignore-space-change --ignore-whitespace ../patches/godot_cpp_exclude_unused_classes.patch
## Faster build
git -C godot-cpp apply --ignore-space-change --ignore-whitespace ../patches/unity_build.patch
## Fixes for JavaScript/Web support
git -C godot-cpp apply --ignore-space-change --ignore-whitespace ../patches/fixed_javascript_build.patch

# Setup build platform tools for windows and javascript environment
scons --directory godot-cpp
scons --directory godot-cpp platform=javascript

# Build openkcc libraries for your development platform.
scons
scons platform=javascript
```

## Build

Build project export using godot via [cli](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
or via the editor.

### Build Windows Platform

See setup guide [Compiling for Windows](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_windows.html)
with godot.

```PowerShell
# Build libraries for openkcc
scons platform=windows

# Export debug windows-desktop build
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
# Build libraries for openkcc
scons platform=javascript

# Export debug web build
mkdir -p builds/WebGL
godot --path openkcc --headless --export-debug web
```

Host website for local testing via [npx](https://docs.npmjs.com/cli/v7/commands/npx)

```PowerShell
npx local-web-server `
  --cors.embedder-policy "require-corp" `
  --cors.opener-policy "same-origin" `
  --directory builds/WebGL
```
