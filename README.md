# OpenKCC Godot

This project is a sample of the Open Kinematic Character Controller for the
Godot game engine. A Kinematic Character Controller (KCC) provides a
way to control a character avatar as a kinematic object that will
interact with the environment.

OpenKCC is an open source project hosted at
[https://github.com/nicholas-maltbie/Godot-OpenKCC](https://github.com/nicholas-maltbie/Godot-OpenKCC).

This is an open source project licensed under a [MIT License](./License.txt).
Feel free to use a build of the project for your own work. If you see an
error in the project or have any suggestions, write an issue or make a pull
request, I'll happily include any suggestions or ideas into the project.

You can see a demo of the project running here: [https://openkcc.nickmaltbie.com/](https://openkcc.nickmaltbie.com/).
The project hosted on the website is up to date with the most recent version on
the `main` branch of this github repo and is automatically
deployed with each update to the codebase.

## Project Setup

Install Godot v4.4.stable, then make sure to setup the build tools for the project.
Setup guide for required tools by platform: [Building from Source](https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html)

Using the GDExtensions to develop with C++, see [GDExtension C++ example](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_cpp_example.html)
for details.

_Note_ install godot via [Scoop](https://scoop.sh/) for windows, see
[Command Line Tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html#path)
from Godot's docs for more details.

```PowerShell
# Setup godot-cpp
git submodule update --init

# Setup build platform tools for windows and web environment
scons --directory godot-cpp -j4
scons --directory godot-cpp -j4 target=editor

# Build openkcc libraries for your development platform.
scons -j4
scons target=editor -j4

# Note, I ran into some issues with the build and multi threading and
#  some of the build dependencies attaching a flag such as -j1 at the end
#  seemed to resolve those errors.
```

### Symlink Issue

If you run into an issue with `demo-project\addons\openkcc` not being created as
a symlink, make sure symlinks is enabled. Once setting has been enabled, you
can restore the path by doing a git checkout of the path
`demo-project\addons\openkcc` or a `git reset --hard`,
but this may need to be run as an admin to correctly create the symlinks on windows.

Check via command.

```PowerShell
git config core.symlinks
```

Update via command.

```PowerShell
git config core.symlinks true
```

## Build

Build project export using godot via [cli](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
or via the editor.

### Build Windows Platform

See setup guide [Compiling for Windows](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_windows.html)
with godot.

```PowerShell
# Build libraries for openkcc
scons --directory godot-cpp platform=windows -j4
scons platform=windows target=template_release -j4

# Optional: Download redit tool
$url = "https://github.com/electron/rcedit/releases/download/v1.1.1/rcedit-x64.exe"
$out = "external\rcedit-x64.exe"
mkdir -p external
Invoke-WebRequest -Uri $url -OutFile $out

# Export debug windows-desktop build
godot -v --path demo-project --headless --import
mkdir -p builds/Windows
godot --path demo-project --headless --export-release windows-desktop
```

### Build Web Platform

See setup guide [Compiling for Web](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html)
with godot.

Requires a custom extension built [Compiling for the Web: GDExtension](https://docs.godotengine.org/en/stable/contributing/development/compiling/compiling_for_web.html#gdextension)

> The default export templates do not include GDExtension support for
> performance and compatibility reasons. See the [export page](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html#export-options)
> for more info.
>
> You can build the export templates using the option `dlink_enabled=yes` to
> enable GDExtension support:

```PowerShell
# Build libraries for openkcc
scons --directory godot-cpp platform=web -j4
scons platform=web target=template_release -j4

# Export debug web build
godot -v --path demo-project --headless --import
mkdir -p builds/WebGL
godot --path demo-project --headless --export-release web
cp demo-project/coi-serviceworker.min.js builds/WebGL/coi-serviceworker.min.js
```

Host website for local testing via [python -m http.server](https://docs.python.org/3/library/http.server.html)

```PowerShell
python -m http.server --directory builds/WebGL
```

## Documentation

Documentation for the project is stored in the `doc` directory
and built using [DocFx](https://github.com/dotnet/docfx).

Generate documentation using godot cli tool `--doctool` and `--gdscript-docs`.
Use [gddoc2yml](https://github.com/nicholas-maltbie/gddoc2yml) tool for
generating docfx docs.

```PowerShell
# install gddoc2yml
python -m pip install gddoc2yml

# Install docfx if needed
# Note, you may need to add nuget as a source like so:
#   dotnet nuget add source "https://api.nuget.org/v3/index.json" --name "nuget.org"   
dotnet tool restore

#  Load project in editor at least once
godot -v --path demo-project --headless --import

# Cleanup previous temporary folders
rm -r doc/tmp
rm -r doc/gen

# Build xml based documentation
mkdir -p doc/tmp/godot
godot --path demo-project --doctool ../doc/tmp/godot

# Convert docs to yml for api and examples
gdxml2yml --filter doc/xml/doc_classes doc/xml/scripts OpenKCCCameraController `
    --path doc/xml/doc_classes doc/xml/scripts doc/xml/example doc/tmp/godot `
    --output doc/gen/api
gdxml2yml --filter doc/xml/example `
    --path doc/xml/doc_classes doc/xml/scripts doc/xml/example doc/tmp/godot `
    --output doc/gen/example

# Create site with docfx
dotnet tool run docfx doc/docfx.json --serve
```

### Generate Docs from Source

See [GDExtension documentation system](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_docs_system.html)
from godot docs for details

```PowerShell
#  Load project in editor at least once
godot -v --path demo-project --headless --import

# Build documentation for addon and gdextensions
godot --path demo-project --doctool ../doc/xml/scripts --gdscript-docs res://addons/openkcc/examples --quit
godot --path demo-project --doctool ../doc/xml --gdextension-docs ../ --quit

# Generate some docs for example project
godot --path demo-project --doctool ../doc/xml/example --gdscript-docs res://scripts --quit
```

## Style Guide

Style guides used for project by language:

* GDScript : [GDScript Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
* C# : [C# Style Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_style_guide.html)
* C++ : [Code Style Guides : C++ and Objective-C](https://docs.godotengine.org/en/stable/contributing/development/code_style_guidelines.html#c-and-objective-c)

## Tests

Run tests for project with [GUT](https://github.com/bitwes/Gut)

```PowerShell
# Run tests with Gut
godot -d -s --path demo-project addons/gut/gut_cmdln.gd
```

## Linting

C++ formatting via [clang-format](https://clang.llvm.org/docs/ClangFormat.html).
Can be installed format via pip.

```PowerShell
# Install
python -m pip install clang-format

# Find formatting via clang-format
clang-format src/*.cpp src/*.h --dry-run

# Fix formatting via clang-format
clang-format src/*.cpp src/*.h  -i
```

GDScript linting via [godot-gdscript-toolkit](https://github.com/Scony/godot-gdscript-toolkit)
with the `gdlint` command

```PowerShell
# Install gdlint via pip
python -m pip install gdtoolkit

# Run gdlint on openkcc files
gdlint addons/openkcc demo-project/scripts demo-project/tests
```

_Note: still in progress_ C# linting via [dotnet format](https://github.com/dotnet/format)
can be installed via dotnet in repo.

```PowerShell
# Install via dotnet, uses .config/dotnet-tools.json
# Note, you may need to add nuget as a source like so:
#   dotnet nuget add source "https://api.nuget.org/v3/index.json" --name "nuget.org"    
dotnet tool restore

# Run dotnet-format command via dotnet tool run
dotnet tool run dotnet-format .\demo-project\GodotOpenKCC.sln --check
```

_Note: still in progress_ Markdown linting via [markdownlint](https://github.com/DavidAnson/markdownlint)
can be installed via npm.

```PowerShell
# Install cli version via npm
npm install -g markdownlint-cli

# Run on local repo
markdownlint .
```
