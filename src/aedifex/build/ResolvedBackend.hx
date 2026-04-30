package aedifex.build;

abstract ResolvedBackend(String) from String to String {
	public static inline final CPP:ResolvedBackend = "cpp";
	public static inline final HL:ResolvedBackend = "hl";
	public static inline final NEKO:ResolvedBackend = "neko";
	public static inline final JVM:ResolvedBackend = "jvm";
	public static inline final PHP:ResolvedBackend = "php";
	public static inline final JS:ResolvedBackend = "js";
	public static inline final HTML5:ResolvedBackend = "html5";
	public static inline final CUSTOM:ResolvedBackend = "custom";
}
