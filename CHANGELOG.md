# Changelog

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
