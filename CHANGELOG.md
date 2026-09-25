# Changelog

## Unreleased

- cpp debug builds no longer include hxcpp's VS Code debug server unless asked for with `AEDIFEX_HXCPP_DEBUGGER=1`, which the VS Code extension sets on the builds it debugs with hxcpp's debugger. The server was compiled into every cpp debug build while `hxcpp-debug-server` was installed, and finding no debugger it listens on port 6972 for one to attach -- so two debug apps run together hung each other, the second taking the first one's listener for VS Code, and one left running held 6972 against the next debug session. Builds from the command line now leave it out and plan the native debugger; to debug one with hxcpp's debugger anyway, set the variable or add `-lib hxcpp-debug-server`.

## 1.0.0-rc.3

- Switched the core CLI to target-first setup readiness with clearer environment checks.
- Standardized the public CLI around single-dash flags.
- Made the runner-first install and rebuild flow the default release model.
- Simplified target, qualifier, architecture, and profile semantics.
- Improved the VS Code workflow around a single Aedifex launcher/task plus target and profile pickers.
- Added guide documentation, curated Dox API docs, and docs CI artifacts.
- Expanded Haxe API documentation to improve IDE hinting in `Aedifex.hx`.

## 1.0.0-rc.2

- switched the project root model to `Aedifex.hx`
- added destination-first CLI commands and planning output
- added project kinds for apps, libraries, tools, plugins, and extensions
- added typed define catalogs and composed define enum support
- added `haxelib.json` sync from `Aedifex.hx`
- added named tasks for library and tool roots
- added a thin VS Code extension scaffold
