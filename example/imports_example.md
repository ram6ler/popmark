# imports_example.md

Here is a code segment that needs the `dart:math` and `dart:convert` libraries. We can let popmark know this using the `imports` option, as follows.

```sh
--imports 'dart:math as math;dart:convert show json'
```

(Packages available in the environment may also be included.)

```dart
print(math.pi);
var map = {'a': 1, 'b': 2};
print(json.encode(map));
```

```text
3.141592653589793
{"a":1,"b":2}
```

