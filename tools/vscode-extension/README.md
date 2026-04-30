# Aedifex VS Code Extension

This extension is a thin client over the Aedifex CLI.

Current features:
- auto-activates when a workspace contains `Aedifex.hx`
- status bar choosers for target and profile
- `Aedifex: Build`, `Aedifex: Run`, and `Aedifex: Debug` commands
- single `Aedifex` debug configuration backed by `launch-plan`
- recognizes library/framework roots and avoids inventing a fake default runnable target

CLI resolution order:
- configured `aedifex.cliPath`
- local `neko run.n` when the workspace is the Aedifex tool checkout
- installed `aedifex` command
- `haxelib run aedifex`
