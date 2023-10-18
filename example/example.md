# Example

## Simple code segments

Here are some simple example of popmark in action. This file originally only had the following Dart code segments, and the text segments containing the output of the code were added in by popmark by running:

```sh
dart bin/popmark.dart example/example.md
```

### Segment 1

Here is some embedded Dart code...

```dart
for (var i = 1; i <= 3; i++) {
  print('$i. Hello, world!');
}
```

```text
1. Hello, world!
2. Hello, world!
3. Hello, world!
```

### Segment 2

... and here is some more...

```dart
print('What the heck, world?!');
```

```text
What the heck, world?!
```

### Segment 3

... and here is yet more...

```dart
print('Goodbye, world!');
```

```text
Goodbye, world!
```

### Segment 4

Who doesn't love word cycles?

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

## Imports

The following is a code segment that needs the `dart:math` and `dart:convert` libraries. For this code to run correctly, we will need to set the `--imports` option when calling popmark:

```sh
dart bin/popmark.dart example/example.md \
  --imports 'dart:math as math;dart:convert show json'
```

(Otherwise the error messages will be output in the text segment instead.)

```dart
print(math.pi);
var map = {'a': 1, 'b': 2};
print(json.encode(map));
```

```text
3.141592653589793
{"a":1,"b":2}
```

Alternatively, we could create a template Dart file with `{BODY}` to mark where the code segments should appear, and then direct popmark to that file using:

```sh
--template [name-of-file]
```
