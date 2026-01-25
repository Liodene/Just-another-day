# Code Style Guide

This document defines the coding standards and style guidelines for the Just Another Day Flutter project.

## Table of Contents

- [General Guidelines](#general-guidelines)
- [Dart Style Guidelines](#dart-style-guidelines)
- [Flutter-Specific Guidelines](#flutter-specific-guidelines)
- [Naming Conventions](#naming-conventions)
- [Documentation](#documentation)
- [Error Handling](#error-handling)
- [Code Organization](#code-organization)

## General Guidelines

### Consistency

- Follow the existing code style in the project
- Use `dart format` to automatically format code
- Configure your IDE to format on save
- Run `flutter analyze` before committing

### Code Reviews

All code must:
- Pass linting checks
- Pass all tests
- Be reviewed by at least one other developer
- Follow these style guidelines

## Dart Style Guidelines

### Formatting

Use `dart format` with default settings:

```bash
dart format lib test
```

**Line Length**: 80 characters (default)

```dart
// Good
const String message = 
    'This is a long message that exceeds 80 characters';

// Also good with trailing comma
final widget = Container(
  padding: const EdgeInsets.all(16),
  child: Text('Hello'),
);
```

### Trailing Commas

Always use trailing commas in:
- Function parameters (when breaking across lines)
- Collection literals
- Widget constructors

```dart
// Good: Trailing commas enable better formatting
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('First'),
      Text('Second'),
      Text('Third'),
    ],
  );
}

// Avoid: Missing trailing comma
Widget build(BuildContext context) {
  return Column(
    children: [
      Text('First'),
      Text('Second'),
      Text('Third')
    ]
  );
}
```

### Imports

1. Dart SDK imports
2. Flutter SDK imports
3. Other package imports
4. Local package imports

Separate groups with a blank line:

```dart
// Dart SDK
import 'dart:async';
import 'dart:convert';

// Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// External packages
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// Local package
import 'package:just_another_day/core/constants/api_constants.dart';
import 'package:just_another_day/shared/widgets/custom_button.dart';
```

Prefer relative imports for files within the same feature:

```dart
// Good: Relative import within feature
import 'widgets/counter_display.dart';
import '../models/user.dart';

// Avoid: Package import for local files
import 'package:just_another_day/features/home/widgets/counter_display.dart';
```

### Variables

**Use `final` or `const` whenever possible:**

```dart
// Good
final String name = 'John';
const int maxRetries = 3;

// Avoid
String name = 'John'; // Should be final if not reassigned
```

**Use type inference when the type is obvious:**

```dart
// Good: Type is obvious
final items = <String>[];
final controller = TextEditingController();

// Good: Type is not obvious, so specify it
final ApiService service = locator<ApiService>();

// Avoid: Unnecessary type annotation
final String name = 'John'; // Type is obvious from literal
```

**Use late for deferred initialization:**

```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### Functions

**Keep functions short and focused:**

```dart
// Good: Single responsibility, ~10 lines
void saveUser(User user) {
  validateUser(user);
  final json = user.toJson();
  storage.save('user', json);
}

// Avoid: Too long, multiple responsibilities
void processUserData(User user) {
  // 50+ lines of code doing multiple things
}
```

**Use named parameters for optional parameters:**

```dart
// Good
void createButton({
  required VoidCallback onPressed,
  String? label,
  IconData? icon,
}) {
  // Implementation
}

// Avoid: Positional optional parameters
void createButton(VoidCallback onPressed, [String? label, IconData? icon]) {
  // Implementation
}
```

**Use arrow syntax for simple functions:**

```dart
// Good: Single expression
int square(int x) => x * x;

// Good: Multi-line needs braces
int calculate(int x, int y) {
  final result = x * y;
  return result + 10;
}

// Avoid: Arrow syntax with side effects
void increment() => _counter++;
```

### Collections

**Use collection literals:**

```dart
// Good
final numbers = <int>[];
final names = <String>['Alice', 'Bob'];
final config = <String, dynamic>{'key': 'value'};

// Avoid
final numbers = List<int>();
final names = List<String>.of(['Alice', 'Bob']);
final config = Map<String, dynamic>();
```

**Use spread operators and collection if/for:**

```dart
// Good: Spread operator
final allItems = [...items1, ...items2];

// Good: Collection if
final items = [
  'First',
  if (condition) 'Conditional',
  'Last',
];

// Good: Collection for
final squared = [
  for (var i in numbers) i * i,
];
```

### Null Safety

**Use null-aware operators:**

```dart
// Good
final name = user?.name ?? 'Unknown';
final length = text?.length ?? 0;

// Good: Null-aware assignment
user?.save();
list?.add(item);

// Good: Assertion
void process(String? text) {
  assert(text != null);
  final length = text!.length; // Use ! only when absolutely sure
}
```

**Avoid unnecessary null checks:**

```dart
// Good
if (user != null) {
  print(user.name);
}

// Avoid: Redundant null check
if (user != null && user.name != null) {
  print(user.name); // user.name already non-nullable
}
```

### Async/Await

**Always use async/await for asynchronous code:**

```dart
// Good
Future<User> fetchUser(String id) async {
  final response = await http.get(Uri.parse('/api/user/$id'));
  return User.fromJson(jsonDecode(response.body));
}

// Avoid: Using .then()
Future<User> fetchUser(String id) {
  return http.get(Uri.parse('/api/user/$id')).then((response) {
    return User.fromJson(jsonDecode(response.body));
  });
}
```

**Handle errors properly:**

```dart
// Good
Future<User> fetchUser(String id) async {
  try {
    final response = await http.get(Uri.parse('/api/user/$id'));
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw HttpException('Failed to load user');
    }
  } catch (e) {
    throw UserFetchException('Error fetching user: $e');
  }
}
```

## Flutter-Specific Guidelines

### Widgets

**Use const constructors:**

```dart
// Good
const Text('Hello World')
const SizedBox(height: 16)
const EdgeInsets.all(8)

// Avoid
Text('Hello World')
SizedBox(height: 16)
EdgeInsets.all(8)
```

**Extract widgets for reusability:**

```dart
// Good: Extracted widget
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
      ),
    );
  }
}

// Usage
UserCard(user: currentUser)

// Avoid: Inline complex widgets
Card(
  child: ListTile(
    title: Text(user.name),
    subtitle: Text(user.email),
  ),
)
```

**Prefer StatelessWidget over StatefulWidget:**

```dart
// Good: No state needed
class Welcome extends StatelessWidget {
  const Welcome({super.key, required this.name});
  
  final String name;
  
  @override
  Widget build(BuildContext context) {
    return Text('Welcome, $name!');
  }
}

// Use StatefulWidget only when necessary
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({super.key});
  
  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}
```

### BuildContext

**Don't store BuildContext in State:**

```dart
// Avoid: Storing context
class _MyWidgetState extends State<MyWidget> {
  BuildContext? _context;
  
  @override
  Widget build(BuildContext context) {
    _context = context; // Don't do this
    return Container();
  }
}

// Good: Use context from build or pass it as parameter
class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handlePress(context),
      child: const Text('Press'),
    );
  }
  
  void _handlePress(BuildContext context) {
    Navigator.of(context).pop();
  }
}
```

### Keys

**Use keys for stateful widgets in lists:**

```dart
// Good
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(
      key: ValueKey(items[index].id),
      item: items[index],
    );
  },
)
```

### Themes

**Use theme colors instead of hardcoded values:**

```dart
// Good
Container(
  color: Theme.of(context).colorScheme.primary,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.bodyLarge,
  ),
)

// Avoid
Container(
  color: Colors.blue,
  child: Text(
    'Hello',
    style: TextStyle(fontSize: 16, color: Colors.black),
  ),
)
```

## Naming Conventions

### Classes

**PascalCase for class names:**

```dart
// Good
class HomePage extends StatelessWidget {}
class UserRepository {}
class ApiService {}

// Avoid
class homePage extends StatelessWidget {}
class user_repository {}
class apiservice {}
```

### Variables, Functions, Parameters

**camelCase:**

```dart
// Good
var userName = 'John';
void fetchUserData() {}
final int itemCount = 10;

// Avoid
var UserName = 'John';
void FetchUserData() {}
final int ItemCount = 10;
```

### Constants

**lowerCamelCase for constants:**

```dart
// Good
const int maxRetries = 3;
const String apiBaseUrl = 'https://api.example.com';

// Avoid
const int MAX_RETRIES = 3;
const String API_BASE_URL = 'https://api.example.com';
```

### Private Members

**Prefix with underscore:**

```dart
// Good
class MyClass {
  int _privateField = 0;
  
  void _privateMethod() {}
}

// Public
class MyClass {
  int publicField = 0;
  
  void publicMethod() {}
}
```

### File Names

**snake_case for file names:**

```
// Good
user_profile.dart
api_service.dart
home_page.dart

// Avoid
UserProfile.dart
apiService.dart
HomePage.dart
```

### Boolean Variables

**Use affirmative names:**

```dart
// Good
bool isLoading = true;
bool hasError = false;
bool canSubmit = true;

// Avoid
bool notLoading = false;
bool noError = true;
```

## Documentation

### DartDoc Comments

**Document all public APIs:**

```dart
/// Fetches a user from the API by their unique [id].
///
/// Returns a [User] object if found, throws [UserNotFoundException]
/// if the user doesn't exist.
///
/// Example:
/// ```dart
/// final user = await fetchUser('123');
/// print(user.name);
/// ```
Future<User> fetchUser(String id) async {
  // Implementation
}
```

**Use triple slash for documentation:**

```dart
/// This is a documentation comment
/// that spans multiple lines
class MyClass {}

// This is a regular comment
// not included in documentation
```

**Document parameters and return values:**

```dart
/// Calculates the total price including tax.
///
/// The [basePrice] is the price before tax.
/// The [taxRate] should be a decimal value (e.g., 0.08 for 8%).
///
/// Returns the total price with tax included.
/// Throws [ArgumentError] if [taxRate] is negative.
double calculateTotal(double basePrice, double taxRate) {
  if (taxRate < 0) {
    throw ArgumentError('Tax rate cannot be negative');
  }
  return basePrice * (1 + taxRate);
}
```

## Error Handling

### Custom Exceptions

**Create specific exception types:**

```dart
// Good
class UserNotFoundException implements Exception {
  UserNotFoundException(this.userId);
  
  final String userId;
  
  @override
  String toString() => 'User not found: $userId';
}

class NetworkException implements Exception {
  NetworkException(this.message);
  
  final String message;
  
  @override
  String toString() => 'Network error: $message';
}
```

### Try-Catch

**Handle specific exceptions:**

```dart
// Good
try {
  final user = await fetchUser(id);
  return user;
} on UserNotFoundException catch (e) {
  print('User not found: $e');
  return null;
} on NetworkException catch (e) {
  print('Network error: $e');
  rethrow;
} catch (e) {
  print('Unexpected error: $e');
  rethrow;
}
```

### Assertions

**Use assertions for development checks:**

```dart
// Good
void updateUser(User user) {
  assert(user.id.isNotEmpty, 'User ID cannot be empty');
  assert(user.name.isNotEmpty, 'User name cannot be empty');
  
  // Implementation
}
```

## Code Organization

### File Structure

**One class per file (usually):**

```dart
// user.dart
class User {
  // Implementation
}

// user_repository.dart
class UserRepository {
  // Implementation
}
```

**Group related small classes:**

```dart
// auth_exceptions.dart
class AuthException implements Exception {}
class InvalidCredentialsException extends AuthException {}
class TokenExpiredException extends AuthException {}
```

### Class Members Order

1. Static constants
2. Static variables
3. Instance variables
4. Constructors
5. Lifecycle methods (for StatefulWidget)
6. Public methods
7. Private methods

```dart
class MyClass {
  // 1. Static constants
  static const int maxRetries = 3;
  
  // 2. Static variables
  static int instanceCount = 0;
  
  // 3. Instance variables
  final String name;
  int _counter = 0;
  
  // 4. Constructors
  MyClass(this.name);
  
  // 5. Public methods
  void increment() {
    _counter++;
  }
  
  // 6. Private methods
  void _validate() {
    // Implementation
  }
}
```

## Best Practices Checklist

Before committing code, ensure:

- [ ] Code is formatted with `dart format`
- [ ] No lint warnings from `flutter analyze`
- [ ] All tests pass
- [ ] Public APIs are documented
- [ ] No TODO comments (create issues instead)
- [ ] No commented-out code
- [ ] No print statements (use proper logging)
- [ ] Constants are extracted, no magic numbers
- [ ] Error handling is implemented
- [ ] Resources are properly disposed

## Tools and IDE Setup

### VS Code

Recommended settings:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "dart.lineLength": 80,
  "dart.enableSnippets": true,
  "dart.previewFlutterUiGuides": true,
  "dart.debugExternalLibraries": false,
  "dart.debugSdkLibraries": false
}
```

### Android Studio / IntelliJ

- Enable "Format on save"
- Enable "Optimize imports on save"
- Set line length to 80
- Enable Flutter UI Guides

## References

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Best Practices](https://docs.flutter.dev/testing/best-practices)
