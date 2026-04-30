package aedifex.build;

/**
 * Core Aedifex define and token catalog.
 *
 * This abstract is intentionally small and string-backed so extension
 * catalogs can compose into a single project-local enum surface via macros.
 */
abstract Defines(String) from String to String {
	public static inline final WINDOWS:Defines = "windows";
	public static inline final MAC:Defines = "mac";
	public static inline final LINUX:Defines = "linux";
	public static inline final ANDROID:Defines = "android";
	public static inline final IOS:Defines = "ios";
	public static inline final HTML5:Defines = "html5";
	public static inline final NODE:Defines = "node";
	public static inline final CPP:Defines = "cpp";
	public static inline final HL:Defines = "hl";
	public static inline final NEKO:Defines = "neko";
	public static inline final JVM:Defines = "jvm";
	public static inline final PHP:Defines = "php";
	public static inline final JS:Defines = "js";
	public static inline final X86:Defines = "x86";
	public static inline final X64:Defines = "x64";
	public static inline final ARM64:Defines = "arm64";
	public static inline final ARMV7:Defines = "armv7";
	public static inline final DEBUG:Defines = "debug";
	public static inline final RELEASE:Defines = "release";
	public static inline final FINAL:Defines = "final";

	public static inline function custom(name:String):Defines {
		return cast name;
	}
}
