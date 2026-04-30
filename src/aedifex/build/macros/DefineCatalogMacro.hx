package aedifex.build.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class DefineCatalogMacro {
	private static inline final DEFINES_METADATA = ":aedifexDefines";
	private static inline final DEFINES_METADATA_FALLBACK = "aedifexDefines";

	public static macro function compose(catalogs:Expr):Array<Field> {
		return buildFromCatalogPaths(resolveCatalogPaths(parseArrayExpr(catalogs)));
	}

	public static macro function fromExtensions(extensions:Expr):Array<Field> {
		var catalogPaths:Array<String> = ["aedifex.build.Defines"];

		for (extensionExpr in parseArrayExpr(extensions)) {
			var extensionPath = exprToPath(extensionExpr);
			for (catalogPath in discoverCatalogsForExtension(extensionPath)) {
				if (catalogPaths.indexOf(catalogPath) == -1) {
					catalogPaths.push(catalogPath);
				}
			}
		}

		return buildFromCatalogPaths(catalogPaths);
	}

	private static function buildFromCatalogPaths(catalogPaths:Array<String>):Array<Field> {
		var fields = Context.getBuildFields();
		var seenNames:Map<String, Bool> = new Map();
		for (field in fields) {
			seenNames.set(field.name, true);
		}

		for (catalogPath in catalogPaths) {
			for (fieldName in collectStaticValueFields(catalogPath)) {
				if (seenNames.exists(fieldName)) continue;
				fields.push(aliasField(fieldName, catalogPath));
				seenNames.set(fieldName, true);
			}
		}

		if (!seenNames.exists("custom")) {
			fields.push(customField());
		}

		return fields;
	}

	private static function resolveCatalogPaths(catalogs:Array<Expr>):Array<String> {
		var results:Array<String> = [];
		for (catalogExpr in catalogs) {
			var path = exprToPath(catalogExpr);
			if (results.indexOf(path) == -1) {
				results.push(path);
			}
		}
		return results;
	}

	private static function parseArrayExpr(expr:Expr):Array<Expr> {
		return switch (expr.expr) {
			case EArrayDecl(values):
				values;
			default:
				Context.error("Expected an array of type paths.", expr.pos);
		}
	}

	private static function discoverCatalogsForExtension(extensionPath:String):Array<String> {
		var type = Context.getType(extensionPath);
		return switch (type) {
			case TInst(classRef, _):
				extractCatalogsFromMetadata(classRef.get().meta.get(), extensionPath);
			case TType(typeRef, _):
				switch (typeRef.get().type) {
					case TInst(classRef, _):
						extractCatalogsFromMetadata(classRef.get().meta.get(), extensionPath);
					default:
						Context.error("`" + extensionPath + "` is not a class-based project extension.", Context.currentPos());
				}
			default:
				Context.error("`" + extensionPath + "` is not a class-based project extension.", Context.currentPos());
		}
	}

	private static function extractCatalogsFromMetadata(entries:Metadata, extensionPath:String):Array<String> {
		var results:Array<String> = [];
		for (entry in entries) {
			if (entry.name != DEFINES_METADATA && entry.name != DEFINES_METADATA_FALLBACK) continue;
			for (param in entry.params) {
				var path = exprToPath(param);
				if (results.indexOf(path) == -1) {
					results.push(path);
				}
			}
		}

		if (results.length == 0) {
			Context.error("`" + extensionPath + "` does not advertise any define catalogs. Add @:aedifexDefines(path.to.Catalog).", Context.currentPos());
		}

		return results;
	}

	private static function collectStaticValueFields(typePath:String):Array<String> {
		var names:Array<String> = [];
		for (field in getStaticFields(typePath)) {
			if (!field.isPublic) continue;
			if (field.name == null || field.name.length == 0) continue;
			if (field.name == "new" || field.name == "custom") continue;
			switch (field.kind) {
				case FVar(_, _):
					if (names.indexOf(field.name) == -1) {
						names.push(field.name);
					}
				default:
			}
		}
		return names;
	}

	private static function getStaticFields(typePath:String):Array<ClassField> {
		var type = Context.getType(typePath);
		return switch (type) {
			case TAbstract(abstractRef, _):
				var abstractType = abstractRef.get();
				if (abstractType.impl == null) {
					Context.error("`" + typePath + "` does not expose static fields for composition.", Context.currentPos());
				}
				abstractType.impl.get().statics.get();
			case TInst(classRef, _):
				classRef.get().statics.get();
			default:
				Context.error("`" + typePath + "` is not a supported define catalog type.", Context.currentPos());
		}
	}

	private static function aliasField(fieldName:String, catalogPath:String):Field {
		var sourcePath = catalogPath.split(".");
		sourcePath.push(fieldName);
		return {
			name: fieldName,
			access: [APublic, AStatic, AInline],
			kind: FVar(null, macro cast $p{sourcePath}),
			pos: Context.currentPos()
		};
	}

	private static function customField():Field {
		return {
			name: "custom",
			access: [APublic, AStatic, AInline],
			kind: FFun({
				args: [{name: "name", type: macro : String}],
				expr: macro return cast name
			}),
			pos: Context.currentPos()
		};
	}

	private static function exprToPath(expr:Expr):String {
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name;
			case EField(target, field):
				exprToPath(target) + "." + field;
			default:
				Context.error("Expected a type path.", expr.pos);
		}
	}
}
