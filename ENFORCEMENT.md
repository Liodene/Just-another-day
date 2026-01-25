# Code Style Enforcement Guide

This document explains how code style is automatically enforced in the Just Another Day project.

## Table of Contents

- [Overview](#overview)
- [Enforcement Levels](#enforcement-levels)
- [Local Development](#local-development)
- [Continuous Integration](#continuous-integration)
- [IDE Integration](#ide-integration)
- [Troubleshooting](#troubleshooting)

## Overview

The project uses multiple layers of enforcement to maintain consistent code quality:

1. **IDE Integration** - Real-time feedback while coding
2. **Pre-commit Hooks** - Automatic checks before commits
3. **CI/CD Pipeline** - Enforcement on pull requests
4. **Static Analysis** - 181 linting rules via `analysis_options.yaml`

## Enforcement Levels

### Level 1: IDE Real-Time Enforcement

Your IDE provides immediate feedback as you type.

**VS Code Setup:**

1. Install the [Flutter extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
2. Add to `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.formatOnType": false,
  "editor.codeActionsOnSave": {
    "source.fixAll": true,
    "source.organizeImports": true
  },
  "dart.lineLength": 80,
  "dart.enableSnippets": true,
  "dart.analysisExcludedFolders": [
    "**/build/**",
    "**/.dart_tool/**"
  ],
  "dart.showTodos": true,
  "dart.previewFlutterUiGuides": true,
  "editor.rulers": [80],
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true
}
```

**Android Studio / IntelliJ IDEA Setup:**

1. **File → Settings → Languages & Frameworks → Flutter**
   - Enable "Format code on save"
   - Enable "Organize imports on save"

2. **File → Settings → Editor → Code Style → Dart**
   - Set "Right margin (columns)" to 80
   - Enable "Enable formatter markers in comments"

3. **File → Settings → Editor → Inspections → Dart**
   - Enable all Dart linting inspections
   - Set severity to "Error" for critical issues

### Level 2: Pre-commit Hook Enforcement

Automatic checks run before each commit to catch issues early.

**Installation:**

```bash
# One-time setup
git config core.hooksPath .githooks

# Verify installation
git config --get core.hooksPath
# Should output: .githooks
```

**What it checks:**

1. ✅ **Code Formatting** - Ensures code follows Dart style guide
   ```bash
   dart format --set-exit-if-changed --line-length 80
   ```

2. ✅ **Static Analysis** - Runs all 181 linting rules
   ```bash
   flutter analyze
   ```

3. ✅ **Common Issues**
   - Detects `print()` statements (should use `debugPrint()`)
   - Warns about TODO comments (create GitHub issues instead)

**Example Output:**

```
🔍 Running pre-commit checks...
📝 Checking 3 files...

1️⃣  Checking code formatting...
✅ Code formatting is correct

2️⃣  Running static analysis...
✅ Code analysis passed

3️⃣  Checking for common issues...

✅ All pre-commit checks passed!
```

**Bypassing (Not Recommended):**

```bash
# Only use in emergencies
git commit --no-verify -m "Emergency fix"
```

### Level 3: CI/CD Pipeline Enforcement

GitHub Actions automatically enforce code quality on all pull requests.

**Workflow Steps:**

1. **Code Formatting Check**
   ```yaml
   - name: Check code formatting
     run: dart format --set-exit-if-changed --line-length 80 lib test
   ```
   - Fails if any file is not formatted correctly
   - Zero tolerance for formatting issues

2. **Static Analysis**
   ```yaml
   - name: Analyze code
     run: flutter analyze
   ```
   - Runs all 181 linting rules
   - Fails on any error or warning

3. **Test Execution**
   ```yaml
   - name: Run tests
     run: flutter test
   ```
   - All tests must pass
   - >= 80% coverage required

**CI will fail if:**
- ❌ Any file is not formatted correctly
- ❌ Any linting rule is violated
- ❌ Any test fails
- ❌ Code coverage drops below 80%

### Level 4: Static Analysis Rules

The `analysis_options.yaml` file contains **181 comprehensive linting rules**.

**Key Enforcements:**

```yaml
analyzer:
  language:
    strict-casts: true          # Enforce type safety
    strict-inference: true      # Strict type inference
    strict-raw-types: true      # No raw types
    strict-null-safety: true    # Enforce null safety
  errors:
    missing_required_param: error
    missing_return: error
    invalid_assignment: error
```

**Rule Categories:**

1. **Error Prevention** (23 rules)
   - `avoid_empty_else`
   - `avoid_print`
   - `avoid_returning_null_for_future`
   - `cancel_subscriptions`
   - `close_sinks`

2. **Style Consistency** (158 rules)
   - `prefer_const_constructors`
   - `prefer_final_locals`
   - `require_trailing_commas`
   - `always_declare_return_types`
   - `prefer_single_quotes`

**Viewing All Rules:**

```bash
# List all active rules
flutter analyze --help | grep "Available lints"

# Check specific file
flutter analyze lib/main.dart

# Check with detailed output
flutter analyze --verbose
```

## Local Development

### Manual Enforcement Commands

```bash
# Format all code
dart format lib test

# Format with specific line length
dart format --line-length 80 lib test

# Check formatting without changing files
dart format --set-exit-if-changed lib test

# Run static analysis
flutter analyze

# Analyze specific file
flutter analyze lib/main.dart

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

### Quick Fix Workflow

```bash
# 1. Format code
dart format lib test

# 2. Check for issues
flutter analyze

# 3. Run tests
flutter test

# 4. Commit (pre-commit hook runs automatically)
git add .
git commit -m "feat: add new feature"
```

## Continuous Integration

### GitHub Actions Workflow

File: `.github/workflows/deploy.yml`

```yaml
- name: Check code formatting
  run: |
    echo "Checking code formatting..."
    dart format --set-exit-if-changed --line-length 80 lib test
    echo "✅ Code formatting is correct"

- name: Analyze code
  run: flutter analyze

- name: Run tests
  run: flutter test
```

### Pull Request Checks

Every pull request must pass:

1. ✅ Code formatting check
2. ✅ Static analysis (all 181 rules)
3. ✅ All tests pass
4. ✅ Build succeeds

**PR Status Checks:**

- 🟢 Green check = All passed, ready to merge
- 🔴 Red X = Failed, needs fixes
- 🟡 Yellow circle = In progress

### Viewing CI Failures

1. Go to the pull request
2. Scroll to "Checks" section
3. Click on failed check
4. View detailed logs
5. Fix issues locally
6. Push updated code

## IDE Integration

### VS Code Recommended Extensions

```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "alexisvt.flutter-snippets",
    "nash.awesome-flutter-snippets",
    "everettjf.pubspec-dependency-search"
  ]
}
```

### VS Code Tasks

File: `.vscode/tasks.json`

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Format Code",
      "type": "shell",
      "command": "dart format lib test",
      "group": "build"
    },
    {
      "label": "Analyze Code",
      "type": "shell",
      "command": "flutter analyze",
      "group": "build"
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "flutter test",
      "group": "test"
    }
  ]
}
```

Run tasks with: `Ctrl+Shift+P` → "Tasks: Run Task"

### Android Studio Live Templates

Create custom live templates for enforced patterns:

1. **File → Settings → Editor → Live Templates**
2. Click "+" to add new template
3. Examples:

**Stateless Widget with const:**
```dart
class $NAME$ extends StatelessWidget {
  const $NAME$({super.key});
  
  @override
  Widget build(BuildContext context) {
    return $END$;
  }
}
```

**Test with arrange-act-assert:**
```dart
test('$DESCRIPTION$', () {
  // Arrange
  $ARRANGE$
  
  // Act
  $ACT$
  
  // Assert
  expect($ACTUAL$, $EXPECTED$);
});
```

## Troubleshooting

### Common Issues

#### Issue: Pre-commit hook not running

**Solution:**
```bash
# Reinstall hook
git config core.hooksPath .githooks

# Make sure it's executable
chmod +x .githooks/pre-commit

# Verify
git config --get core.hooksPath
```

#### Issue: IDE not showing linting errors

**Solution:**
```bash
# Restart Dart analysis server
# VS Code: Ctrl+Shift+P → "Dart: Restart Analysis Server"
# Android Studio: File → Invalidate Caches / Restart

# Update dependencies
flutter pub get
```

#### Issue: Formatting fails in CI but works locally

**Solution:**
```bash
# Check your Dart SDK version
dart --version

# CI uses Flutter 3.27.1, ensure local matches
flutter --version

# Format with explicit line length
dart format --line-length 80 lib test
```

#### Issue: Too many linting errors to fix at once

**Solution:**
```dart
// Temporarily ignore specific rules (use sparingly)
// ignore_for_file: prefer_const_constructors

// Or ignore specific line
final widget = Container(); // ignore: prefer_const_constructors
```

**Better Solution:**
```bash
# Fix issues incrementally
# 1. Fix all formatting issues first
dart format lib test

# 2. Fix easy issues (const constructors)
# Use IDE quick fixes (Ctrl+. or Alt+Enter)

# 3. Fix remaining issues one file at a time
flutter analyze lib/main.dart
```

### Getting Help

If you encounter issues with code style enforcement:

1. **Check the documentation**
   - [CODE_STYLE.md](CODE_STYLE.md) - Style guidelines
   - [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution workflow

2. **Use IDE quick fixes**
   - VS Code: `Ctrl+.` or click the lightbulb
   - Android Studio: `Alt+Enter`

3. **Ask for help**
   - Open a GitHub Discussion
   - Ask in pull request comments
   - Review existing issues

## Best Practices

### Daily Development

```bash
# Start of day: Pull latest changes
git pull origin main
flutter pub get

# During development: Run checks frequently
dart format lib test && flutter analyze

# Before committing: Run all checks
dart format lib test
flutter analyze
flutter test

# Commit (hooks run automatically)
git add .
git commit -m "feat: add feature"
```

### Code Review Checklist

Before requesting review, ensure:

- [ ] Code is formatted (`dart format lib test`)
- [ ] No linting errors (`flutter analyze`)
- [ ] All tests pass (`flutter test`)
- [ ] New code has tests (>= 80% coverage)
- [ ] No `print()` statements (use `debugPrint()`)
- [ ] No TODO comments (create issues)
- [ ] CI checks pass on GitHub

## Summary

**Automatic Enforcement Layers:**

1. ✅ **IDE** - Real-time feedback
2. ✅ **Pre-commit Hook** - Before every commit
3. ✅ **CI/CD** - On every pull request
4. ✅ **Static Analysis** - 181 linting rules

**Result:** Consistent, high-quality code across the entire project.

**Key Commands:**
```bash
# Setup (one time)
git config core.hooksPath .githooks

# Daily use
dart format lib test
flutter analyze
flutter test
git commit -m "your message"  # Hooks run automatically
```

All code style violations are **automatically caught** before they reach the main branch! 🎉
