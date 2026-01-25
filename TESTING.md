# Testing Guide

This document outlines testing strategies, best practices, and guidelines for the Just Another Day Flutter project.

## Table of Contents

- [Testing Philosophy](#testing-philosophy)
- [Types of Tests](#types-of-tests)
- [Running Tests](#running-tests)
- [Unit Testing](#unit-testing)
- [Widget Testing](#widget-testing)
- [Integration Testing](#integration-testing)
- [Test Coverage](#test-coverage)
- [Mocking and Stubbing](#mocking-and-stubbing)
- [Best Practices](#best-practices)

## Testing Philosophy

### Why We Test

- **Confidence**: Tests give us confidence that our code works as expected
- **Documentation**: Tests document how code should be used
- **Refactoring**: Tests enable safe refactoring
- **Quality**: Tests improve code quality by encouraging better design
- **Regression Prevention**: Tests prevent bugs from reappearing

### Testing Pyramid

Follow the testing pyramid strategy:

```
        /\
       /  \      Integration Tests (Few)
      /    \     - Test complete user flows
     /------\    - Expensive and slow
    /        \
   /  Widget  \  Widget Tests (Some)
  /   Tests    \ - Test individual widgets
 /              \- Medium speed
/----------------\
/   Unit Tests    \ Unit Tests (Many)
/                  \- Test business logic
/--------------------\- Fast and cheap
```

**Test Distribution:**
- 70% Unit Tests
- 20% Widget Tests
- 10% Integration Tests

## Types of Tests

### Unit Tests

Test individual functions, methods, and classes in isolation.

**Location**: `test/unit/`

**Use for:**
- Business logic
- Utility functions
- Data models
- Services and repositories

### Widget Tests

Test individual widgets and their interactions.

**Location**: `test/widget/`

**Use for:**
- Widget rendering
- User interactions
- Widget state changes
- UI composition

### Integration Tests

Test complete user flows and app behavior.

**Location**: `integration_test/`

**Use for:**
- End-to-end user flows
- Multiple screens/features working together
- Real device/browser testing

## Running Tests

### All Tests

```bash
# Run all unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/utils_test.dart
```

### Integration Tests

```bash
# Run integration tests in Chrome
flutter test integration_test/app_test.dart -d chrome
```

### Watch Mode

```bash
# Run tests in watch mode (re-run on file changes)
flutter test --watch
```

### Verbose Output

```bash
# Show detailed output
flutter test --verbose
```

## Unit Testing

### Basic Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/core/utils/validators.dart';

void main() {
  group('EmailValidator', () {
    test('returns true for valid email', () {
      // Arrange
      const email = 'test@example.com';
      
      // Act
      final result = EmailValidator.isValid(email);
      
      // Assert
      expect(result, isTrue);
    });
    
    test('returns false for invalid email', () {
      // Arrange
      const email = 'invalid-email';
      
      // Act
      final result = EmailValidator.isValid(email);
      
      // Assert
      expect(result, isFalse);
    });
  });
}
```

### Testing Classes

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/features/counter/models/counter.dart';

void main() {
  group('Counter', () {
    late Counter counter;
    
    setUp(() {
      // Runs before each test
      counter = Counter();
    });
    
    tearDown(() {
      // Runs after each test (if needed)
      // Clean up resources
    });
    
    test('initial value is 0', () {
      expect(counter.value, 0);
    });
    
    test('increment increases value by 1', () {
      counter.increment();
      expect(counter.value, 1);
    });
    
    test('multiple increments work correctly', () {
      counter.increment();
      counter.increment();
      counter.increment();
      expect(counter.value, 3);
    });
    
    test('decrement decreases value by 1', () {
      counter.increment();
      counter.increment();
      counter.decrement();
      expect(counter.value, 1);
    });
    
    test('reset sets value to 0', () {
      counter.increment();
      counter.increment();
      counter.reset();
      expect(counter.value, 0);
    });
  });
}
```

### Testing Async Functions

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('fetchUser returns user when successful', () async {
      // Arrange
      final apiService = ApiService();
      
      // Act
      final user = await apiService.fetchUser('123');
      
      // Assert
      expect(user, isNotNull);
      expect(user.id, '123');
    });
    
    test('fetchUser throws exception when user not found', () async {
      // Arrange
      final apiService = ApiService();
      
      // Act & Assert
      expect(
        () => apiService.fetchUser('invalid'),
        throwsA(isA<UserNotFoundException>()),
      );
    });
  });
}
```

### Testing Exceptions

```dart
test('throws ArgumentError for negative values', () {
  expect(
    () => calculateDiscount(-10),
    throwsA(isA<ArgumentError>()),
  );
});

test('throws specific exception with message', () {
  expect(
    () => processPayment(-100),
    throwsA(
      predicate(
        (e) => e is PaymentException && e.message.contains('negative'),
      ),
    ),
  );
});
```

## Widget Testing

### Basic Widget Test

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_another_day/features/home/widgets/counter_display.dart';

void main() {
  group('CounterDisplay', () {
    testWidgets('displays counter value', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterDisplay(value: 5),
          ),
        ),
      );
      
      // Assert
      expect(find.text('5'), findsOneWidget);
    });
    
    testWidgets('displays zero when value is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CounterDisplay(value: 0),
          ),
        ),
      );
      
      expect(find.text('0'), findsOneWidget);
    });
  });
}
```

### Testing User Interactions

```dart
testWidgets('button press increments counter', (tester) async {
  // Arrange
  await tester.pumpWidget(const MyApp());
  
  // Verify initial state
  expect(find.text('0'), findsOneWidget);
  expect(find.text('1'), findsNothing);
  
  // Act - tap the button
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump(); // Rebuild widget after state change
  
  // Assert
  expect(find.text('0'), findsNothing);
  expect(find.text('1'), findsOneWidget);
});
```

### Testing Animations

```dart
testWidgets('animation completes correctly', (tester) async {
  // Arrange
  await tester.pumpWidget(const AnimatedWidget());
  
  // Start animation
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump(); // Start animation
  
  // Check intermediate state
  await tester.pump(const Duration(milliseconds: 500));
  // Verify animation is in progress
  
  // Complete animation
  await tester.pumpAndSettle(); // Wait for all animations to complete
  
  // Assert final state
  expect(find.text('Animation Complete'), findsOneWidget);
});
```

### Finding Widgets

```dart
// By type
find.byType(FloatingActionButton)

// By text
find.text('Hello World')

// By key
find.byKey(const Key('my-key'))

// By icon
find.byIcon(Icons.add)

// By widget instance
find.byWidget(const Text('Exact widget'))

// Descendant
find.descendant(
  of: find.byType(AppBar),
  matching: find.text('Title'),
)
```

### Verifying Widget Properties

```dart
testWidgets('button has correct properties', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  final button = tester.widget<ElevatedButton>(
    find.byType(ElevatedButton),
  );
  
  expect(button.onPressed, isNotNull);
  
  final text = tester.widget<Text>(
    find.descendant(
      of: find.byType(ElevatedButton),
      matching: find.byType(Text),
    ),
  );
  
  expect(text.data, 'Click Me');
});
```

### Testing Forms

```dart
testWidgets('form validation works', (tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Find text field
  final emailField = find.byKey(const Key('email-field'));
  
  // Enter invalid email
  await tester.enterText(emailField, 'invalid');
  await tester.pump();
  
  // Try to submit
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  // Verify error message
  expect(find.text('Invalid email'), findsOneWidget);
  
  // Enter valid email
  await tester.enterText(emailField, 'test@example.com');
  await tester.pump();
  
  // Submit again
  await tester.tap(find.byType(ElevatedButton));
  await tester.pump();
  
  // Verify no error
  expect(find.text('Invalid email'), findsNothing);
});
```

## Integration Testing

### Setup

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

### Basic Integration Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_another_day/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('end-to-end test', () {
    testWidgets('complete user flow', (tester) async {
      // Start app
      app.main();
      await tester.pumpAndSettle();
      
      // Verify home screen
      expect(find.text('Just Another Day'), findsOneWidget);
      
      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      
      // Verify profile screen
      expect(find.text('Profile'), findsOneWidget);
      
      // Perform actions
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      
      // Verify result
      expect(find.text('Edit Profile'), findsOneWidget);
    });
  });
}
```

## Test Coverage

### Generate Coverage Report

```bash
# Generate coverage data
flutter test --coverage

# View coverage (requires lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Coverage Goals

- **Overall**: >= 80%
- **Critical paths**: 100%
- **Business logic**: >= 90%
- **UI code**: >= 70%

### Excluding Files from Coverage

```dart
// coverage:ignore-file
```

Or specific lines:

```dart
// coverage:ignore-start
void debugOnlyFunction() {
  print('Debug info');
}
// coverage:ignore-end
```

## Mocking and Stubbing

### Using Mockito

Add to `pubspec.yaml`:

```yaml
dev_dependencies:
  mockito: ^5.4.0
  build_runner: ^2.4.0
```

### Creating Mocks

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:just_another_day/services/user_repository.dart';

// Generate mocks with build_runner
@GenerateMocks([UserRepository])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService', () {
    late MockUserRepository mockRepository;
    late UserService userService;
    
    setUp(() {
      mockRepository = MockUserRepository();
      userService = UserService(mockRepository);
    });
    
    test('getUser returns user from repository', () async {
      // Arrange
      final user = User(id: '1', name: 'John');
      when(mockRepository.getUser('1'))
          .thenAnswer((_) async => user);
      
      // Act
      final result = await userService.getUser('1');
      
      // Assert
      expect(result, user);
      verify(mockRepository.getUser('1')).called(1);
    });
    
    test('getUser throws exception when user not found', () async {
      // Arrange
      when(mockRepository.getUser('999'))
          .thenThrow(UserNotFoundException('999'));
      
      // Act & Assert
      expect(
        () => userService.getUser('999'),
        throwsA(isA<UserNotFoundException>()),
      );
    });
  });
}
```

### Verifying Interactions

```dart
// Verify method was called
verify(mock.someMethod()).called(1);

// Verify method was never called
verifyNever(mock.someMethod());

// Verify method was called with specific arguments
verify(mock.someMethod('specific-arg')).called(1);

// Verify call order
verifyInOrder([
  mock.firstMethod(),
  mock.secondMethod(),
]);
```

## Best Practices

### Test Organization

**Use descriptive test names:**

```dart
// Good
test('returns true when email contains @ symbol', () {});
test('throws ArgumentError when input is negative', () {});

// Avoid
test('test1', () {});
test('email validation', () {});
```

**Group related tests:**

```dart
group('EmailValidator', () {
  group('isValid', () {
    test('returns true for valid email', () {});
    test('returns false for invalid email', () {});
    test('handles null input', () {});
  });
  
  group('normalize', () {
    test('converts to lowercase', () {});
    test('trims whitespace', () {});
  });
});
```

### AAA Pattern

Follow Arrange-Act-Assert pattern:

```dart
test('adds two numbers correctly', () {
  // Arrange - Set up test data
  final calculator = Calculator();
  const a = 5;
  const b = 3;
  
  // Act - Execute the code being tested
  final result = calculator.add(a, b);
  
  // Assert - Verify the result
  expect(result, 8);
});
```

### Test Independence

Each test should be independent:

```dart
// Good - Each test is independent
group('Counter', () {
  test('increment works', () {
    final counter = Counter();
    counter.increment();
    expect(counter.value, 1);
  });
  
  test('decrement works', () {
    final counter = Counter();
    counter.increment();
    counter.decrement();
    expect(counter.value, 0);
  });
});

// Avoid - Tests depend on each other
late Counter counter;
test('increment works', () {
  counter = Counter();
  counter.increment();
  expect(counter.value, 1);
});
test('decrement works', () {
  counter.decrement(); // Depends on previous test
  expect(counter.value, 0);
});
```

### Test Data

**Use meaningful test data:**

```dart
// Good
final user = User(
  id: 'test-user-123',
  name: 'John Doe',
  email: 'john.doe@example.com',
);

// Avoid
final user = User(id: '1', name: 'x', email: 'a@b.c');
```

### Don't Test Implementation Details

```dart
// Good - Test behavior
test('user list displays all users', () {
  final users = [User(name: 'Alice'), User(name: 'Bob')];
  final widget = UserList(users: users);
  
  expect(widget.build(context), contains(Text('Alice')));
  expect(widget.build(context), contains(Text('Bob')));
});

// Avoid - Testing implementation
test('user list uses ListView.builder', () {
  final widget = UserList(users: []);
  
  expect(widget.build(context), isA<ListView>());
});
```

### Keep Tests Fast

- Mock external dependencies
- Avoid real network calls
- Use in-memory databases
- Minimize file I/O

### Test Edge Cases

```dart
group('divide', () {
  test('divides positive numbers', () {
    expect(divide(10, 2), 5);
  });
  
  test('divides negative numbers', () {
    expect(divide(-10, 2), -5);
  });
  
  test('handles zero dividend', () {
    expect(divide(0, 5), 0);
  });
  
  test('throws exception for zero divisor', () {
    expect(() => divide(10, 0), throwsA(isA<DivisionByZeroException>()));
  });
});
```

## Common Matchers

```dart
// Equality
expect(value, equals(expected));
expect(value, expected); // Short form

// Type checking
expect(value, isA<String>());
expect(value, isNotNull);
expect(value, isNull);

// Numerical
expect(value, greaterThan(5));
expect(value, lessThan(10));
expect(value, greaterThanOrEqualTo(5));
expect(value, inInclusiveRange(0, 10));

// Strings
expect(value, contains('substring'));
expect(value, startsWith('prefix'));
expect(value, endsWith('suffix'));
expect(value, matches(RegExp(r'\d+')));

// Collections
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(3));
expect(list, contains(item));
expect(list, containsAll([item1, item2]));

// Async
expect(future, completion(equals(value)));
expect(future, throwsA(isA<Exception>()));

// Widgets
expect(find.text('Hello'), findsOneWidget);
expect(find.text('Hello'), findsNothing);
expect(find.text('Hello'), findsNWidgets(3));
```

## Debugging Tests

### Print Statements

```dart
test('debug test', () {
  final value = calculate();
  print('Calculated value: $value'); // Will show in test output
  expect(value, 42);
});
```

### Debug Widget Tree

```dart
testWidgets('debug widget tree', (tester) async {
  await tester.pumpWidget(const MyWidget());
  
  // Print widget tree
  debugDumpApp();
  
  // Print render tree
  debugDumpRenderTree();
});
```

## Continuous Integration

Ensure tests run in CI/CD:

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - run: flutter test integration_test/app_test.dart -d chrome
```

## Resources

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Widget Testing Introduction](https://docs.flutter.dev/cookbook/testing/widget/introduction)
