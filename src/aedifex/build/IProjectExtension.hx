package aedifex.build;

import aedifex.build.Project.ProjectBuilder;

interface IProjectExtension {
	public function apply(project:ProjectBuilder, ?options:Dynamic):Void;
}
