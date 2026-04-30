# Extensions

Aedifex has two separate extension surfaces.

## 1. Haxe-Side Project Extensions

Use Haxe-side extensions inside `Aedifex.hx` when you want to shape the resolved project model.

Relevant files:

- `src/aedifex/build/IProjectExtension.hx`
- `src/aedifex/build/IProjectCapabilityProvider.hx`
- `src/aedifex/build/Project.hx`

Example:

```haxe
class MyExtension implements IProjectExtension {
	public function new() {}

	public function apply(project:ProjectBuilder, ?options:Dynamic):Void {
		project.haxelib("my-lib");
		project.supportsTarget(aedifex.build.BuildTarget.PHP);
	}
}
```

Use it from the root:

```haxe
Project
	.named("Main")
	.use(MyExtension)
	.done();
```

Use Haxe-side extensions for:

- project defaults
- extra libraries and defines
- target declarations
- target-specific rules
- framework-style project shaping

## Capability Reporting

If an extension should describe what it adds to the world, implement `IProjectCapabilityProvider`.

That allows the extension to advertise:

- define catalogs
- commands
- targets
- profiles

Those capabilities show up in machine-readable inspection such as `aedifex explain . -json`.

## Define Catalog Metadata

An extension can advertise a define catalog:

```haxe
@:aedifexDefines(my.framework.GraphaxeDefines)
class GraphaxeExtension implements IProjectExtension {
	...
}
```

Projects can then compose their own define enum for completion. See [Defines](defines.md).

## 2. External Process Plugins

Use process plugins when you want host/runtime behavior outside the typed project model.

Relevant files:

- `src/aedifex/plugin/Plugin.hx`
- `src/aedifex/plugin/PluginManager.hx`
- `template/plugin/PluginWire.hx`
- `src/aedifex/core/BuildContext.hx`

Use process plugins for:

- host configuration
- build/run observation
- external integrations
- tooling around the lifecycle

## Plugin Hooks

Current plugin lifecycle hooks include:

- `hook.preBuild`
- `hook.postBuild`
- `hook.preRun`
- `hook.postRun`
- `hook.preFinalize`
- `hook.postFinalize`

Plugins receive a `BuildContext` with fields such as:

- `projectRoot`
- `target`
- `platform`
- `architecture`
- `backend`
- `profile`
- `outDir`
- `binDir`
- `objDir`
- `haxeDir`
- `srcDir`
- `defines`
- `libs`
- `project`

## Which One To Use

Use a Haxe-side project extension when the feature belongs in `Aedifex.hx`.

Use a process plugin when the feature belongs in the host/runtime around command execution.
