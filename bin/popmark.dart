import 'dart:io';
import 'package:args/args.dart';

/// Reader states.
enum State { markdown, dart, ignore }

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    showHelp();
    exit(0);
  } else {
    final targetFile = arguments.first,
        results = () {
      try {
        return (ArgParser()
              ..addOption('imports', abbr: 'i')
              ..addOption('output', abbr: 'o', defaultsTo: targetFile)
              ..addOption('template', abbr: 't', defaultsTo: 'DEFAULT')
              ..addOption('execute', abbr: 'e', defaultsTo: 'ALL')
              ..addFlag('help', abbr: 'h', defaultsTo: false)
              ..addFlag('cleanup', abbr: 'c', defaultsTo: true)
              ..addFlag('strip', abbr: 's', defaultsTo: false)
              ..addFlag('time', defaultsTo: false))
            .parse(arguments);
      } on Exception {
        showHelp();
        exit(0);
      }
      return null;
    }(),

        // The name of the file to write to.
        output = results['output'] as String,

        // The template to use for temporary Dart files.
        template = (results['template'] as String).toUpperCase() == 'DEFAULT'
            ? defaultTemplate
            : await () async {
                final templateFile = results['template'] as String;
                if (await File(templateFile).exists()) {
                  return await File(templateFile).readAsString();
                } else {
                  print(
                      'Cannot find file "$templateFile". For help, run: popmark --help');
                  exit(0);
                }
                return null;
              }(),

        // Which code segments to / not to execute.
        doExecute = -10,
        doNotExecute = -20,
        executeSegments = () {
      final executeOption = results['execute'] as String;
      if (executeOption.toUpperCase() == 'ALL') {
        return null;
      } else {
        final cleanExecuteOptions =
            executeOption.replaceAll(RegExp(r'[^*,;0-9]'), '');

        return <int>[
          cleanExecuteOptions.isNotEmpty && cleanExecuteOptions[0] == '*'
              ? doNotExecute
              : doExecute,
          ...cleanExecuteOptions
              .replaceAll('*', '')
              .split(RegExp(r'[,;]'))
              .map((x) => int.tryParse(x).abs() - 1)
        ];
      }
    }(),

        // Whether to delete the temporary Dart files afterwards.
        cleanup = results['cleanup'] as bool,

        // Whether to remove the code segment output segments.
        strip = results['strip'] as bool,

        // Whether to show help.
        help = results['help'] as bool,

        // Whether or not to time the execution.
        time = results['time'] as bool,

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
        openPopmark = '```text',

        // The match that kicks off ignore.
        openPopmarkMatch = RegExp(r'^```text'),

        // The marker to indicate the end of segment output and ignore.
        closePopmark = '```';

    if (help) {
      showHelp();
      exit(0);
    }

    if (!(await File(targetFile).exists())) {
      print('Cannot find file "$targetFile". For help, run: popmark --help');
      exit(0);
    }

    // The lines of the target file.
    final lines = await File(targetFile).readAsLines();

    //
    final tempDirectory = await Directory('.popmark').create();

    var
        // The state of the reader, which determines response to lines.
        state = State.markdown,

        // A buffer for the code to be executed.
        code = StringBuffer(),

        // An index tracker for the code segments.
        segmentIndex = 0;

    final contentBuffer = StringBuffer();
    for (final line in lines) {
      switch (state) {
        case State.markdown:
          // Include markdown in the output.
          if (line.contains(openPopmarkMatch)) {
            state = State.ignore;
          } else {
            contentBuffer.writeln(line);

            if (line.contains(openCode)) {
              state = State.dart;
            }
          }
          break;
        case State.dart:
          contentBuffer.writeln(line);

          if (line.contains(closeCode)) {
            // Execute the code segment and insert its output.
            if (executeSegments == null ||
                (executeSegments.first == doExecute &&
                    executeSegments.contains(segmentIndex)) ||
                (executeSegments.first == doNotExecute &&
                    !executeSegments.contains(segmentIndex))) {
              final tempFileName = '.popmark/_temp_popmark$segmentIndex.dart';

              await File(tempFileName).writeAsString(template
                  .replaceFirst('{IMPORTS}', importLines.join('\n'))
                  .replaceFirst('{TIMER_START}', time ? timerStart : '')
                  .replaceFirst('{BODY}', code.toString())
                  .replaceFirst('{TIMER_END}', time ? timerEnd : ''));

              final result = await Process.run('dart', [tempFileName]);

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

                contentBuffer.writeln('\n$openPopmark\n$output$closePopmark\n');
              }

              /*if (cleanup) {
                await File(tempFileName).delete();
              } else {
                final cleanCode =
                    (await Process.run('dartfmt', [tempFileName])).stdout as String;
                await File(tempFileName).writeAsString(cleanCode);
              }*/
            }

            code.clear();
            state = State.markdown;
            segmentIndex++;
          } else {
            // Include code segments.
            code.writeln(line);
          }
          break;
        case State.ignore:
          if (line.contains(closePopmark)) {
            state = State.markdown;
          }
          break;
      }
    }

    final content =
        contentBuffer.toString().replaceAll(RegExp(r'\n\n\n+'), '\n\n');

    await File(output).writeAsString(content);

    if (cleanup) {
      await tempDirectory.delete(recursive: true);
    }
  }
}

void showHelp() {
  print('''

Welcome to popmark, a simple program that POPulates your MARKdown files
with the output of your documented Dart code!

Popmark expects the Dart code segments in the markdown to be wrapped in 
marked code fences, for example:

```dart
print('Hello, world!');
```

It will insert the segment code output after the code segment, wrapped
in fences marked as text, for example:

```text
Hello, world!
```

Basic use:

  popmark [file] [options] [flags]

Options:

  --execute   -e    Identifies which code segments to or not to execute.
                    For example, to only execute the 1st and the 3rd
                    code segment, use:

                    popmark target.md -e 1,3

                    To execute all segments except for the 1st and 3rd
                    segment, use an asterisk:

                    popmark target.md -e *1,3

  --help      -h    To get help (i.e. see this information), use:

                    popmark -h

  --output    -o    By default, popmark writes to the target file. To 
                    specify the file to write to, set the output file:

                    popmark target.md -o out.md

  --imports   -i    Specify any libraries or packages the documented 
                    code relies on, separated by semi-colons:

                    popmark target.md -i 'dart:io;dart:math'

  --template  -t    Specify the path to the template Dart code to use.
                    For example, if template.txt contains Dart code with
                    the text {BODY} to indicate where the documented code
                    should be inserted, we could use it as a template:

                    popmark target.md -t template.txt

Flags:

  --cleanup   -c    By default, popmark cleans up after itself. Specify 
                    whether to delete the Dart files popmark runs in the 
                    background using:

                    popmark target.md --no-cleanup

  --strip     -s    Strip all code segment output:

                    popmark target.md -s

  --time            Include the execution time in the output.

                    popmark target.md --time


For more information, check out the wiki at ...

''');
}

final defaultTemplate = r'''
// Generated by popmark.

{IMPORTS}

main() async {
{TIMER_START}  
{BODY}
{TIMER_END}
  
}
''',
    timerStart = r'''
  final _stopwatch = Stopwatch();
  _stopwatch.start();
''',
    timerEnd = r'''
  _stopwatch.stop();
  print('\n[${_stopwatch.elapsedMicroseconds} μs]');
''';
