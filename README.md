# popmark

Welcome to `popmark`, a simple library that **pop**ulates your **mark**down files with the output of embedded Dart code segments. This can be helpful if you want to check that the code segments in your readme and other markdown files are working correctly.

## Basic use

To populate our markdown with the output of embedded code segments, we can run:

```sh
dart run popmark [target-markdown-file]
```

This gets popmark to search through the file for code segments marked `dart`, execute those segments, and poplate the markdown file with `text` blocks containing the respective segment output.

For example, the output of the following Dart code segment was added by running `dart run popmark README.md`:

```dart
final message = 'spamtapaalesrest', cycle = 4;
for (var i = 0; i < cycle; i++) {
    final buffer = StringBuffer('  ' * i);
    for (var j = i; j < message.length; j += cycle) {
        buffer.write(' ' * cycle + message[j]);
    }
    print(buffer);
}
```

```text
    s    t    a    r
      p    a    l    e
        a    p    e    s
          m    a    s    t
```

## Summary and options

Basic use:

```sh
dart run popmark [file] [options] [flags]
```

### `--help`

Get help.

### `--execute`

Use `--execute` to identify which code segments to (or not to) execute. For  example, to only execute the 1st and the 3rd code segment, use:

```sh
dart run popmark target.md --execute '1,3'
```

To execute all segments except for the 1st and 3rd segment, use an asterisk:

```sh
dart run popmark target.md --execute '*1,3'
```

### `--output`

By default, popmark writes directly to the target file. To specify a different file to write to, set the output file:

```sh
dart run popmark target.md --output out.md
```

### `--imports`

Specify any libraries or packages the documented code relies on, separated by semi-colons. For example:

```sh
dart run popmark target.md --imports 'dart:io;dart:math'
```

### `--template`

Specify the path to a template Dart file to use. For example, `template.txt` might contains Dart code with the text `{BODY}` to indicate where the documented code segment should be inserted; then to use `template.txt` as a template, run:

```sh
dart run popmark target.md --template template.txt
```

### `--cleanup`

By default, popmark cleans up after itself by deleting background scripts that it created and used to generate the output. If you don't want this, you can use `--no-cleanup`, in which case these generated files can be found in `.popmark`.

```sh
dart run popmark target.md --no-cleanup
```

### `--cache`

By default, popmark saves the output from code segments to a cache (in `.popmark`) so that output does not need to be regenerated in future runs. Execute all segments, whether or not their results are cached. If you don't want this, you can use ```--no-cache```.

### `--refresh`

Use `--refresh` to execute all code segments and insert their results, whether or not the results are stored in the cache.

### `--strip`

Use `--strip` to remove Dart code segment output from a markdown file.

### `--time`

Include the execution time for each code segment in the output.

## Miscellaneous

* Be sure to save the target file before you unleash popmark on it.

* You might want to add `.popmark`, where popmark stores its cache and any generated temporary Dart files, to your `.gitignore` file.

* popmark overwrites any blocks marked `text` (which it reserves for the output  from Dart code segments). Consider using more specific tags or unmarked blocks for text you do not want modified.

* If the implementation of the embedded code changes between runs, clear the cache (or mark segments `dart!`) to force the segments to be executed.

## Thanks

Thanks for your interest in this project. Please [file any issues here](https://github.com/ram6ler/popmark/issues).
