package aedifex.build;

import aedifex.build.Project.ProjectBuilder;

/**
 * Haxe-side extension point for shaping a project while `Aedifex.hx` is
 * being evaluated.
 *
 * Use this when you want to add libraries, defines, targets, tasks, or
 * other typed project behavior from reusable Haxe code.
 */
interface IProjectExtension {
	/**
	 * Applies extension behavior to the current project builder.
	 * @param project Mutable project builder being evaluated from `Aedifex.hx`.
	 * @param options Optional extension-specific configuration object.
	 * @return No return value.
	 */
	public function apply(project:ProjectBuilder, ?options:Dynamic):Void;
}
