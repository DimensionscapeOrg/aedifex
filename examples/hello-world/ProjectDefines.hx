package;

@:build(aedifex.build.macros.DefineCatalogMacro.compose([
	aedifex.build.Defines
]))
abstract ProjectDefines(String) from String to String {}
