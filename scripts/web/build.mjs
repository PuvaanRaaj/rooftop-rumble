import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { existsSync, readFileSync, writeFileSync, mkdirSync, rmSync, cpSync, chmodSync, readdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { inflateRawSync } from 'node:zlib';

const root = fileURLToPath(new URL('../../', import.meta.url));
const tools = path.join(root, '.tools');
const release = 'https://github.com/godotengine/godot-builds/releases/download/4.5.2-stable';
const template = path.join(tools, 'web/web_nothreads_release.zip');
const templateSha = '5f202410b79f15d31bfef4c434ee7b7bcc964b50a587bb1338cb53ad9d94c61b';
const hash = (file) => createHash('sha256').update(readFileSync(file)).digest('hex');

function download(asset, destination, range) {
  const args = ['--fail', '--location', '--retry', '3', '--connect-timeout', '30', '--max-time', '600', '--silent', '--show-error'];
  if (range) args.push('--range', range);
  console.log(`Downloading official Godot 4.5.2 ${asset}${range ? ' (web template only)' : ''}…`);
  execFileSync('curl', [...args, `${release}/${asset}`, '--output', destination], { stdio: 'inherit' });
}

function verify(file, checksum) {
  if (hash(file) !== checksum) {
    rmSync(file, { force: true });
    throw new Error(`Checksum verification failed: ${path.basename(file)}`);
  }
}

function ensureTemplate() {
  mkdirSync(path.dirname(template), { recursive: true });
  if (existsSync(template) && hash(template) === templateSha) return;
  const entry = path.join(tools, 'web/template-entry.tmp');
  try {
    // Fixed offsets from the official 4.5.2 archive's ZIP central directory.
    // Fetch only web_nothreads_release.zip instead of all 1.35 GB of templates.
    download('Godot_v4.5.2-stable_export_templates.tpz', entry, '1142166206-1151585561');
    const bytes = readFileSync(entry);
    if (bytes.length !== 9419356 || bytes.readUInt32LE(0) !== 0x04034b50) {
      throw new Error('The template server did not honor the requested byte range.');
    }
    const offset = 30 + bytes.readUInt16LE(26) + bytes.readUInt16LE(28);
    const name = bytes.subarray(30, 30 + bytes.readUInt16LE(26)).toString();
    if (name !== 'templates/web_nothreads_release.zip' || bytes.readUInt16LE(8) !== 8) {
      throw new Error('Unexpected template ZIP entry.');
    }
    writeFileSync(template, inflateRawSync(bytes.subarray(offset, offset + 9419263)));
    verify(template, templateSha);
  } finally {
    rmSync(entry, { force: true });
  }
}

function ensureGodot() {
  const localMac = path.join(tools, 'Godot.app/Contents/MacOS/Godot');
  const localLinux = path.join(tools, 'godot/Godot_v4.5.2-stable_linux.x86_64');
  let executable = process.env.GODOT_BIN;
  if (!executable) executable = process.platform === 'darwin' ? localMac : localLinux;
  if (!existsSync(executable)) {
    if (process.env.GODOT_BIN) throw new Error('GODOT_BIN must point to an existing Godot 4.5.2 executable.');
    const assets = {
      darwin: ['Godot_v4.5.2-stable_macos.universal.zip', '2a3f35cf5813b0d26e3f4c15dabc5e7c58407fceec7bae5291740772f72d141a'],
      linux: ['Godot_v4.5.2-stable_linux.x86_64.zip', '87f6e6be292929e363d15ed9052f277b2ba4e95ed994e1e099048097be2dfd03'],
    };
    const asset = assets[process.platform];
    if (!asset || (process.platform === 'linux' && process.arch !== 'x64')) {
      throw new Error('Automatic downloads support macOS and Linux x64. Set GODOT_BIN on other systems.');
    }
    const archive = path.join(tools, 'godot-download.zip');
    download(asset[0], archive);
    verify(archive, asset[1]);
    const destination = process.platform === 'darwin' ? tools : path.join(tools, 'godot');
    mkdirSync(destination, { recursive: true });
    execFileSync('unzip', ['-q', '-o', archive, '-d', destination], { stdio: 'inherit' });
    rmSync(archive);
    chmodSync(executable, 0o755);
  }
  const version = execFileSync(executable, ['--version'], { encoding: 'utf8' }).trim();
  if (!version.startsWith('4.5.2.stable.')) throw new Error(`Expected Godot 4.5.2 stable, found ${version}`);
  console.log(`Using Godot ${version}`);
  return executable;
}

try {
  mkdirSync(tools, { recursive: true });
  writeFileSync(path.join(tools, '.gdignore'), '');
  ensureTemplate();
  const godot = ensureGodot();
  const shell = path.join(root, 'web');
  if (!existsSync(path.join(shell, 'index.html'))) throw new Error('Missing browser landing page: web/index.html');
  const dist = path.join(root, 'dist');
  rmSync(dist, { recursive: true, force: true });
  mkdirSync(path.join(dist, 'game'), { recursive: true });
  writeFileSync(path.join(dist, '.gdignore'), '');
  execFileSync(godot, ['--headless', '--path', root, '--editor', '--import', '--quit'], { stdio: 'inherit' });
  execFileSync(godot, ['--headless', '--path', root, '--export-release', 'Web', path.join(dist, 'game/index.html')], { stdio: 'inherit' });
  for (const item of readdirSync(shell)) {
    if (item !== '.gdignore') cpSync(path.join(shell, item), path.join(dist, item), { recursive: true });
  }
  for (const file of ['index.html', 'index.js', 'index.wasm', 'index.pck']) {
    if (!existsSync(path.join(dist, 'game', file))) throw new Error(`Export missing game/${file}`);
  }
  if (!existsSync(path.join(dist, 'index.html'))) throw new Error('Export missing landing page index.html');
  console.log('Web export complete: dist/game/index.html. Run npm run serve to play.');
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
}
