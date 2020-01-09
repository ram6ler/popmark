import 'dart:io';
import 'package:args/args.dart';

/// Reader states.
enum State { markdown, dart, ignore }

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    showHelp();
  } else {
    final targetFile = arguments.first,
        parser = ArgParser()
          ..addOption('imports', abbr: 'i')
          ..addOption('output', abbr: 'o', defaultsTo: targetFile)
          ..addFlag('help', abbr: 'h', defaultsTo: false)
          ..addFlag('cleanup', abbr: 'c', defaultsTo: true)
          ..addFlag('strip', abbr: 's', defaultsTo: false),
        results = parser.parse(arguments),

        /// The name of the file to write to.
        output = results['output'] as String,
        // Whether to delete the temporary Dart files afterwards.
        cleanup = results['cleanup'] as bool,
        // Whether to remove the code segment output segments.
        strip = results['strip'] as bool,
        // Whether to show help.
        help = results['help'] as bool,
        // List of Dart imports the code relies on.
        imports = results['imports'] as String,
        importLines = imports == null
            ? <String>[]
            : imports.split(';').map((import) {
                final split = import
                        .trim()
                        .split(' ')
                        .where((token) => token != 'import')
                        .toList(),
                    library = split.first.replaceAll(RegExp('[\'"]'), ''),
                    line = "import '$library'";
                return '$line ${split.length > 1 ? split.sublist(1).join(' ') : ''};';
              }).toList(),
        // The match that kicks off code recognition.
        openCode = RegExp(r'^```dart'),
        // The match that ends code recognition.
        closeCode = RegExp(r'^```'),
        // The marker to indicate the start of segment output.
        openPopmark = '<pre popmark>',
        // The match that kicks off ignore.
        openPopmarkMatch = RegExp(r'^<pre popmark>'),
        // The marker to indicate the end of segment output and ignore.
        closePopmark = '</pre>';

    if (help || !(await File(targetFile).exists())) {
      showHelp();
      exit(0);
    }

    // The lines of the target file.
    final lines = (await File(targetFile).readAsString())
        .replaceAll(RegExp(r'\n\n+'), '\n\n')
        .split('\n');

    var
        // The state of the reader, which determines response to lines.
        state = State.markdown,
        // A buffer for the code to be executed.
        code = StringBuffer(),
        // An index tracker for the code segments.
        index = 0;

    final sink = File(output).openWrite();
    for (final line in lines) {
      switch (state) {
        case State.markdown:
          if (line.contains(openPopmarkMatch)) {
            state = State.ignore;
          } else {
            sink.writeln(line);
            if (line.contains(openCode)) {
              state = State.dart;
            }
          }
          break;
        case State.dart:
          if (line.contains(openPopmarkMatch)) {
            state = State.ignore;
          } else {
            sink.writeln(line);
            if (line.contains(closeCode)) {
              final dartFile = '_temp_popmark$index.dart';
              index++;
              await File(dartFile).writeAsString(template
                  .replaceFirst('{IMPORTS}', importLines.join('\n'))
                  .replaceFirst('{BODY}', code.toString()));
              index++;
              final result = await Process.run('dart', [dartFile]);
              if (!strip) {
                final resultStdout = result.stdout.toString(),
                    output = resultStdout.isNotEmpty
                        ? resultStdout
                        : result.stderr
                            .toString()
                            .split('\n')
                            .map((line) => line.contains('_temp_popmark')
                                ? line.split(' ').sublist(1).join(' ')
                                : line)
                            .join('\n');

                sink.writeln('\n$openPopmark\n$output$closePopmark\n');
              }

              if (cleanup || result.stderr.toString().isNotEmpty) {
                await File(dartFile).delete();
              } else {
                final cleanCode =
                    (await Process.run('dartfmt', [dartFile])).stdout as String;
                await File(dartFile).writeAsString(cleanCode);
              }

              code.clear();
              state = State.markdown;
            } else {
              code.writeln(line);
            }
          }
          break;
        case State.ignore:
          if (line.contains(closePopmark)) {
            state = State.markdown;
          }
          break;
      }
    }
    await sink.flush();
    await sink.close();
  }
}

void showHelp() {
  print('''

Welcome to popmark, a simple program that POPulates your MARKdown files
with the output of your documented Dart code!

Basic use:

  pub run popmark [file] [options] [flags]

Options:

  --help      -h    Shows this help.

                    Example:
                    pub run popmark -h

  --output    -o    Specifies the file to write to. If not set, popmark 
                    writes to the target file.

                    Example:
                    pub run popmark target.md -o out.md

  --imports   -i    Specifies any libraries or packages the documented 
                    code relies on, separated by semi-colons.

                    Example:
                    pub run popmark target.md -i 'dart:math'

Flags:

  --cleanup   -c    Specifies whether to delete the Dart files run in 
                    the background (popmark cleans up by default).

                    Example:
                    pub run popmark target.md --no-cleanup

  --strip     -s    Specifies whether to remove the program segment output.

                    Example:
                    pub run popmark target.md -s

For more information, check out the wiki at ...

''');
}

final template = '''
// Generated by popmark.

{IMPORTS}

void main() {
{BODY}
}
''';
