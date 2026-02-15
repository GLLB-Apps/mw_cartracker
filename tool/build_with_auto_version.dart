import 'dart:io';

final _versionLineRegex = RegExp(r'^version:\s*([^\s]+)\s*$', multiLine: true);
final _semverRegex = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

Future<void> main(List<String> args) async {
  final projectRoot = Directory.current.path;
  final pubspecFile = File('$projectRoot/pubspec.yaml');

  if (!await pubspecFile.exists()) {
    stderr.writeln('Could not find pubspec.yaml in: $projectRoot');
    exitCode = 1;
    return;
  }

  final pubspecContent = await pubspecFile.readAsString();
  final currentMatch = _versionLineRegex.firstMatch(pubspecContent);
  if (currentMatch == null) {
    stderr.writeln('Could not find version: line in pubspec.yaml');
    exitCode = 1;
    return;
  }

  final currentVersion = currentMatch.group(1)!;
  final currentBaseVersion = currentVersion.split('+').first;

  final latestTagRaw = await _runAndRead(
    'git',
    ['describe', '--tags', '--abbrev=0'],
  );

  final normalizedTagVersion = _normalizeTag(latestTagRaw?.trim() ?? '');
  final baseVersion = _semverRegex.hasMatch(normalizedTagVersion)
      ? normalizedTagVersion
      : currentBaseVersion;

  final commitCountRaw = await _runAndRead('git', ['rev-list', '--count', 'HEAD']);
  final commitCount = int.tryParse((commitCountRaw ?? '').trim()) ?? 1;

  final newVersion = '$baseVersion+$commitCount';
  final updatedPubspec = pubspecContent.replaceFirst(
    _versionLineRegex,
    'version: $newVersion',
  );

  if (updatedPubspec != pubspecContent) {
    await pubspecFile.writeAsString(updatedPubspec);
    stdout.writeln('Updated pubspec version -> $newVersion');
  } else {
    stdout.writeln('pubspec version already set -> $newVersion');
  }

  final flutterArgs = args.isEmpty ? ['build', 'windows', '--release'] : args;
  stdout.writeln('Running: flutter ${flutterArgs.join(' ')}');
  final buildExit = await _runInherit('flutter', flutterArgs);
  exitCode = buildExit;
}

String _normalizeTag(String tag) {
  if (tag.isEmpty) return '';

  var t = tag.toLowerCase();
  if (t.startsWith('v')) {
    t = t.substring(1);
  }

  final numbers = RegExp(r'\d+').allMatches(t).map((m) => m.group(0)!).toList();
  if (numbers.length < 3) return '';
  return '${numbers[0]}.${numbers[1]}.${numbers[2]}';
}

Future<String?> _runAndRead(String executable, List<String> arguments) async {
  try {
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) return null;
    return (result.stdout as String?)?.trim();
  } catch (_) {
    return null;
  }
}

Future<int> _runInherit(String executable, List<String> arguments) async {
  try {
    final process = await Process.start(
      executable,
      arguments,
      mode: ProcessStartMode.inheritStdio,
      runInShell: true,
    );
    return await process.exitCode;
  } catch (e) {
    stderr.writeln('Failed to run $executable: $e');
    return 1;
  }
}
