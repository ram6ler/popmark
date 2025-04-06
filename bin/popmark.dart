import "dart:io";
import "dart:convert" show json;
import "package:args/args.dart";

/// Version number
const version = "0.2.1";

/// Reader states.
enum State { markdown, dart, ignore }

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    showHelp();
    exit(0);
  }

  if (arguments.first == "--version") {
    print("popmark version $version");
    exit(0);
  }

  final
      // The file to read markdown from.
      targetFileName = arguments.first,

      // The results from parsing the arguments.
      results = () {
        try {
          return (ArgParser()
                ..addOption("imports", defaultsTo: "")
                ..addOption("output", defaultsTo: targetFileName)
                ..addOption("template", defaultsTo: "DEFAULT")
                ..addOption("execute", defaultsTo: "ALL")
                ..addFlag("help", abbr: "h", defaultsTo: false)
                ..addFlag("cleanup", defaultsTo: true)
                ..addFlag("strip", defaultsTo: false)
                ..addFlag("time", defaultsTo: false)
                ..addFlag("refresh", defaultsTo: false)
                ..addFlag("cache", defaultsTo: true))
              .parse(arguments);
        } on Exception {
          showHelp();
          exit(0);
        }
      }(),

      // The name of the file to write to.
      outputFileName = results["output"] as String,

      // The template to use for temporary Dart files.
      codeTemplate = (results["template"] as String).toUpperCase() == "DEFAULT"
          ? defaultTemplate
          : await () async {
              final templateFile = results["template"] as String;
              if (await File(templateFile).exists()) {
                return await File(templateFile).readAsString();
              } else {
                print('Cannot find file "$templateFile". '
                    'For help, run: popmark --help');
                exit(0);
              }
            }(),

      // Marker to execute identified segments.
      doExecute = -10,

      // Marker to not execute identified segments.
      doNotExecute = -20,

      // Which code segments to / not to execute.
      executeSegments = () {
        final executeOption = results["execute"] as String;
        if (executeOption.toUpperCase() == "ALL") {
          return <int>[];
        } else {
          final cleanExecuteOptions =
              executeOption.replaceAll(RegExp(r"[^*,;0-9]"), "");

          return <int>[
            cleanExecuteOptions.isNotEmpty && cleanExecuteOptions[0] == "*"
                ? doNotExecute
                : doExecute,
            ...cleanExecuteOptions
                .replaceAll("*", "")
                .replaceAll(" ", "")
                .split(RegExp(r"[,;]"))
                .map((x) => int.tryParse(x)!.abs() - 1)
          ];
        }
      }(),

      // Whether to delete the temporary Dart files afterwards.
      cleanup = results["cleanup"] as bool,

      // Whether to remove the code segment output segments.
      strip = results["strip"] as bool,

      // Whether to show help.
      help = results["help"] as bool,

      // Whether or not to time the execution.
      time = results["time"] as bool,

      // Whether to refresh the cache (delete existing cache).
      refresh = results["refresh"] as bool,

      // Whether to overwrite a cache (write created cache).
      cache = results["cache"] as bool,

      // List of Dart imports the code relies on.
      imports = results["imports"] as String,

      // Import code lines to insert into the template.
      importLines = imports.split(";").map((import) {
        final split = import
                .trim()
                .split(" ")
                .where((token) => token != "import")
                .toList(),
            library = split.first.replaceAll(RegExp("['\"]"), ""),
            line = 'import "$library"';
        return "$line ${split.length > 1 ? split.sublist(1).join(" ") : ""};";
      }).toList(),

      // The match that kicks off code recognition.
      openCode = RegExp(r"^```dart"),

      // The match that ends code recognition.
      closeCode = RegExp(r"^```"),

      // The marker to indicate the start of segment output.
      openCodeOutput = "```text",

      // The match that kicks off ignore.
      openCodeOutputMatch = RegExp(r"^```text"),

      // The marker to indicate the end of segment output and ignore.
      closeCodeOutput = "```";

  if (help) {
    showHelp();
    exit(0);
  }

  if (!(await File(targetFileName).exists())) {
    print('Cannot find file "$targetFileName". For help, run:');
    print("\npopmark --help\n");
    exit(0);
  }

  // The lines of the target file.
  final lines = await File(targetFileName).readAsLines();

  if (await Directory(".popmark").exists()) {
    if (refresh) {
      final oldCache = File(".popmark/cache.json");
      if (await oldCache.exists()) {
        await oldCache.delete();
        print("Cleared the cache...\n");
      }
    }
  } else {
    await Directory(".popmark").create();
    print("Added folder .popmark for popmark cache.");
    print("(You may want add .popmark to .gitignore.)");
  }

  // The cache file.
  final cacheFile = File(".popmark/cache.json");

  var
      // A decode of the json or a new cache map.
      cacheMap = (await cacheFile.exists())
          ? Map.from(json.decode(await cacheFile.readAsString()))
          : <String, Map<String, String>>{},

      // The state of the reader, which determines response to lines.
      state = State.markdown,

      // A buffer for the code to be executed.
      codeBuffer = StringBuffer(),

      // An index tracker for the code segments.
      segmentIndex = 0,

      // Whether to execute the code even if output is cached.
      forceExecution = false,

      // File for temporary Dart code.
      tempFileName = "";

  // A buffer for the final output file's content.
  final contentBuffer = StringBuffer();

  for (final line in lines) {
    switch (state) {
      case State.markdown:
        if (line.contains(openCodeOutputMatch)) {
          state = State.ignore;
        } else {
          if (line.contains(openCode)) {
            forceExecution = line.contains("!");
            state = State.dart;
            contentBuffer.writeln("```dart");
          } else {
            contentBuffer.writeln(line);
          }
        }
      case State.dart:
        contentBuffer.writeln(line);

        // Whether to include the code segment's output.
        final includeSegmentOutput = executeSegments.isEmpty ||
            (executeSegments.first == doExecute &&
                executeSegments.contains(segmentIndex)) ||
            (executeSegments.first == doNotExecute &&
                !executeSegments.contains(segmentIndex));

        if (line.contains(closeCode)) {
          // The code to be executed.
          final codeString = codeBuffer.toString();

          if (includeSegmentOutput &&
              (forceExecution ||
                  !cacheMap.containsKey(codeString) ||
                  (cacheMap[codeString]["out"] as String).isEmpty)) {
            // The name of the temporary Dart file to be executed.
            tempFileName = ".popmark/_temp_popmark$segmentIndex.dart";

            await File(tempFileName).writeAsString(codeTemplate
                .replaceFirst("{IMPORTS}", importLines.join("\n"))
                .replaceFirst("{TIMER_START}", time ? timerStart : "")
                .replaceFirst("{BODY}", codeString)
                .replaceFirst("{TIMER_END}", time ? timerEnd : ""));

            final result = await Process.run("dart", [tempFileName]),
                resultStdout = result.stdout.toString(),
                resultStderr = result.stderr.toString();

            if (cleanup && resultStderr.isEmpty) {
              await File(tempFileName).delete();
            }

            cacheMap[codeString] = {"out": resultStdout, "err": resultStderr};
          }

          if (!strip &&
              includeSegmentOutput &&
              cacheMap.containsKey(codeString)) {
            void insertOutput(String key) => contentBuffer.writeln(
                "\n$openCodeOutput\n${cacheMap[codeString][key]}$closeCodeOutput\n");

            if (cacheMap[codeString]["out"].isNotEmpty) {
              insertOutput("out");
            }
            if (cacheMap[codeString]["err"].isNotEmpty) {
              insertOutput("err");
            }
          }

          codeBuffer.clear();
          state = State.markdown;
          segmentIndex++;
        } else {
          // Include code segments.
          codeBuffer.writeln(line);
        }
      case State.ignore:
        if (line.contains(closeCodeOutput)) {
          state = State.markdown;
        }
    }
  }

  final content =
      contentBuffer.toString().replaceAll(RegExp(r"\n\n\n+"), "\n\n");

  if (cache) {
    await cacheFile.writeAsString(json.encode(cacheMap));
  }
  await File(outputFileName).writeAsString(content);
}

void showHelp() {
  print("""

Welcome to popmark, a simple program that POPulates your MARKdown files
with the output of embedded Dart code segments.

Popmark expects the Dart code segments in the markdown to be wrapped in 
marked code fences, for example:

```dart
print("Hello, world!");
```

It will insert the segment code output after the code segment, wrapped
in fences marked as text, for example:

```text
Hello, world!
```

(Consider wrapping any text you don't want modified in unmarked fences.)

Basic use:

  popmark [file] [options] [flags]

Options:

  --help      Get help (i.e. see this information).

  --version   Output the current version.

  --execute   Identify which code segments to (or not to) execute. For 
              example, to only execute the 1st and the 3rd code segment, use:

                    popmark target.md --execute 1,3

              To execute all segments except for the 1st and 3rd segment,
              use an asterisk:

                    popmark target.md --execute *1,3

  --output    By default, popmark writes directly to the target file. To 
              specify a different file to write to, set the output file:

                    popmark target.md --output out.md

  --imports   Specify any libraries or packages the documented code relies
              on, separated by semi-colons. For example:

                    popmark target.md --imports 'dart:io;dart:math'

  --template  Specify the path to the template Dart code to use. For example,
              template.txt might contains Dart code with the text {BODY} to
              indicate where the documented code segment should be inserted;
              then to use template.txt as a template, run:

                    popmark target.md --template template.txt

Flags:

  --cleanup   By default, popmark cleans up after itself. Specify whether to
              delete the Dart files popmark runs in the background using:

                    popmark target.md --no-cleanup
  
  --refresh   Execute all segments, whether or not their results are cached.
  
  --cache     By default, popmark saves code segment results in a cache (in
              .popmark). Use --no-cache to prevent this behavior. (Using
              --refresh and --no-cache together thus deleted the current cache.)

  --strip     Strip all code segment output.

  --time      Include the execution time in the output.


Thanks for your interest!
Log any issues at https://github.com/ram6ler/popmark/issues.

""");
}

const defaultTemplate = r"""
// Generated by popmark.

{IMPORTS}

main() async {
{TIMER_START}  
{BODY}
{TIMER_END}
  
}
""",
    timerStart = r"""
  final _stopwatch = Stopwatch()..start();
""",
    timerEnd = r"""
  _stopwatch.stop();
  print("\n[${_stopwatch.elapsedMicroseconds} μs]");
""";
