package aedifex.theme;

import haxe.ds.StringMap;

class Themes {
	public static var cyber:String = '{"name":"cyber","kind":"sweep","sweep":{"s":{"r":180,"g":0,"b":255},"e":{"r":0,"g":255,"b":220}}}';
	public static var defaultTheme:String = '{"name":"defaultTheme","kind":"flat","head":{"r":255,"g":0,"b":0},"sub":{"r":255,"g":255,"b":255},"meta":{"r":200,"g":200,"b":200}}';
	public static var aurora:String = '{"name":"aurora","kind":"multi","stops":[{"pos":0.0,"r":20,"g":40,"b":120},{"pos":0.3,"r":0,"g":255,"b":160},{"pos":0.6,"r":100,"g":120,"b":255},{"pos":1.0,"r":0,"g":220,"b":180}]}';

	public static final themeRegistry:StringMap<String> = _populateRegistry();

	private static inline function _populateRegistry():StringMap<String> {
		var sMap:StringMap<String> = new StringMap();
		for (field in Type.getClassFields(Themes)) {
			if (field != "themeRegistry" && field != "_populateRegistry") {
				sMap.set(field, Reflect.field(Themes, field));
			}
		}
		return sMap;
	}
}
