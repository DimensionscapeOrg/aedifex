package aedifex.setup;

import aedifex.build.BuildPlatform;
import aedifex.build.BuildTarget;

class SetupStatus {
	public var target:BuildTarget;
	public var platform:BuildPlatform;
	public var ready:Bool;
	public var installed:Array<String>;
	public var detected:Array<String>;
	public var missing:Array<String>;
	public var manualSteps:Array<String>;
	public var setupCommand:String;

	public function new(target:BuildTarget, platform:BuildPlatform, setupCommand:String) {
		this.target = target;
		this.platform = platform;
		this.setupCommand = setupCommand;
		this.ready = false;
		this.installed = [];
		this.detected = [];
		this.missing = [];
		this.manualSteps = [];
	}

	public function finalize():SetupStatus {
		ready = missing.length == 0;
		return this;
	}

	public function summary():String {
		if (ready) {
			return "Ready.";
		}
		if (manualSteps.length > 0) {
			return manualSteps[0];
		}
		if (missing.length > 0) {
			return "Missing: " + missing.join(", ");
		}
		return "Target setup is incomplete.";
	}

	public function toDynamic():Dynamic {
		return {
			target: Std.string(target),
			platform: platform != null ? Std.string(platform) : null,
			ready: ready,
			installed: installed.copy(),
			detected: detected.copy(),
			missing: missing.copy(),
			manualSteps: manualSteps.copy(),
			setupCommand: setupCommand
		};
	}
}
