# Aedifex for VS Code

This extension is the official Visual Studio Code companion for Aedifex.

Current features:
- auto-activates when a workspace contains `Aedifex.hx`
- status bar choosers for target and profile
- `Aedifex: Build`, `Aedifex: Run`, and `Aedifex: Debug` commands
- single `Aedifex` debug configuration backed by `launch-plan`
- recognizes library/framework roots and avoids inventing a fake default runnable target
- reads workspace plugin manifests from `.aedifex/plugins/*.json` so installed Aedifex plugins can contribute custom target pickers without shipping their own VS Code extension

CLI resolution order:
- configured `aedifex.cliPath`
- local `neko run.n` when the workspace is the Aedifex tool checkout
- installed `aedifex` command
- `haxelib run aedifex`
