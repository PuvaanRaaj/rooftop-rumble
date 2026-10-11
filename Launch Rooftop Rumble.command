#!/bin/zsh
cd "${0:A:h}"
if [[ -x .tools/Godot.app/Contents/MacOS/Godot ]]; then
  exec .tools/Godot.app/Contents/MacOS/Godot --path "$PWD"
elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then
  exec /Applications/Godot.app/Contents/MacOS/Godot --path "$PWD"
elif command -v godot >/dev/null 2>&1; then
  exec godot --path "$PWD"
else
  print 'Install Godot 4.5 or newer from https://godotengine.org/download/macos/'
  print 'Then import project.godot and press F5, or run this launcher again.'
  read 'answer?Press Enter to close.'
fi
