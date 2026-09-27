// Regression test for the CI input boundary. Shorebird/Xcode/Pods are mocked;
// this test cannot build or publish an actual release or patch.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');

const repository = path.resolve(__dirname, '..');
const fixture = fs.mkdtempSync(path.join(os.tmpdir(), 'verdict-shorebird-test-'));
const bash = process.env.BASH_BINARY || (process.platform === 'win32'
  ? 'C:/Program Files/Git/bin/bash.exe' : 'bash');
const harness = `
xcodebuild() { echo 'Mock Xcode'; }
pod() { echo 'Mock CocoaPods'; }
shorebird() { printf '%s\\n' "$@" >> shorebird-args.txt; }
export -f xcodebuild pod shorebird
bash tool/shorebird_codemagic.sh "$1"
`;

try {
  fs.mkdirSync(path.join(fixture, 'tool'));
  fs.mkdirSync(path.join(fixture, 'ios'));
  for (const name of ['shorebird.yaml', 'pubspec.yaml', 'pubspec.lock',
    'ios/Podfile.lock', 'tool/check_shorebird.sh', 'tool/shorebird_codemagic.sh']) {
    fs.copyFileSync(path.join(repository, name), path.join(fixture, name));
  }
  const argsFile = path.join(fixture, 'shorebird-args.txt');
  const run = (value, mode) => {
    if (fs.existsSync(argsFile)) fs.unlinkSync(argsFile);
    const env = { ...process.env, SHOREBIRD_TOKEN: 'local-test-only',
      RELEASE_VERSION: '38.0.0+38', PATCH_TRACK: 'stable' };
    delete env.REVENUECAT_IOS_API_KEY;
    delete env.REVENUECAT_ANDROID_API_KEY;
    delete env.PATCH_DRY_RUN;
    if (value !== undefined) env.PATCH_DRY_RUN = value;
    return spawnSync(bash, ['-c', harness, 'test', mode], {
      cwd: fixture, env, encoding: 'utf8', windowsHide: true,
    });
  };

  let checks = 0;
  for (const [value, dryRun] of [
    ['true', true], ['True', true], ['TRUE', true], [' \tTrUe\r\n', true],
    ['false', false], ['False', false], ['FALSE', false], [' \tfAlSe\r\n', false],
  ]) {
    const validation = run(value, 'validate-patch');
    assert.equal(validation.status, 0, validation.stderr || validation.stdout);
    assert(validation.stdout.includes(`dry_run: ${dryRun}`));
    assert(!fs.existsSync(argsFile), 'Validation must not invoke Shorebird.');
    const patch = run(value, 'patch');
    assert.equal(patch.status, 0, patch.stderr || patch.stdout);
    const args = fs.readFileSync(argsFile, 'utf8').trim().split(/\r?\n/);
    assert(args.includes('patch'));
    assert(args.includes('--release-version=38.0.0+38'));
    assert(args.includes('--track=stable'));
    assert.equal(args.includes('--dry-run'), dryRun);
    checks += 2;
  }
  for (const value of [undefined, '', ' ', 'yes', '0', '1', 'f alse', '${{ inputs.dry_run }}']) {
    for (const mode of ['validate-patch', 'patch']) {
      const result = run(value, mode);
      assert.equal(result.status, 1);
      assert(result.stderr.includes('Invalid dry_run value'));
      assert(!fs.existsSync(argsFile), 'Invalid input must not invoke Shorebird.');
      checks++;
    }
  }
  console.log(`${checks} checks passed: input normalization, validation and patch flags.`);
} finally {
  // Only remove the unique fixture created by this test under the OS temp dir.
  assert.equal(path.dirname(fixture), path.resolve(os.tmpdir()));
  assert(path.basename(fixture).startsWith('verdict-shorebird-test-'));
  fs.rmSync(fixture, { recursive: true, force: true });
}
