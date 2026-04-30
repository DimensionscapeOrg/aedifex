package aedifex.build;

/**
 * Core Aedifex define and token catalog.
 *
 * This abstract is intentionally small and string-backed so extension
 * catalogs can compose into a single project-local enum surface via macros.
 */
abstract Defines(String) from String to String {
	/** Host Windows desktop token. */
	public static inline final WINDOWS:Defines = "windows";
	/** Host macOS desktop token. */
	public static inline final MAC:Defines = "mac";
	/** Host Linux desktop token. */
	public static inline final LINUX:Defines = "linux";
	/** Android qualifier token. */
	public static inline final ANDROID:Defines = "android";
	/** iOS qualifier token. */
	public static inline final IOS:Defines = "ios";
	/** Browser/HTML5 qualifier token. */
	public static inline final HTML5:Defines = "html5";
	/** Node.js qualifier token. */
	public static inline final NODE:Defines = "node";
	/** Cpp/native target token. */
	public static inline final CPP:Defines = "cpp";
	/** HashLink target token. */
	public static inline final HL:Defines = "hl";
	/** Neko target token. */
	public static inline final NEKO:Defines = "neko";
	/** JVM target token. */
	public static inline final JVM:Defines = "jvm";
	/** PHP target token. */
	public static inline final PHP:Defines = "php";
	/** JavaScript target token. */
	public static inline final JS:Defines = "js";
	/** 32-bit x86 architecture token. */
	public static inline final X86:Defines = "x86";
	/** 64-bit x86 architecture token. */
	public static inline final X64:Defines = "x64";
	/** 64-bit ARM architecture token. */
	public static inline final ARM64:Defines = "arm64";
	/** 32-bit ARM v7 architecture token. */
	public static inline final ARMV7:Defines = "armv7";
	/** Debug profile token. */
	public static inline final DEBUG:Defines = "debug";
	/** Release profile token. */
	public static inline final RELEASE:Defines = "release";
	/** Final profile token. */
	public static inline final FINAL:Defines = "final";

	/** Creates a custom string-backed token for project- or framework-specific conditions. */
	public static inline function custom(name:String):Defines {
		return cast name;
	}
}
