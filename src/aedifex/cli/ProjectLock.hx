package aedifex.cli;

import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class ProjectLock
{
	private static inline final LOCK_DIR = ".aedifex/lifecycle.lock";
	private static inline final OWNER_PATH = ".aedifex/lifecycle.lock/owner.json";

	public static function run(projectRoot:String, command:String, action:Void->Void):Void
	{
		var normalizedRoot = Path.normalize(projectRoot);
		acquire(normalizedRoot, command);
		try
		{
			action();
		}
		finally
		{
			release(normalizedRoot);
		}
	}

	private static function acquire(projectRoot:String, command:String):Void
	{
		var lockDir = Path.join([projectRoot, LOCK_DIR]);
		ensureDirectory(Path.directory(lockDir));
		try
		{
			FileSystem.createDirectory(lockDir);
		}
		catch (_:Dynamic)
		{
			throw buildLockedMessage(projectRoot);
		}

		var ownerPath = Path.join([projectRoot, OWNER_PATH]);
		var payload = {
			command: command,
			projectRoot: projectRoot,
			cwd: Sys.getCwd(),
			timestamp: Date.now().toString()
		};
		File.saveContent(ownerPath, Json.stringify(payload, "\t"));
	}

	private static function release(projectRoot:String):Void
	{
		var ownerPath = Path.join([projectRoot, OWNER_PATH]);
		var lockDir = Path.join([projectRoot, LOCK_DIR]);
		try
		{
			if (FileSystem.exists(ownerPath) && !FileSystem.isDirectory(ownerPath))
			{
				FileSystem.deleteFile(ownerPath);
			}
		}
		catch (_:Dynamic) {}

		try
		{
			if (FileSystem.exists(lockDir) && FileSystem.isDirectory(lockDir))
			{
				FileSystem.deleteDirectory(lockDir);
			}
		}
		catch (_:Dynamic) {}
	}

	private static function buildLockedMessage(projectRoot:String):String
	{
		var ownerPath = Path.join([projectRoot, OWNER_PATH]);
		var details = try File.getContent(ownerPath) catch (_:Dynamic) null;
		return details != null && StringTools.trim(details).length > 0
			? "Another Aedifex lifecycle command is already using this project. Wait for it to finish or clear the stale lifecycle lock if that process crashed. " + details
			: "Another Aedifex lifecycle command is already using this project. Wait for it to finish or clear the stale lifecycle lock if that process crashed.";
	}

	private static function ensureDirectory(path:String):Void
	{
		if (path == null || path.length == 0 || FileSystem.exists(path)) return;
		var parent = Path.directory(path);
		if (parent != null && parent != "" && parent != path)
		{
			ensureDirectory(parent);
		}
		FileSystem.createDirectory(path);
	}
}
