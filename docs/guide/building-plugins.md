# Building Plugins

Aedifex process plugins are separate executables that communicate with the host over a simple wire protocol.

That makes them a good fit for host-side integration work without forcing everything into the typed `Aedifex.hx` model.

## Scaffold A Plugin

```powershell
aedifex create path/to/MyPlugin -plugin
```

That gives you a plugin-oriented project layout plus the wire template under the generated source tree.

## What Plugins Are Good For

Use process plugins for host/runtime behavior such as:

- lifecycle observation
- host-side integrations
- tool coordination
- side-channel automation around build and run

Use Haxe-side project extensions when the feature belongs inside the typed project model instead.

## Current Lifecycle Shape

Current hook-style interactions include:

- pre-build
- post-build
- pre-run
- post-run
- pre-finalize
- post-finalize

Plugins receive a `BuildContext` describing the active target, profile, output paths, project root, and related build state.

## The Wire Template

The generated plugin wire is intentionally simple:

- process boundary
- request/response over stdio
- explicit lifecycle messages

That keeps the plugin surface straightforward and portable.

## Current Boundaries

The plugin layer is deliberately narrower than the Haxe-side extension layer:

- plugins are not the main typed config authoring story
- plugins are host/runtime sidecars
- project shaping still belongs in `Aedifex.hx`

## More

- [Extensions reference](../extensions.md)
- [Building your own CLI tool](building-your-own-cli-tool.md)
