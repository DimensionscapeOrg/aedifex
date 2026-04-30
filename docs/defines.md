# Defines

Aedifex defines are authored in Haxe so they can be typed, documented, and extended.

## How It Works

`Aedifex.hx` is evaluated through Haxe `--interp`, so project config can use normal Haxe code and still produce a `ProjectSpec`.

Relevant files:

- `src/aedifex/build/Define.hx`
- `src/aedifex/build/Defines.hx`
- `src/aedifex/build/BuildCondition.hx`
- `src/aedifex/build/Project.hx`
- `src/aedifex/build/macros/DefineCatalogMacro.hx`

## Core Types

- `Define` is the value object used in the build model
- `Defines` is the built-in string-backed token catalog
- `BuildCondition` accepts the same token style for conditional rules

Built-in examples:

- `Defines.CPP`
- `Defines.JS`
- `Defines.NODE`
- `Defines.JVM`
- `Defines.DEBUG`
- `Defines.X64`

## Direct Usage

```haxe
import aedifex.build.Define;
import aedifex.build.Defines;
import aedifex.build.Project;
import aedifex.build.ProjectSpec;

class Aedifex {
	public static final project:ProjectSpec = Project
		.named("Main")
		.define(Define.token(Defines.DEBUG))
		.defineToken(Defines.NODE)
		.done();
}
```

Conditional use:

```haxe
BuildCondition.unless(Defines.HTML5)
```

## Composed Define Enums

Projects can expose one local define enum for completion by composing multiple catalogs.

Example:

```haxe
import aedifex.build.Defines;

@:build(aedifex.build.macros.DefineCatalogMacro.compose([
	Defines,
	my.framework.GraphaxeDefines,
	my.framework.CrossbyteDefines
]))
abstract AppDefines(String) from String to String {}
```

Use it:

```haxe
Project
	.named("Main")
	.defineToken(AppDefines.TELEMETRY)
	.done();
```

## Extension-Driven Composition

An extension can advertise a define catalog:

```haxe
@:aedifexDefines(my.framework.GraphaxeDefines)
class GraphaxeExtension implements IProjectExtension {
	public function new() {}

	public function apply(project:ProjectBuilder, ?options:Dynamic):Void {
		project.defineToken("graphaxe");
	}
}
```

Then a project can compose from extension classes:

```haxe
@:build(aedifex.build.macros.DefineCatalogMacro.fromExtensions([
	my.framework.GraphaxeExtension,
	my.framework.CrossbyteExtension
]))
abstract AppDefines(String) from String to String {}
```

`fromExtensions(...)` automatically includes the core `Defines` catalog.

## Runtime Reporting

Compile-time composition handles code completion.

Runtime capability reporting is separate. If an extension implements `IProjectCapabilityProvider`, its define catalogs can also appear in:

- `aedifex explain . -json`

That is useful for editor tooling and inspection commands.
