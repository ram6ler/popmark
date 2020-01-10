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

## Errors

```dart
print('...
```

```text
Error: String starting with ' must end with '.
print('...
      ^^^^
Error: Can't find ')' to match '('.
print('...
     ^
Error: Expected ';' after this.
print('...
      ^^^^
```

