package aedifex.build;

import aedifex.build.ProjectSpec.ExtensionCapabilities;

interface IProjectCapabilityProvider {
	public function describeCapabilities():ExtensionCapabilities;
}
