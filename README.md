# `popmark`

Welcome to `popmark`, a simple library that **pop**ulates your **mark**down files with the output of documented code segments.

<!-- comment -->

## Use cases

When writing markdown documents, we often include simple, short code segments as examples. If we find ourselves repeatedly copying code and output to inset onto our documentation 

## Example

Let's say we have the following markdown file saved as `input.md`:

<pre>
# Segment 1

Here is some Dart:

```dart
print('Hello, world!');
```

# Segment 2

And here is some more:

```dart
print('Goodbye, sweet world!');
```
</pre>

We can run the following in the CL:

```text
pub run popmark input.md
```

This will run all the code in `input.md` marked as `dart` and insert the respective output in `pre` tags:

<pre>
# Segment 1

Here is some Dart:

```dart
print('Hello, world!');
```

```text
Hello, world!
```


# Segment 2

And here is some more:

```dart
print('Goodbye, sweet world!');
```

```text
Goodbye, sweet world!
```

</pre>

If the code segments rely on libraries or packages, we can let `popmark` know this using the `-imports` or `-i` option. For example, let's say we want to populate a markdown file containing the following code segment:

<pre>
```dart
print(math.pi);
print(json.encode({'a': 1, 'b': 2}));
```
</pre>

If we try to run `pub run popmark input.md -o output.md` in the command line now, the following output will be inserted in the output markdown file:

<pre>
```text
Error: Getter not found: 'math'.
print(math.pi);
      ^^^^
Error: Getter not found: 'json'.
print(json.encode({'a': 1, 'b': 2}));
      ^^^^
```
</pre>

This is because the code relies on the `dart:math` and `dart:convert` libraries. To let `popmark` know this, we should rather use:

```
pub run popmark input.md -o output.md -i 'dart:math as math;dart:convert show json'
```

Now the output file is populated with the following markdown segment:

<pre>
```text
3.141592653589793
{"a":1,"b":2}
```
</pre>

(Notice the imports are separated by a semicolon.)