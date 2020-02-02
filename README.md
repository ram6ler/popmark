# popmark

Welcome to `popmark`, a simple library that **pop**ulates your **mark**down files with the output of embedded Dart code segments.


## Basic use

To populate our markdown with the output of embedded code segments, we can run:

```
popmark [target-markdown-file]
```

This gets popmark to search through the file for code segments marked `dart`, execute those segments, and poplate the markdown file with `text` blocks containing the respective segment output.

(We can use `--strip` to remove all code output blocks.)

For example:

![](https://bytebucket.org/ram6ler/popmark/wiki/code_segments.gif)

## Using libraries and packages

We can use `--imports` to specify libraries or packages the code segments rely on.

For example:

![](https://bytebucket.org/ram6ler/popmark/wiki/imports.gif)

Alternatively, we can specify a Dart template file, with necessary imports, using `--template`. See `--help` for details.

## Cache

popmark stores a json cache in a folder `.popmark` (which we may want to tell our repo to ignore). 

We can force popmark to execute code, whether or not it is cached, using `--refresh`. (We can also force individual code segments to be executed by wrapping them in code blocks marked `dart!` instead of `dart`.)

We can stop popmark from saving a cache, or making changes to an existing cache, using `--no-cache`.

(We can thus delete the cache by using both `--refresh` and `--no-cache`, or, of course, by simply running `rm -rf .popmark`.)

## Miscellaneous

* Be sure to save the target file before you unleash popmark on it.
* popmark overwrites any blocks marked `text`... consider using unmarked blocks for text you do not want modified.
*  Use `--output output.md` to create a new file rather than overwriting the target.
*  If the implementation of the embedded code changes between runs, clear the cache (or mark segments `dart!`) to force the segments to be executed.

## Thanks!

Thanks for your interest in this project. Please [file any issues here](https://github.com/ram6ler/popmark/issues).
