# Contributing to Just Another Day

Thank you for your interest in contributing to Just Another Day! This document provides guidelines and best practices for contributing to this Flutter web application.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Code Quality Standards](#code-quality-standards)
- [Pull Request Process](#pull-request-process)
- [Testing Requirements](#testing-requirements)

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other community members

## Getting Started

### Prerequisites

- Flutter SDK (>=3.16.0)
- Dart SDK
- Git
- A code editor (VS Code or Android Studio recommended)

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Just-another-day.git
   cd Just-another-day
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Workflow

### Branch Naming Convention

Use descriptive branch names following this pattern:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Adding or updating tests

Example: `feature/add-user-authentication`

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semi-colons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(ui): add dark mode toggle

Implements a theme switcher that allows users to toggle between
light and dark modes. The preference is saved to local storage.

Closes #123
```

## Code Quality Standards

### Dart/Flutter Best Practices

1. **Use const constructors whenever possible**
   ```dart
   // Good
   const Text('Hello World')
   
   // Avoid
   Text('Hello World')
   ```

2. **Follow the single responsibility principle**
   - Each widget should have a single, well-defined purpose
   - Extract complex widgets into separate files

3. **Prefer composition over inheritance**
   - Build complex UIs by combining simple widgets
   - Use mixins for shared behavior

4. **Use meaningful names**
   ```dart
   // Good
   final String userDisplayName;
   void calculateTotalPrice() {}
   
   // Avoid
   final String n;
   void calc() {}
   ```

5. **Keep widgets small and focused**
   - Extract large build methods into smaller widgets
   - Maximum ~100-150 lines per widget class

### State Management

- Use `StatefulWidget` for simple, local state
- Consider state management solutions (Provider, Riverpod, Bloc) for complex state
- Keep state as close to where it's used as possible
- Avoid unnecessary rebuilds by using `const` constructors

### Code Organization

```
lib/
├── main.dart                 # App entry point
├── core/                     # Core functionality
│   ├── constants/           # App constants
│   ├── themes/              # Theme definitions
│   └── utils/               # Utility functions
├── features/                # Feature modules
│   ├── feature_name/
│   │   ├── models/          # Data models
│   │   ├── views/           # UI widgets
│   │   ├── widgets/         # Reusable widgets
│   │   └── services/        # Business logic
└── shared/                  # Shared components
    ├── widgets/             # Shared widgets
    └── models/              # Shared models
```

### Linting

This project uses `flutter_lints` with additional custom rules. Ensure your code passes all lint checks:

```bash
flutter analyze
```

Fix all warnings and errors before submitting a PR.

### Formatting

Use `dart format` to automatically format your code:

```bash
dart format lib test
```

- Line length: 80 characters (default)
- Use trailing commas for better formatting
- Configure your IDE to format on save

## Pull Request Process

1. **Update your branch**
   ```bash
   git checkout main
   git pull origin main
   git checkout your-branch
   git rebase main
   ```

2. **Run quality checks**
   ```bash
   # Format code
   dart format lib test
   
   # Analyze code
   flutter analyze
   
   # Run tests
   flutter test
   
   # Build for web
   flutter build web --release
   ```

3. **Create a pull request**
   - Use a clear, descriptive title
   - Reference any related issues
   - Provide a detailed description of changes
   - Include screenshots for UI changes
   - Ensure all CI checks pass

4. **Code review**
   - Address all review comments
   - Keep discussions focused and professional
   - Update your PR based on feedback

5. **Merge**
   - Squash commits if requested
   - Ensure the branch is up to date with main
   - Delete your branch after merging

## Testing Requirements

### Unit Tests

- Write unit tests for all business logic
- Test coverage should be >= 80%
- Use descriptive test names

```dart
test('incrementCounter increases counter by 1', () {
  // Arrange
  final counter = Counter();
  
  // Act
  counter.increment();
  
  // Assert
  expect(counter.value, 1);
});
```

### Widget Tests

- Test widget rendering and user interactions
- Test different widget states
- Test edge cases

```dart
testWidgets('Counter increments when button is pressed', (tester) async {
  // Build widget
  await tester.pumpWidget(const MyApp());
  
  // Verify initial state
  expect(find.text('0'), findsOneWidget);
  
  // Tap button
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pump();
  
  // Verify updated state
  expect(find.text('1'), findsOneWidget);
});
```

### Integration Tests

- Test complete user flows
- Test interactions between multiple components
- Place in `integration_test/` directory

## Performance Guidelines

1. **Avoid unnecessary rebuilds**
   - Use `const` constructors
   - Use `ListView.builder` for long lists
   - Implement `shouldRebuild` when needed

2. **Optimize images**
   - Use appropriate image formats (WebP for web)
   - Provide multiple resolutions
   - Lazy load images

3. **Minimize bundle size**
   - Use tree-shaking
   - Avoid unnecessary dependencies
   - Enable code splitting for web

## Accessibility

- Provide semantic labels for interactive elements
- Ensure sufficient color contrast
- Support keyboard navigation
- Test with screen readers
- Add tooltips for icon buttons

```dart
FloatingActionButton(
  onPressed: _incrementCounter,
  tooltip: 'Increment counter',
  child: const Icon(Icons.add, semanticLabel: 'Add'),
)
```

## Documentation

- Document all public APIs
- Use dartdoc comments for classes, methods, and properties
- Provide code examples for complex functionality
- Keep README.md up to date

```dart
/// Calculates the total price including tax.
///
/// Returns the sum of [basePrice] and tax calculated at [taxRate].
/// Throws [ArgumentError] if [taxRate] is negative.
///
/// Example:
/// ```dart
/// final total = calculateTotal(100.0, 0.08); // Returns 108.0
/// ```
double calculateTotal(double basePrice, double taxRate) {
  if (taxRate < 0) {
    throw ArgumentError('Tax rate cannot be negative');
  }
  return basePrice * (1 + taxRate);
}
```

## Questions?

If you have questions or need help, please:
- Open an issue for bugs or feature requests
- Start a discussion for general questions
- Review existing documentation

Thank you for contributing! 🎉
