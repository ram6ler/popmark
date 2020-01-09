# Imports

Here is some code that relies on the `dart:math` and `dart:json` libraries...

```dart
print(math.pi);
print(json.encode({'a': 1, 'b': 2}));
```

<pre popmark>
Error: Getter not found: 'math'.
print(math.pi);
      ^^^^
Error: Getter not found: 'json'.
print(json.encode({'a': 1, 'b': 2}));
      ^^^^
</pre>

