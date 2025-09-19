package aedifex.util;

import haxe.Resource;
import aedifex.theme.Theme;
import aedifex.theme.Themes;

class Intro {
	public static function show(version:String, ?theme:String = "defaultTheme"):Void {
		var bannerRes = Resource.getString("AedifexBanner");
		var banner = (bannerRes != null) ? bannerRes : defaultBanner();

		var theme:Theme = Theme.resolveTheme(theme);
		theme.renderBanner(banner, version);
	}

	private static inline function defaultBanner():String {
		return "
.................................................................		
||'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''||		
||   .d8b.  d88888b d8888b. d888888b d88888b d88888b db    db  ||
||  d8' `8b 88'     88  `8D   `88'   88'     88'     `8b  d8'  ||
||  88ooo88 88ooooo 88   88    88    88ooo   88ooooo  `8bd8'   ||
||  88~~~88 88~~~~~ 88   88    88    88~~~   88~~~~~  .dPYb.   ||
||  88   88 88.     88  .8D   .88.   88      88.     .8P  Y8.  ||
||  YP   YP Y88888P Y8888D' Y888888P YP      Y88888P YP    YP  ||
||                  -- Build System Daemon --            v" + Aedifex.version + "||
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: 			   
";
	}
}