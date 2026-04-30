package aedifex.build;

import aedifex.build.ProjectSpec.ExtensionCapabilities;

/**
 * Optional companion interface for `IProjectExtension`.
 *
 * Implement this when an extension should advertise its public capabilities
 * to tooling such as `aedifex explain . -json`.
 */
interface IProjectCapabilityProvider {
	/**
	 * Returns a description of commands, targets, profiles, and define catalogs exposed by the extension.
	 * @return Capability metadata used by tooling and inspection commands.
	 */
	public function describeCapabilities():ExtensionCapabilities;
}
