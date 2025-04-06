# `popmark` tests

## Basic segment output

```dart
String spaces(int n) => ' ' * n;
final message = 'Hello, popmark!';
for (var i = 0; i < message.length; i++) {
    print(spaces(((i % 6) - 3).abs()) + message[i]); 
}
```

```text
   H
  e
 l
l
 o
  ,
    
  p
 o
p
 m
  a
   r
  k
 !
```

## Requires a library

The following snippet needs popmark to be called using:

```sh
popmark test/popmark_test.md --imports 'dart:math show Random, pi, sqrt, pow'
```

```dart
const simulations = 10_000;
final rand = Random();
var successes = 0;

for (var _ = 0; _ < simulations; _++) {
    final x = (rand.nextDouble() - 0.5) * 2, y = (rand.nextDouble() - 0.5) * 2;
    if (sqrt(pow(x, 2) + pow(y, 2)) < 1) successes++;
}

final estimate = successes / simulations * 4;
print("π ≈ ${estimate}");
print("ε = ${(estimate - pi).abs()}");
```

```text
π ≈ 3.1228
ε = 0.018792653589793318
```

## Errors

```dart
print('...
```

```text
.popmark/_temp_popmark2.dart:7:7: Error: String starting with ' must end with '.
print('...
      ^^^^
.popmark/_temp_popmark2.dart:7:6: Error: Can't find ')' to match '('.
print('...
     ^
.popmark/_temp_popmark2.dart:7:7: Error: Expected ';' after this.
print('...
      ^^^^
```

