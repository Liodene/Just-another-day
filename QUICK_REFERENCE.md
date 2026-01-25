# Developer Quick Reference

A quick reference guide for developers working on the Just Another Day Flutter project.

## 📚 Documentation Overview

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [README.md](README.md) | Project overview and setup | Getting started with the project |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guidelines | Before making your first contribution |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture and design patterns | Planning new features or refactoring |
| [CODE_STYLE.md](CODE_STYLE.md) | Code style and conventions | Writing or reviewing code |
| [TESTING.md](TESTING.md) | Testing strategies | Writing tests |
| [SECURITY.md](SECURITY.md) | Security best practices | Handling sensitive data or APIs |

## 🚀 Quick Start Commands

### Setup
```bash
# Clone the repository
git clone https://github.com/Liodene/Just-another-day.git
cd Just-another-day

# Install dependencies
flutter pub get
```

### Development
```bash
# Run app in Chrome
flutter run -d chrome

# Run with hot reload
flutter run -d chrome --hot

# Format code
dart format lib test

# Analyze code
flutter analyze
```

### Testing
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/widget_test.dart
```

### Build
```bash
# Build for production
flutter build web --release --base-href "/Just-another-day/"
```

## 📋 Pre-Commit Checklist

Before committing code, ensure:

- [ ] Code is formatted: `dart format lib test`
- [ ] No lint warnings: `flutter analyze`
- [ ] All tests pass: `flutter test`
- [ ] New code has tests (>= 80% coverage)
- [ ] Documentation is updated
- [ ] Commit message follows conventions

## 🎯 Common Tasks

### Adding a New Feature

1. Create feature branch: `git checkout -b feature/feature-name`
2. Create feature directory: `lib/features/feature_name/`
3. Organize as:
   ```
   feature_name/
   ├── models/
   ├── views/
   ├── widgets/
   └── services/
   ```
4. Write tests in: `test/unit/features/feature_name/`
5. Follow [ARCHITECTURE.md](ARCHITECTURE.md) patterns

### Fixing a Bug

1. Create branch: `git checkout -b fix/bug-name`
2. Write failing test first
3. Fix the bug
4. Ensure test passes
5. Follow [CODE_STYLE.md](CODE_STYLE.md)

### Adding a Dependency

1. Check security: Review package on pub.dev
2. Add to `pubspec.yaml`
3. Run: `flutter pub get`
4. Update documentation if needed

## 🔍 Code Quality Standards

### Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserProfile` |
| Variables | camelCase | `userName` |
| Functions | camelCase | `getUserData()` |
| Constants | lowerCamelCase | `maxRetries` |
| Files | snake_case | `user_profile.dart` |
| Private | _prefix | `_privateMethod` |

### Widget Guidelines

```dart
// ✅ Good
class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user});
  
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Text('Hello'),
    );
  }
}

// ❌ Avoid
class UserCard extends StatelessWidget {
  var user; // No type, not final
  
  Widget build(context) { // Missing @override, type
    return Card( // Missing const
      child: Text('Hello'),
    );
  }
}
```

### Testing Guidelines

```dart
// ✅ Good Test
group('UserService', () {
  late UserService service;
  late MockRepository mockRepo;
  
  setUp(() {
    mockRepo = MockRepository();
    service = UserService(mockRepo);
  });
  
  test('getUser returns user when found', () async {
    // Arrange
    final expectedUser = User(id: '1', name: 'John');
    when(mockRepo.getUser('1')).thenAnswer((_) async => expectedUser);
    
    // Act
    final user = await service.getUser('1');
    
    // Assert
    expect(user, expectedUser);
    verify(mockRepo.getUser('1')).called(1);
  });
});
```

## 🔒 Security Checklist

When working with sensitive data:

- [ ] No hardcoded secrets
- [ ] Use HTTPS for all external calls
- [ ] Validate all user input
- [ ] Use `FlutterSecureStorage` for sensitive data
- [ ] No logging of sensitive information
- [ ] Implement proper error handling

## 🐛 Debugging Tips

### Common Issues

**Issue**: Widget not updating
- Solution: Check if using `const` incorrectly
- Check: State management (setState, Provider, etc.)

**Issue**: Lint errors after pulling changes
- Solution: Run `flutter pub get` to update dependencies
- Run: `dart format lib test` to fix formatting

**Issue**: Tests failing
- Solution: Run `flutter pub get`
- Check: Test isolation (each test should be independent)

### Debug Commands

```bash
# Print widget tree
debugDumpApp()

# Print render tree
debugDumpRenderTree()

# Check performance
flutter run --profile

# Verbose logging
flutter run --verbose
```

## 📊 Project Metrics

### Coverage Goals
- Overall: >= 80%
- Critical paths: 100%
- Business logic: >= 90%
- UI code: >= 70%

### Performance Targets
- Initial load: < 3 seconds
- Page transitions: < 100ms
- Build time: < 5 seconds

## 🔗 Useful Links

### Internal Documentation
- [Contributing Guide](CONTRIBUTING.md)
- [Architecture](ARCHITECTURE.md)
- [Code Style](CODE_STYLE.md)
- [Testing Guide](TESTING.md)
- [Security](SECURITY.md)

### External Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Material Design 3](https://m3.material.io/)
- [Flutter GitHub](https://github.com/flutter/flutter)

### Community
- [Flutter Community](https://flutter.dev/community)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)
- [r/FlutterDev](https://www.reddit.com/r/FlutterDev/)

## 💡 Best Practices Summary

### DO ✅
- Use `const` constructors
- Write tests for all new code
- Document public APIs
- Handle errors gracefully
- Keep widgets small and focused
- Follow SOLID principles
- Use meaningful names

### DON'T ❌
- Hardcode values
- Skip tests
- Use `print()` for logging
- Ignore lint warnings
- Mix UI and business logic
- Store sensitive data insecurely
- Commit commented-out code

## 🎓 Learning Path

For new contributors:

1. **Week 1**: Read README.md, CONTRIBUTING.md
2. **Week 2**: Study CODE_STYLE.md, practice with small PRs
3. **Week 3**: Learn ARCHITECTURE.md, review existing code
4. **Week 4**: Read TESTING.md and SECURITY.md
5. **Ongoing**: Contribute features, participate in code reviews

## 📞 Getting Help

- 💬 Questions about code? Open a GitHub Discussion
- 🐛 Found a bug? Open an Issue
- 🔒 Security concern? See [SECURITY.md](SECURITY.md)
- 💡 Feature idea? Open an Issue with [Feature Request] tag

## 🔄 Workflow Summary

```
1. Pick an issue
   ↓
2. Create feature branch
   ↓
3. Write tests (TDD)
   ↓
4. Implement feature
   ↓
5. Run quality checks
   ↓
6. Commit with meaningful message
   ↓
7. Push and create PR
   ↓
8. Address review comments
   ↓
9. Merge and celebrate! 🎉
```

---

**Last Updated**: January 2026

For the most up-to-date information, always refer to the main documentation files.
