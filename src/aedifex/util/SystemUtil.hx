package aedifex.util;

/**
 * ...
 * @author Christopher Speciale
 */
class SystemUtil {
	public static var platform(get, never):String;

	private static inline function get_platform():String {
		return Sys.systemName().toLowerCase();
	}
}
