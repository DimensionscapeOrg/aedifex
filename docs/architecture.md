# Architecture

This document describes how Aedifex resolves and executes a project.

## Command Pipeline

For most project commands, Aedifex does this:

1. resolve the invocation root
2. find `Aedifex.hx`
3. extract `ProjectSpec` by running Haxe in interpreter mode
4. resolve target, qualifier, architecture, profile, and setup readiness
5. build a machine-readable plan
6. execute build, run, test, or finalization work

## Main Modules

CLI entrypoint:

- `src/aedifex/cli/Main.hx`

Public build model:

- `src/aedifex/build/`

Planning and resolution:

- `src/aedifex/build/_internal/ExecutionPlanner.hx`
- `src/aedifex/build/_internal/ProjectResolver.hx`
- `src/aedifex/build/_internal/ProjectProviderDiscovery.hx`
- `src/aedifex/build/_internal/ProjectExtractor.hx`
- `src/aedifex/build/_internal/ToolEnvironment.hx`

Build and run:

- `src/aedifex/core/Builder.hx`
- `src/aedifex/core/Runner.hx`
- `src/aedifex/core/ProgramWriter.hx`

Setup readiness:

- `src/aedifex/setup/TargetSetup.hx`
- `src/aedifex/setup/SetupStatus.hx`

Plugins:

- `src/aedifex/plugin/`

## Project Extraction

`Aedifex.hx` is not parsed as JSON or a custom config format.

Aedifex generates a small extraction runner and evaluates the project root through Haxe `--interp`. The runner reads:

- `Aedifex.project`

and serializes the resulting `ProjectSpec`.

## Target Resolution

Public input is target-first:

- `target`
- optional qualifier
- optional architecture
- profile

Examples:

- `cpp` means host desktop cpp
- `js -node` means Node.js
- `js -html5` means browser-style JavaScript
- `cpp -android` means Android-qualified cpp

The planner resolves the concrete backend, host, output layout, and readiness from there.

## Setup Readiness

Before `build`, `run`, or `test`, Aedifex checks whether the selected target environment is ready.

If it is not ready:

- interactive terminals can prompt to run `setup`
- non-interactive flows fail with the exact setup command to run

This makes the same contract usable for:

- local onboarding
- editor integration
- CI

## Machine-Readable Commands

These commands are the stable introspection surface:

- `aedifex explain . -json`
- `aedifex targets . -json`
- `aedifex profiles -json`
- `aedifex tasks . -json`
- `aedifex build-plan ... -json`
- `aedifex launch-plan ... -json`
- `aedifex setup <target> -check -json`

The VS Code extension consumes these outputs directly.

## Tool Root And Project Root

Aedifex keeps two roots:

- invocation root: the user's working directory or explicit project path
- tool root: the active installed Aedifex location

Invocation root is used for:

- loading the local `Aedifex.hx`
- resolving relative project paths
- creating files in the target repo

Tool root is used for:

- embedded templates
- runner resources
- `run.hxml`
- self-rebuild

## Plugins And Extensions

There are two extension surfaces:

- Haxe-side project extensions used in `Aedifex.hx`
- external process plugins loaded by `PluginManager`

See [Extensions](extensions.md).
