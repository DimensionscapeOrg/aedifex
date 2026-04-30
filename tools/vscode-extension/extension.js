const cp = require('child_process');
const fs = require('fs');
const path = require('path');
const vscode = require('vscode');

const TARGET_KEY = 'aedifex.target';
const PROFILE_KEY = 'aedifex.profile';
const HAXE_CONFIG_LABEL = 'Aedifex Root';
const DEFAULT_PROFILES = ['debug', 'release', 'final'];

let outputChannel;
let targetItem;
let profileItem;
let cleanItem;
let extensionContext;
let displayProvider;
let displayProviderRegistration;
let taskProviderDisposable;
const runTerminals = new Map();

async function activate(context) {
  extensionContext = context;
  outputChannel = vscode.window.createOutputChannel('Aedifex');

  targetItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
  targetItem.command = 'aedifex.selectTarget';
  profileItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 99);
  profileItem.command = 'aedifex.selectProfile';
  cleanItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 98);
  cleanItem.command = 'aedifex.clean';

  context.subscriptions.push(outputChannel, targetItem, profileItem, cleanItem);

  const debugProvider = new AedifexDebugConfigurationProvider();
  context.subscriptions.push(vscode.debug.registerDebugConfigurationProvider('aedifex', debugProvider));
  taskProviderDisposable = vscode.tasks.registerTaskProvider('aedifex', new AedifexTaskProvider());
  context.subscriptions.push(taskProviderDisposable);

  context.subscriptions.push(vscode.commands.registerCommand('aedifex.selectTarget', () => runHandled('Select Target', () => selectTarget())));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.selectProfile', () => runHandled('Select Profile', () => selectProfile())));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.build', () => runHandled('Build', () => runLifecycleCommand('build'))));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.clean', () => runHandled('Clean', () => runLifecycleCommand('clean'))));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.run', () => runHandled('Run', () => runLifecycleCommand('run'))));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.debug', () => runHandled('Debug', () => startDebugging())));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.rebuild', () => runHandled('Rebuild Tool', () => rebuildToolRoot())));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.task', () => runHandled('Run Task', () => runNamedTaskCommand())));
  context.subscriptions.push(vscode.commands.registerCommand('aedifex.refresh', () => runHandled('Refresh Project State', () => refreshStatusBar())));

  context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor(() => refreshStatusBar()));
  context.subscriptions.push(vscode.workspace.onDidChangeWorkspaceFolders(() => refreshStatusBar()));
  context.subscriptions.push(vscode.workspace.onDidSaveTextDocument((document) => {
    const name = path.basename(document.fileName).toLowerCase();
    if (name === 'aedifex.hx' || name === 'projectdefines.hx') {
      refreshStatusBar();
    }
  }));

  await registerDisplayProvider(context);
  await refreshStatusBar();
}

async function refreshStatusBar() {
  const folder = getActiveAedifexWorkspace();
  if (!folder) {
    targetItem.hide();
    profileItem.hide();
    cleanItem.hide();
    return;
  }

  try {
    const displayPayload = await syncDisplayProvider(folder);
    await applyGeneratedHaxeConfiguration(folder, displayPayload);
    const explain = await getExplain(folder);
    if (!hasRunnableTargets(explain)) {
      targetItem.text = `Aedifex: ${explain.kind || 'project'}`;
      targetItem.tooltip = `Active Aedifex root kind for ${folder.name}`;
      targetItem.show();
      profileItem.hide();
      cleanItem.hide();
      return;
    }
    const target = await getSelectedTarget(folder, explain.defaults ? explain.defaults.target : null);
    const profile = await getSelectedProfile(folder, explain.defaults ? explain.defaults.profile : null);
    await ensureLaunchConfiguration(folder, explain, target, profile);
    await ensureTasksConfiguration(folder, target, profile);
    targetItem.text = `Aedifex: ${target}`;
    targetItem.tooltip = `Active Aedifex target for ${folder.name}`;
    profileItem.text = `Aedifex: ${profile}`;
    profileItem.tooltip = `Active Aedifex profile for ${folder.name}`;
    cleanItem.text = '$(trash) Clean';
    cleanItem.tooltip = `Clean build with the active Aedifex target/profile for ${folder.name}`;
    targetItem.show();
    profileItem.show();
    cleanItem.show();
  } catch (error) {
    targetItem.hide();
    profileItem.hide();
    cleanItem.hide();
    outputChannel.appendLine(`[refresh] ${String(error)}`);
  }
}

async function selectTarget() {
  const folder = getActiveAedifexWorkspace();
  if (!folder) {
    vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
    return;
  }

  const payload = await getTargets(folder);
  if (!hasRunnableTargets(payload)) {
    vscode.window.showInformationMessage(nonRunnableSelectionMessage(payload));
    return;
  }
  const items = (payload.targets || [])
    .filter((target) => !target.hidden)
    .map((target) => ({
      label: target.name,
      description: buildTargetDescription(target),
      detail: target.buildSupported
        ? (target.runSupported ? 'build + run available' : 'build available')
        : (target.reason || 'not currently available'),
      target
    }));

  const choice = await vscode.window.showQuickPick(items, {
    title: 'Select Aedifex Target',
    placeHolder: 'Choose the active target for build, run, and debug'
  });

  if (!choice) {
    return;
  }

  await extensionContext.workspaceState.update(targetStateKey(folder), choice.label);
  await refreshStatusBar();
}

async function selectProfile() {
  const folder = getActiveAedifexWorkspace();
  if (!folder) {
    vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
    return;
  }

  let payload;
  try {
    payload = await execJson(folder, ['profiles']);
  } catch (_) {
    payload = { profiles: DEFAULT_PROFILES.map((name) => ({ name })) };
  }

  const items = (payload.profiles || []).map((profile) => ({
    label: profile.name,
    detail: profile.description || ''
  }));

  const choice = await vscode.window.showQuickPick(items, {
    title: 'Select Aedifex Profile',
    placeHolder: 'Choose the active debug, release, or final profile'
  });

  if (!choice) {
    return;
  }

  await extensionContext.workspaceState.update(profileStateKey(folder), choice.label);
  await refreshStatusBar();
}

async function runLifecycleCommand(command, forceClean = false) {
  const folder = getActiveAedifexWorkspace();
  if (!folder) {
    vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
    return;
  }

  const explain = await getExplain(folder);
  if (!hasRunnableTargets(explain)) {
    if (explain.kind === 'tool' && command === 'build') {
      await rebuildToolRoot(folder);
      return;
    }
    if (command === 'build' || command === 'test') {
      const taskPayload = await getTasks(folder);
      if (hasTasks(taskPayload)) {
        await runNamedTaskCommand(folder, taskPayload);
        return;
      }
    }
    vscode.window.showInformationMessage(nonRunnableMessage(explain, command, await safeTaskPayload(folder)));
    return;
  }

  const target = await getSelectedTarget(folder, null, true);
  const profile = await getSelectedProfile(folder, null, true);
  if (command === 'clean') {
    await executeTaskAndWait(createLifecycleTask(folder, 'clean', target, profile));
    return;
  }
  if (command === 'run') {
    await vscode.tasks.executeTask(createLifecycleTask(folder, 'run', target, profile));
    return;
  }
  if (command === 'build') {
    await executeTaskAndWait(createLifecycleTask(folder, command, target, profile, forceClean));
    return;
  }
  await vscode.tasks.executeTask(createLifecycleTask(folder, command, target, profile));
}

async function startDebugging() {
  const folder = getActiveAedifexWorkspace();
  if (!folder) {
    vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
    return;
  }

  const explain = await getExplain(folder);
  if (!hasRunnableTargets(explain)) {
    vscode.window.showInformationMessage(nonRunnableMessage(explain, 'debug', await safeTaskPayload(folder)));
    return;
  }

  await getSelectedTarget(folder, explain.defaults ? explain.defaults.target : null, true);
  await getSelectedProfile(folder, explain.defaults ? explain.defaults.profile : null, true);
  await vscode.debug.startDebugging(folder, {
    type: 'aedifex',
    request: 'launch',
    name: 'Aedifex'
  });
}

async function rebuildToolRoot(folderOverride) {
  const folder = folderOverride || getActiveAedifexWorkspace();
  if (!folder) {
    vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
    return;
  }

  const explain = await getExplain(folder);
  if (explain.kind !== 'tool') {
    vscode.window.showInformationMessage('This Aedifex root is not a tool root. Use build, run, or test instead.');
    return;
  }

  await vscode.tasks.executeTask(createCliTask(folder, ['rebuild']));
}

class AedifexDebugConfigurationProvider {
  async provideDebugConfigurations(folder) {
    return [];
  }

  async resolveDebugConfiguration(folder, debugConfiguration) {
    const workspaceFolder = folder || getActiveAedifexWorkspace();
    if (!workspaceFolder) {
      vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
      return null;
    }

    const target = debugConfiguration.target || await getSelectedTarget(workspaceFolder, null, true);
    const profile = debugConfiguration.profile || await getSelectedProfile(workspaceFolder, null, true);

    const plan = await execJson(workspaceFolder, ['launch-plan', target, workspaceFolder.uri.fsPath, '-profile', profile]);

    if (!plan || !plan.launcher) {
      vscode.window.showErrorMessage('Aedifex did not return a launch plan.');
      return null;
    }

    await executeTaskAndWait(createLifecycleTask(workspaceFolder, 'build', target, profile));

    const resolved = toDebugConfiguration(workspaceFolder, target, profile, plan.launcher, profile === 'debug');
    if (!resolved) {
      if (profile !== 'debug') {
        await launchWithoutDebugging(workspaceFolder, target, profile, plan.launcher);
      }
      return null;
    }
    return resolved;
  }
}

class AedifexTaskProvider {
  async provideTasks() {
    return [];
  }

  async resolveTask(task) {
    const folder = task.scope && task.scope.uri ? task.scope : getActiveAedifexWorkspace();
    if (!folder) {
      return undefined;
    }

    const definition = task.definition || {};
    const command = definition.command || 'build';
    const target = definition.target || await getSelectedTarget(folder, null);
    const profile = definition.profile || await getSelectedProfile(folder, null);
    const cleanBuild = command === 'build' ? definition.clean === true : false;
    return createLifecycleTask(folder, command, target, profile, cleanBuild);
  }
}

function toDebugConfiguration(folder, target, profile, launcher, allowWarnings = true) {
  if (launcher.kind === 'native') {
    return {
      name: 'Aedifex',
      type: launcher.debugger || (process.platform === 'win32' ? 'cppvsdbg' : 'cppdbg'),
      request: 'launch',
      program: launcher.command,
      args: Array.isArray(launcher.args) ? launcher.args : [],
      cwd: launcher.cwd || folder.uri.fsPath,
      stopAtEntry: false,
      console: 'integratedTerminal'
    };
  }

  if (launcher.kind === 'terminal') {
    if (String(launcher.command || '').toLowerCase() !== 'node') {
      if (allowWarnings) {
        vscode.window.showWarningMessage(`Aedifex target '${target}' runs in a terminal for profile '${profile}', but it does not currently expose a VS Code debugger.`);
      }
      return null;
    }
    return {
      name: 'Aedifex',
      type: 'node-terminal',
      request: 'launch',
      commandLine: buildTerminalCommand(launcher),
      cwd: launcher.cwd || folder.uri.fsPath
    };
  }

  if (allowWarnings) {
    vscode.window.showWarningMessage(`Aedifex target '${target}' does not currently expose a VS Code debugger for profile '${profile}'.`);
  }
  return null;
}

async function launchWithoutDebugging(folder, target, profile, launcher) {
  if (launcher.kind === 'native') {
    const config = toDebugConfiguration(folder, target, profile, launcher);
    if (!config) {
      return;
    }
    await vscode.debug.startDebugging(folder, config, { noDebug: true });
    return;
  }

  if (launcher.kind === 'terminal') {
    const terminal = getOrCreateRunTerminal(folder, target, launcher.cwd || folder.uri.fsPath);
    terminal.show(true);
    terminal.sendText(buildTerminalCommand(launcher), true);
    return;
  }

  if (launcher.kind === 'browser' && launcher.file) {
    await vscode.env.openExternal(vscode.Uri.file(launcher.file));
    return;
  }

  vscode.window.showWarningMessage(`Aedifex target '${target}' does not currently expose a runnable launch surface for profile '${profile}'.`);
}

function buildTerminalCommand(launcher) {
  const parts = [launcher.command].concat(Array.isArray(launcher.args) ? launcher.args : []);
  return parts.map(quoteArg).join(' ');
}

function resolveLauncherCwd(launcher) {
  const candidates = [];
  if (launcher && launcher.cwd) {
    candidates.push(launcher.cwd);
  }
  if (launcher && Array.isArray(launcher.args)) {
    for (const arg of launcher.args) {
      const text = String(arg || '');
      if (/\.(jar|js|n|hl|php|exe)$/i.test(text)) {
        candidates.push(path.dirname(text));
      }
    }
  }
  if (launcher && launcher.command && /^[A-Za-z]:[\\/]|^\//.test(String(launcher.command))) {
    candidates.push(path.dirname(String(launcher.command)));
  }

  for (const candidate of candidates) {
    try {
      if (candidate && fs.existsSync(candidate) && fs.statSync(candidate).isDirectory()) {
        return candidate;
      }
    } catch (_) {}
  }

  return launcher && launcher.cwd ? launcher.cwd : null;
}

function quoteArg(value) {
  const text = String(value || '');
  if (process.platform === 'win32') {
    if (!/[\s"]/u.test(text)) {
      return text;
    }
    return `"${text.replace(/"/g, '\\"')}"`;
  }

  if (!/[\s'"$]/u.test(text)) {
    return text;
  }
  return `'${text.replace(/'/g, `'\\''`)}'`;
}

async function getExplain(folder) {
  return execJson(folder, ['explain', folder.uri.fsPath]);
}

async function getTargets(folder) {
  return execJson(folder, ['targets', folder.uri.fsPath]);
}

async function getTasks(folder) {
  return execJson(folder, ['tasks', folder.uri.fsPath]);
}

async function getSelectedTarget(folder, fallback, promptIfMissing = false) {
  const key = targetStateKey(folder);
  const payload = await getTargets(folder);
  const available = getRunnableTargets(payload);
  const availableNames = new Set(available.map((item) => item.name));
  let target = extensionContext.workspaceState.get(key);
  if (target && !availableNames.has(target)) {
    target = null;
  }
  if (!target && fallback && availableNames.has(fallback)) {
    target = fallback;
  }
  if (!target) {
    const explain = await getExplain(folder);
    const defaultTarget = explain.defaults ? explain.defaults.target : null;
    if (defaultTarget && availableNames.has(defaultTarget)) {
      target = defaultTarget;
    }
  }
  if (!target) {
    if (promptIfMissing && available.length > 1) {
      const selected = await promptForTarget(folder, payload);
      if (selected) {
        target = selected;
      }
    }
    if (!target) {
      const first = available[0];
      target = first ? first.name : null;
    }
  }
  if (!target) {
    throw new Error('This Aedifex root does not currently declare a runnable target.');
  }
  await extensionContext.workspaceState.update(key, target);
  return target;
}

async function getSelectedProfile(folder, fallback, promptIfMissing = false) {
  const key = profileStateKey(folder);
  let profile = extensionContext.workspaceState.get(key);
  if (!profile) {
    profile = fallback;
  }
  if (!profile) {
    if (promptIfMissing) {
      const selected = await promptForProfile(folder);
      if (selected) {
        profile = selected;
      }
    }
    if (!profile) {
      const payload = await getExplain(folder);
      profile = payload.defaults ? payload.defaults.profile : 'debug';
    }
  }
  await extensionContext.workspaceState.update(key, profile);
  return profile;
}

function getRunnableTargets(payload) {
  return (payload && Array.isArray(payload.targets) ? payload.targets : [])
    .filter((item) => item && item.buildSupported && !item.hidden);
}

async function promptForTarget(folder, payload) {
  const available = getRunnableTargets(payload);
  if (available.length === 0) {
    return null;
  }

  const items = available.map((target) => ({
    label: target.name,
    description: buildTargetDescription(target),
    detail: target.runSupported ? 'build + run available' : 'build available',
    target
  }));

  const choice = await vscode.window.showQuickPick(items, {
    title: 'Select Aedifex Target',
    placeHolder: 'Choose a target for this run or debug session'
  });

  if (!choice) {
    return null;
  }

  await extensionContext.workspaceState.update(targetStateKey(folder), choice.label);
  return choice.label;
}

async function promptForProfile(folder) {
  const items = DEFAULT_PROFILES.map((name) => ({
    label: name,
    detail: name === 'debug'
      ? 'Fast iteration'
      : (name === 'release' ? 'Standard optimized build' : 'Final build with finalization hooks')
  }));

  const choice = await vscode.window.showQuickPick(items, {
    title: 'Select Aedifex Profile',
    placeHolder: 'Choose a profile for this run or debug session'
  });

  if (!choice) {
    return null;
  }

  await extensionContext.workspaceState.update(profileStateKey(folder), choice.label);
  return choice.label;
}

async function runNamedTaskCommand(folderOverride, preloadedPayload) {
  const folder = folderOverride || getActiveAedifexWorkspace();
  if (!folder) {
    vscode.window.showInformationMessage('No Aedifex workspace is currently active.');
    return;
  }

  const payload = preloadedPayload || await getTasks(folder);
  const tasks = payload && Array.isArray(payload.tasks) ? payload.tasks : [];
  if (tasks.length === 0) {
    vscode.window.showInformationMessage('This Aedifex root does not currently declare any tasks.');
    return;
  }

  const items = tasks.map((task) => ({
    label: task.name,
    description: task.command,
    detail: task.description || ((task.args || []).join(' ')),
    task
  }));

  const choice = await vscode.window.showQuickPick(items, {
    title: 'Run Aedifex Task',
    placeHolder: 'Choose a task from this Aedifex root'
  });

  if (!choice) {
    return;
  }

  await vscode.tasks.executeTask(createCliTask(folder, ['task', choice.task.name, folder.uri.fsPath]));
}

function targetStateKey(folder) {
  return `${TARGET_KEY}:${folder.uri.fsPath}`;
}

function profileStateKey(folder) {
  return `${PROFILE_KEY}:${folder.uri.fsPath}`;
}

function getActiveAedifexWorkspace() {
  const folders = vscode.workspace.workspaceFolders || [];
  const activeEditor = vscode.window.activeTextEditor;
  if (activeEditor && activeEditor.document && activeEditor.document.uri && activeEditor.document.uri.scheme === 'file') {
    const root = findAedifexRoot(activeEditor.document.uri.fsPath);
    if (root) {
      return workspaceLike(root);
    }
  }

  const active = activeEditor ? vscode.workspace.getWorkspaceFolder(activeEditor.document.uri) : null;
  if (active && hasAedifexProject(active)) {
    return active;
  }
  return folders.find((folder) => hasAedifexProject(folder));
}

function findAedifexRoot(filePath) {
  let current = fs.statSync(filePath).isDirectory() ? filePath : path.dirname(filePath);
  while (current && current.length > 0) {
    if (fs.existsSync(path.join(current, 'Aedifex.hx'))) {
      return current;
    }
    const parent = path.dirname(current);
    if (!parent || parent === current) {
      break;
    }
    current = parent;
  }
  return null;
}

function workspaceLike(rootPath) {
  return {
    name: path.basename(rootPath),
    uri: vscode.Uri.file(rootPath)
  };
}

function hasAedifexProject(folder) {
  if (!folder) {
    return false;
  }
  return fs.existsSync(path.join(folder.uri.fsPath, 'Aedifex.hx'));
}

async function execJson(folder, args) {
  const result = await runCli(folder, args.concat('-json'), { expectJson: true, reveal: false });
  return parseJsonResponse(result.stdout, result.stderr);
}

function runCli(folder, args, options) {
  const finalArgs = buildCliArgs(args);
  const candidates = resolveCliCandidates(folder, finalArgs);
  return runCliCandidate(folder, candidates, options, 0);
}

function buildCliArgs(args) {
  const configuration = vscode.workspace.getConfiguration('aedifex');
  const finalArgs = [];
  const theme = configuration.get('theme');
  const pluginsPath = configuration.get('pluginsPath');
  const jsonMode = Array.isArray(args) && (args.includes('-json') || args.includes('--json'));

  if (theme && !jsonMode) {
    finalArgs.push(`-theme=${theme}`);
  }
  if (pluginsPath) {
    finalArgs.push(`-plugins=${pluginsPath}`);
  }

  return finalArgs.concat(args);
}

function resolveCliCandidates(folder, finalArgs) {
  const configuration = vscode.workspace.getConfiguration('aedifex', folder.uri);
  const configured = configuration.get('cliPath');
  if (configured && configured.trim().length > 0) {
    return [candidateFromPath(configured.trim(), finalArgs)];
  }

  const candidates = [];
  if (isAedifexToolCheckout(folder)) {
    candidates.push({
      command: 'neko',
      args: [path.join(folder.uri.fsPath, 'run.n')].concat(finalArgs),
      display: `neko ${quoteArg(path.join(folder.uri.fsPath, 'run.n'))} ${finalArgs.map(quoteArg).join(' ')}`
    });
  }

  candidates.push({
    command: 'haxelib',
    args: ['run', 'aedifex'].concat(finalArgs),
    display: `haxelib run aedifex ${finalArgs.map(quoteArg).join(' ')}`
  });
  return candidates;
}

function candidateFromPath(cliPath, finalArgs) {
  const normalized = cliPath.trim();
  const lower = normalized.toLowerCase();
  if (lower.endsWith('.n')) {
    return {
      command: 'neko',
      args: [normalized].concat(finalArgs),
      display: `neko ${quoteArg(normalized)} ${finalArgs.map(quoteArg).join(' ')}`
    };
  }

  return candidateFromCommand(normalized, finalArgs);
}

function candidateFromCommand(command, finalArgs) {
  return {
    command,
    args: finalArgs.slice(),
    display: `${command} ${finalArgs.map(quoteArg).join(' ')}`
  };
}

function runCliCandidate(folder, candidates, options, index) {
  return new Promise((resolve, reject) => {
    if (index >= candidates.length) {
      reject(new Error('Unable to launch Aedifex. Configure `aedifex.cliPath` or install the `aedifex` command.')); 
      return;
    }

    const candidate = candidates[index];
    const child = cp.spawn(candidate.command, candidate.args, {
      cwd: folder.uri.fsPath,
      windowsHide: true,
      shell: process.platform === 'win32'
    });

    let stdout = '';
    let stderr = '';

    if (options.reveal) {
      outputChannel.show(true);
      outputChannel.appendLine(`> ${candidate.display}`);
    }

    child.stdout.on('data', (chunk) => {
      const text = chunk.toString();
      stdout += text;
      if (options.reveal) {
        outputChannel.append(text);
      }
    });

    child.stderr.on('data', (chunk) => {
      const text = chunk.toString();
      stderr += text;
      if (options.reveal || options.expectJson) {
        outputChannel.append(text);
      }
    });

    child.on('error', (error) => {
      if (error && error.code === 'ENOENT') {
        runCliCandidate(folder, candidates, options, index + 1).then(resolve, reject);
        return;
      }
      reject(error);
    });

    child.on('close', (code) => {
      if (code === 0) {
        resolve({ stdout, stderr });
        return;
      }

      if ((code === 1 || code === 9009) && index + 1 < candidates.length && stderr.trim().length === 0 && stdout.trim().length === 0) {
        runCliCandidate(folder, candidates, options, index + 1).then(resolve, reject);
        return;
      }

      const message = stderr.trim() || stdout.trim() || `Aedifex exited with code ${code}.`;
      reject(new Error(message));
    });
  });
}

function isAedifexToolCheckout(folder) {
  const root = folder && folder.uri ? folder.uri.fsPath : null;
  if (!root) {
    return false;
  }

  return fs.existsSync(path.join(root, 'run.n'))
    && fs.existsSync(path.join(root, 'src', 'aedifex', 'cli', 'Main.hx'))
    && fs.existsSync(path.join(root, 'haxelib.json'));
}

function hasRunnableTargets(payload) {
  const targets = payload && Array.isArray(payload.targets) ? payload.targets : [];
  return targets.some((item) => item && item.buildSupported && !item.hidden);
}

function parseJsonResponse(stdout, stderr) {
  const text = String(stdout || '').trim();
  const errText = String(stderr || '').trim();

  if (text.length === 0) {
    throw new Error(errText.length > 0 ? errText : 'Aedifex did not return any JSON output.');
  }

  try {
    return JSON.parse(text);
  } catch (_) {}

  const objectStart = text.indexOf('{');
  const objectEnd = text.lastIndexOf('}');
  if (objectStart !== -1 && objectEnd > objectStart) {
    const candidate = text.slice(objectStart, objectEnd + 1);
    try {
      return JSON.parse(candidate);
    } catch (_) {}
  }

  throw new Error(text.length > 0 ? text : (errText.length > 0 ? errText : 'Aedifex returned non-JSON output.'));
}

async function runHandled(label, callback) {
  try {
    return await callback();
  } catch (error) {
    const message = String(error && error.message ? error.message : error);
    outputChannel.show(true);
    outputChannel.appendLine(`[${label}] ${message}`);
    vscode.window.showErrorMessage(`Aedifex ${label.toLowerCase()} failed: ${message}`);
    return null;
  }
}

function capitalize(value) {
  const text = String(value || '');
  if (text.length === 0) {
    return text;
  }
  return text.charAt(0).toUpperCase() + text.slice(1);
}

async function ensureLaunchConfiguration(folder, explain, target, profile) {
  if (!folder || !hasRunnableTargets(explain)) {
    return;
  }

  const vscodeDir = path.join(folder.uri.fsPath, '.vscode');
  const launchPath = path.join(vscodeDir, 'launch.json');
  const desiredConfig = {
    type: 'aedifex',
    request: 'launch',
    name: 'Aedifex',
    target,
    profile
  };

  let launchData = {
    version: '0.2.0',
    configurations: []
  };

  try {
    if (fs.existsSync(launchPath)) {
      const raw = fs.readFileSync(launchPath, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        launchData = parsed;
      }
    }
  } catch (error) {
    outputChannel.appendLine(`[launch] Skipped launch.json sync for ${folder.uri.fsPath}: ${String(error)}`);
    return;
  }

  if (!Array.isArray(launchData.configurations)) {
    launchData.configurations = [];
  }
  if (!launchData.version) {
    launchData.version = '0.2.0';
  }

  const preservedConfigurations = launchData.configurations.filter((config) => !(config && config.type === 'aedifex'));
  launchData.configurations = [desiredConfig].concat(preservedConfigurations);

  fs.mkdirSync(vscodeDir, { recursive: true });
  fs.writeFileSync(launchPath, `${JSON.stringify(launchData, null, 2)}\n`, 'utf8');
}

async function ensureTasksConfiguration(folder, target, profile) {
  if (!folder || !target || !profile) {
    return;
  }

  const vscodeDir = path.join(folder.uri.fsPath, '.vscode');
  const tasksPath = path.join(vscodeDir, 'tasks.json');
  const desiredTask = {
    label: 'Aedifex',
    type: 'aedifex',
    command: 'build',
    target,
    profile,
    clean: false,
    problemMatcher: []
  };

  let tasksData = {
    version: '2.0.0',
    tasks: []
  };

  try {
    if (fs.existsSync(tasksPath)) {
      const raw = fs.readFileSync(tasksPath, 'utf8');
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        tasksData = parsed;
      }
    }
  } catch (error) {
    outputChannel.appendLine(`[tasks] Skipped tasks.json sync for ${folder.uri.fsPath}: ${String(error)}`);
    return;
  }

  if (!Array.isArray(tasksData.tasks)) {
    tasksData.tasks = [];
  }
  if (!tasksData.version) {
    tasksData.version = '2.0.0';
  }

  const preservedTasks = tasksData.tasks.filter((task) => {
    if (!task) {
      return true;
    }
    if (task.label === 'Aedifex' || task.label === 'aedifex: Aedifex') {
      return false;
    }
    if (task.type === 'aedifex') {
      return false;
    }
    return true;
  });
  tasksData.tasks = [desiredTask].concat(preservedTasks);

  fs.mkdirSync(vscodeDir, { recursive: true });
  fs.writeFileSync(tasksPath, `${JSON.stringify(tasksData, null, 2)}\n`, 'utf8');
}

function buildTargetDescription(target) {
  const parts = [];
  if (target.backend) {
    parts.push(`${target.backend} backend`);
  }
  if (target.platform) {
    parts.push(target.platform);
  }
  if (target.architecture) {
    parts.push(target.architecture);
  }
  return parts.join(' - ');
}

function buildLifecycleArgs(command, target, projectPath, profile, cleanBuild = false) {
  const args = [command, target, projectPath, '-profile', profile, '-ignore'];
  if (command === 'build' && cleanBuild) {
    args.push('-clean');
  }
  return args;
}

function createLifecycleTask(folder, command, target, profile, cleanBuild = false) {
  const args = buildLifecycleArgs(command, target, folder.uri.fsPath, profile, cleanBuild);
  return createCliTask(folder, args);
}

function executeTaskAndWait(task) {
  return new Promise(async (resolve, reject) => {
    let execution;
    try {
      execution = await vscode.tasks.executeTask(task);
    } catch (error) {
      reject(error);
      return;
    }

    const disposable = vscode.tasks.onDidEndTaskProcess((event) => {
      if (!execution || event.execution !== execution) {
        return;
      }
      disposable.dispose();
      if (event.exitCode === 0 || event.exitCode == null) {
        resolve();
      } else {
        reject(new Error(`Aedifex task failed with exit code ${event.exitCode}.`));
      }
    });
  });
}

function createCliTask(folder, args) {
  const candidate = resolveCliCandidates(folder, buildCliArgs(args))[0];
  const definition = {
    type: 'aedifex',
    command: args[0] || 'build',
    target: args[1] || null,
    profile: extractProfileFromArgs(args),
    clean: hasArg(args, '-clean')
  };
  const execution = (candidate.command && Array.isArray(candidate.args))
    ? new vscode.ProcessExecution(candidate.command, candidate.args, {
        cwd: folder.uri.fsPath
      })
    : new vscode.ShellExecution(candidate.display, {
        cwd: folder.uri.fsPath
      });
  const task = new vscode.Task(definition, folder, 'Aedifex', 'aedifex', execution);
  task.presentationOptions = {
    reveal: vscode.TaskRevealKind.Always,
    clear: false,
    focus: false,
    echo: true,
    panel: vscode.TaskPanelKind.Shared
  };
  task.isBackground = false;
  return task;
}

function extractProfileFromArgs(args) {
  for (let i = 0; i < args.length; i++) {
    if ((args[i] === '-profile' || args[i] === '--profile') && i + 1 < args.length) {
      return args[i + 1];
    }
  }
  return null;
}

function hasArg(args, value) {
  return Array.isArray(args) && args.includes(value);
}

function lifecycleTaskLabel(command) {
  return 'Aedifex';
}

function hasTasks(payload) {
  const tasks = payload && Array.isArray(payload.tasks) ? payload.tasks : [];
  return tasks.length > 0;
}

async function safeTaskPayload(folder) {
  try {
    return await getTasks(folder);
  } catch (_) {
    return null;
  }
}

function nonRunnableMessage(explain, command, taskPayload) {
  const kind = explain && explain.kind ? explain.kind : 'project';
  const taskHint = hasTasks(taskPayload) ? ' Use `Aedifex: Run Task` for framework/library workflows.' : '';
  if (kind === 'tool') {
    if (command === 'debug' || command === 'run') {
      return 'This Aedifex tool root is not a runnable app target. Use `Aedifex: Build` to rebuild the tool.';
    }
    return 'This Aedifex tool root does not declare runnable targets. Use `Aedifex: Build` to rebuild the tool.';
  }

  if (kind === 'library' || kind === 'framework' || kind === 'plugin' || kind === 'extension') {
    if (command === 'run' || command === 'debug') {
      return `This Aedifex ${kind} root is not a runnable app target.${taskHint}`;
    }
    return `This Aedifex ${kind} root does not declare runnable targets.${taskHint}`;
  }

  return `This Aedifex ${kind} root does not currently declare runnable targets.`;
}

function nonRunnableSelectionMessage(payload) {
  const kind = payload && payload.kind ? payload.kind : 'project';
  if (kind === 'tool') {
    return 'This Aedifex tool root rebuilds the tool itself instead of selecting runnable targets.';
  }
  if (kind === 'library' || kind === 'framework' || kind === 'plugin' || kind === 'extension') {
    return `This Aedifex ${kind} root is valid, but it does not expose runnable targets. Use tasks or metadata workflows instead.`;
  }
  return 'This Aedifex root does not currently declare runnable targets.';
}

function getOrCreateRunTerminal(folder, target, cwd) {
  const key = `${folder.uri.fsPath}:${target}`;
  const existing = runTerminals.get(key);
  if (existing && existing.exitStatus === undefined) {
    return existing;
  }
  const terminal = vscode.window.createTerminal({
    name: `Aedifex: ${target}`,
    cwd
  });
  runTerminals.set(key, terminal);
  return terminal;
}

async function registerDisplayProvider(context) {
  const extension = vscode.extensions.getExtension('nadako.vshaxe');
  if (!extension) {
    outputChannel.appendLine('[display] vshaxe not installed; Aedifex.hx completion provider unavailable.');
    return;
  }

  let api;
  try {
    api = extension.isActive ? extension.exports : await extension.activate();
  } catch (error) {
    outputChannel.appendLine(`[display] failed to activate vshaxe: ${String(error)}`);
    return;
  }

  if (!api || typeof api.registerDisplayArgumentsProvider !== 'function' || typeof api.parseHxmlToArguments !== 'function') {
    outputChannel.appendLine('[display] incompatible vshaxe API; expected registerDisplayArgumentsProvider and parseHxmlToArguments.');
    return;
  }

  displayProvider = new AedifexDisplayArgsProvider(api, () => refreshStatusBar());
  displayProviderRegistration = api.registerDisplayArgumentsProvider('Aedifex', displayProvider);
  context.subscriptions.push(displayProviderRegistration);
}

async function syncDisplayProvider(folder) {
  if (!folder) {
    return null;
  }
  if (!displayProvider) {
    return await execJson(folder, ['display', 'sync', folder.uri.fsPath]);
  }
  return await displayProvider.sync(folder);
}

class AedifexDisplayArgsProvider {
  constructor(api, activationChangedCallback) {
    this.description = 'Project using Aedifex root configuration';
    this.api = api;
    this.activationChangedCallback = activationChangedCallback;
    this.updateArgumentsCallback = null;
    this.parsedArguments = null;
    this.serializedArgs = null;
    this.workspaceRoot = null;
  }

  activate(provideArguments) {
    this.updateArgumentsCallback = provideArguments;
    if (this.parsedArguments) {
      this.updateArgumentsCallback(this.parsedArguments);
    }
    if (typeof this.activationChangedCallback === 'function') {
      this.activationChangedCallback(true);
    }
  }

  deactivate() {
    this.updateArgumentsCallback = null;
    if (typeof this.activationChangedCallback === 'function') {
      this.activationChangedCallback(false);
    }
  }

  async sync(folder) {
    if (!folder || !hasAedifexProject(folder)) {
      return null;
    }

    const payload = await execJson(folder, ['display', 'sync', folder.uri.fsPath]);
    if (!payload || !Array.isArray(payload.args)) {
      return payload;
    }

    const serializedArgs = JSON.stringify(payload.args);
    const changedWorkspace = this.workspaceRoot !== folder.uri.fsPath;
    if (!changedWorkspace && serializedArgs === this.serializedArgs) {
      return payload;
    }

    this.workspaceRoot = folder.uri.fsPath;
    this.serializedArgs = serializedArgs;
    this.parsedArguments = payload.args.slice();
    if (this.updateArgumentsCallback) {
      this.updateArgumentsCallback(this.parsedArguments);
    }
    return payload;
  }
}

async function applyGeneratedHaxeConfiguration(folder, payload) {
  if (!payload || !Array.isArray(payload.args)) {
    return;
  }

  const configuration = vscode.workspace.getConfiguration('haxe', folder.uri);
  const current = configuration.get('configurations') || [];
  const generated = {
    label: payload.label || HAXE_CONFIG_LABEL,
    args: payload.args,
    files: Array.isArray(payload.files) ? payload.files : ['Aedifex.hx', 'ProjectDefines.hx']
  };

  const next = [generated].concat(current.filter((entry) => !(entry && typeof entry === 'object' && entry.label === generated.label)));
  const legacyNext = next.map((entry) => entry && typeof entry === 'object' ? {
    label: entry.label,
    args: entry.args,
    files: entry.files
  } : entry);

  const currentLegacy = configuration.get('displayConfigurations') || [];
  const changedConfigurations = JSON.stringify(current) !== JSON.stringify(next);
  const changedLegacy = JSON.stringify(currentLegacy) !== JSON.stringify(legacyNext);

  if (!changedConfigurations && !changedLegacy) {
    return;
  }

  const targets = [
    vscode.ConfigurationTarget.WorkspaceFolder,
    vscode.ConfigurationTarget.Workspace
  ];

  for (const target of targets) {
    if (changedConfigurations) {
      try {
        await configuration.update('configurations', next, target);
      } catch (_) {}
    }
    if (changedLegacy) {
      try {
        await configuration.update('displayConfigurations', legacyNext, target);
      } catch (_) {}
    }
  }
}

function deactivate() {
  if (displayProviderRegistration && typeof displayProviderRegistration.dispose === 'function') {
    displayProviderRegistration.dispose();
  }
  displayProviderRegistration = null;
  displayProvider = null;
}

module.exports = {
  activate,
  deactivate
};


