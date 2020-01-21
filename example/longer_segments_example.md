# longer_segments_example.md

## Word cycles

Silly word cycles!

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

