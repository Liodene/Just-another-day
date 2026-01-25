# Architecture Documentation

This document describes the architecture, design patterns, and structural guidelines for the Just Another Day Flutter web application.

## Table of Contents

- [Overview](#overview)
- [Architecture Principles](#architecture-principles)
- [Project Structure](#project-structure)
- [Design Patterns](#design-patterns)
- [Component Architecture](#component-architecture)
- [State Management](#state-management)
- [Data Flow](#data-flow)
- [Navigation](#navigation)
- [Performance Considerations](#performance-considerations)

## Overview

Just Another Day is built using Flutter for the web, following modern software architecture principles to ensure maintainability, scalability, and testability.

### Technology Stack

- **Framework**: Flutter (Web)
- **Language**: Dart
- **UI**: Material Design 3
- **Deployment**: GitHub Pages
- **CI/CD**: GitHub Actions

## Architecture Principles

### 1. Separation of Concerns

Separate the application into distinct layers with clear responsibilities:

- **Presentation Layer**: UI widgets and screens
- **Business Logic Layer**: Application logic and state management
- **Data Layer**: Data models and services

### 2. Single Responsibility Principle

Each class, widget, and module should have one clear purpose:

```dart
// Good: Single responsibility
class UserProfile extends StatelessWidget {
  const UserProfile({super.key, required this.user});
  
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

// Avoid: Multiple responsibilities
class UserProfileWithData extends StatefulWidget {
  // Mixing UI, data fetching, and business logic
}
```

### 3. Dependency Inversion

Depend on abstractions, not concretions:

```dart
// Good: Depend on abstract interface
abstract class UserRepository {
  Future<User> getUser(String id);
}

class UserService {
  UserService(this.repository);
  
  final UserRepository repository;
  
  Future<User> fetchUser(String id) => repository.getUser(id);
}

// Implementation can be swapped
class ApiUserRepository implements UserRepository {
  @override
  Future<User> getUser(String id) async {
    // API implementation
  }
}
```

### 4. Composition Over Inheritance

Build complex widgets by combining simpler ones:

```dart
// Good: Composition
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key, required this.user});
  
  final User user;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          UserAvatar(user: user),
          UserName(user: user),
          UserBio(user: user),
        ],
      ),
    );
  }
}

// Avoid: Deep inheritance hierarchies
class BaseCard extends StatelessWidget {}
class UserCard extends BaseCard {}
class ProfileCard extends UserCard {}
```

## Project Structure

### Recommended Organization

```
lib/
├── main.dart                     # Application entry point
│
├── core/                         # Core functionality (framework)
│   ├── constants/
│   │   ├── api_constants.dart   # API endpoints, keys
│   │   ├── app_constants.dart   # App-wide constants
│   │   └── route_constants.dart # Route names
│   │
│   ├── themes/
│   │   ├── app_theme.dart       # Theme configuration
│   │   ├── colors.dart          # Color palette
│   │   └── text_styles.dart     # Typography
│   │
│   ├── utils/
│   │   ├── validators.dart      # Input validation
│   │   ├── formatters.dart      # Data formatting
│   │   └── extensions.dart      # Dart extensions
│   │
│   └── errors/
│       ├── exceptions.dart      # Custom exceptions
│       └── failures.dart        # Error handling
│
├── features/                     # Feature modules
│   ├── home/                    # Home feature
│   │   ├── models/
│   │   │   └── home_data.dart
│   │   ├── views/
│   │   │   └── home_page.dart
│   │   ├── widgets/
│   │   │   ├── counter_display.dart
│   │   │   └── increment_button.dart
│   │   └── services/
│   │       └── home_service.dart
│   │
│   └── feature_name/            # New feature template
│       ├── models/              # Feature-specific data models
│       ├── views/               # Full-screen pages
│       ├── widgets/             # Reusable feature widgets
│       └── services/            # Business logic
│
├── shared/                      # Shared across features
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── cards/
│   │   └── dialogs/
│   │
│   ├── models/
│   │   └── common_models.dart
│   │
│   └── services/
│       ├── api_service.dart
│       └── storage_service.dart
│
└── config/                      # App configuration
    ├── routes.dart              # Route configuration
    └── app_config.dart          # Environment config

test/
├── unit/                        # Unit tests
├── widget/                      # Widget tests
└── integration/                 # Integration tests
```

## Design Patterns

### 1. Repository Pattern

Separate data access logic from business logic:

```dart
// Domain model
class User {
  const User({required this.id, required this.name});
  
  final String id;
  final String name;
}

// Repository interface
abstract class UserRepository {
  Future<User?> getUser(String id);
  Future<void> saveUser(User user);
}

// Implementation
class LocalUserRepository implements UserRepository {
  @override
  Future<User?> getUser(String id) async {
    // Implementation
  }
  
  @override
  Future<void> saveUser(User user) async {
    // Implementation
  }
}
```

### 2. Factory Pattern

Create objects without specifying exact classes:

```dart
abstract class Shape {
  void draw();
  
  factory Shape.fromType(String type) {
    switch (type) {
      case 'circle':
        return Circle();
      case 'square':
        return Square();
      default:
        throw ArgumentError('Unknown shape type: $type');
    }
  }
}

class Circle implements Shape {
  @override
  void draw() => print('Drawing circle');
}

class Square implements Shape {
  @override
  void draw() => print('Drawing square');
}
```

### 3. Builder Pattern

Construct complex objects step by step:

```dart
class UserProfile {
  UserProfile._({
    required this.name,
    required this.email,
    this.age,
    this.bio,
  });
  
  final String name;
  final String email;
  final int? age;
  final String? bio;
  
  factory UserProfile.builder() => _UserProfileBuilder();
}

class _UserProfileBuilder {
  String? _name;
  String? _email;
  int? _age;
  String? _bio;
  
  _UserProfileBuilder setName(String name) {
    _name = name;
    return this;
  }
  
  _UserProfileBuilder setEmail(String email) {
    _email = email;
    return this;
  }
  
  _UserProfileBuilder setAge(int age) {
    _age = age;
    return this;
  }
  
  _UserProfileBuilder setBio(String bio) {
    _bio = bio;
    return this;
  }
  
  UserProfile build() {
    if (_name == null || _email == null) {
      throw StateError('Name and email are required');
    }
    
    return UserProfile._(
      name: _name!,
      email: _email!,
      age: _age,
      bio: _bio,
    );
  }
}
```

### 4. Observer Pattern

Implemented via Flutter's built-in mechanisms (ChangeNotifier, StreamController):

```dart
class CounterModel extends ChangeNotifier {
  int _count = 0;
  
  int get count => _count;
  
  void increment() {
    _count++;
    notifyListeners();
  }
}

// Usage in widget
class CounterDisplay extends StatelessWidget {
  const CounterDisplay({super.key, required this.model});
  
  final CounterModel model;
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, child) {
        return Text('Count: ${model.count}');
      },
    );
  }
}
```

## Component Architecture

### Widget Hierarchy

Organize widgets in a clear hierarchy:

1. **Pages/Screens**: Full-screen views
2. **Sections**: Major page sections
3. **Components**: Reusable UI elements
4. **Primitives**: Basic building blocks

```dart
// Page level
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HomeAppBar(),          // Section
      body: HomeContent(),           // Section
      floatingActionButton: AddButton(), // Component
    );
  }
}

// Section level
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HeaderSection(),              // Component
        ContentList(),                // Component
      ],
    );
  }
}

// Component level
class HeaderSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(                      // Primitive
      child: Text('Header'),          // Primitive
    );
  }
}
```

### Stateless vs Stateful Widgets

**Use StatelessWidget when:**
- Widget doesn't need to maintain state
- All properties are final
- Widget depends only on configuration and BuildContext

**Use StatefulWidget when:**
- Widget needs to maintain mutable state
- State changes over time
- Need lifecycle methods (initState, dispose)

```dart
// Stateless: No internal state
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.imageUrl});
  
  final String imageUrl;
  
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundImage: NetworkImage(imageUrl),
    );
  }
}

// Stateful: Manages animation state
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({super.key, required this.value});
  
  final int value;
  
  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Text('${widget.value}');
      },
    );
  }
}
```

## State Management

### Local State

Use `StatefulWidget` for simple, local state:

```dart
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({super.key, required this.child});
  
  final Widget child;
  
  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool _isExpanded = false;
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text('Title'),
            trailing: IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: _toggleExpanded,
            ),
          ),
          if (_isExpanded) widget.child,
        ],
      ),
    );
  }
}
```

### App-Wide State

For complex state, consider:
- **InheritedWidget**: Pass data down the tree
- **Provider**: Simple dependency injection and state management
- **Riverpod**: Modern, compile-safe provider
- **Bloc**: Business logic separation with streams
- **GetX**: Lightweight state management

```dart
// Using InheritedWidget for theme
class AppTheme extends InheritedWidget {
  const AppTheme({
    super.key,
    required this.themeData,
    required super.child,
  });
  
  final ThemeData themeData;
  
  static AppTheme of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppTheme>()!;
  }
  
  @override
  bool updateShouldNotify(AppTheme oldWidget) {
    return themeData != oldWidget.themeData;
  }
}
```

## Data Flow

### Unidirectional Data Flow

Follow a unidirectional data flow pattern:

```
User Action → State Update → UI Rebuild
     ↓             ↓              ↓
  Events      State Layer    Widget Tree
```

```dart
// State
class AppState {
  const AppState({required this.counter});
  
  final int counter;
  
  AppState copyWith({int? counter}) {
    return AppState(counter: counter ?? this.counter);
  }
}

// Actions
abstract class CounterAction {}
class IncrementAction extends CounterAction {}
class DecrementAction extends CounterAction {}

// Reducer
AppState counterReducer(AppState state, CounterAction action) {
  if (action is IncrementAction) {
    return state.copyWith(counter: state.counter + 1);
  } else if (action is DecrementAction) {
    return state.copyWith(counter: state.counter - 1);
  }
  return state;
}
```

## Navigation

### Route Management

Organize routes centrally:

```dart
// routes.dart
class AppRoutes {
  static const String home = '/';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case settings:
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      default:
        return MaterialPageRoute(
          builder: (_) => const NotFoundPage(),
        );
    }
  }
}

// main.dart
MaterialApp(
  onGenerateRoute: AppRoutes.generateRoute,
  initialRoute: AppRoutes.home,
)
```

## Performance Considerations

### 1. Build Method Optimization

- Keep build methods pure (no side effects)
- Extract const widgets
- Use const constructors
- Split large widgets into smaller ones

### 2. List Performance

```dart
// Good: ListView.builder for large lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)

// Avoid: Creating all children upfront
ListView(
  children: items.map((item) => ListTile(title: Text(item))).toList(),
)
```

### 3. Async Operations

```dart
// Good: Proper async/await usage
Future<User> fetchUser(String id) async {
  try {
    final response = await http.get(Uri.parse('/api/user/$id'));
    return User.fromJson(jsonDecode(response.body));
  } catch (e) {
    throw UserFetchException(e.toString());
  }
}

// Avoid: Unhandled futures
void loadUser() {
  fetchUser('123'); // Future not awaited
}
```

### 4. Memory Management

- Dispose controllers, streams, and listeners
- Use `AutomaticKeepAliveClientMixin` wisely
- Avoid memory leaks in callbacks

```dart
@override
void dispose() {
  _controller.dispose();
  _subscription.cancel();
  super.dispose();
}
```

## Testing Architecture

### Test Organization

Mirror the lib structure:

```
test/
├── unit/
│   ├── core/
│   │   └── utils_test.dart
│   └── features/
│       └── home/
│           └── services/
│               └── home_service_test.dart
├── widget/
│   └── features/
│       └── home/
│           └── widgets/
│               └── counter_display_test.dart
└── integration/
    └── app_test.dart
```

### Testability Guidelines

- Inject dependencies
- Use interfaces/abstractions
- Keep widgets pure
- Separate UI from logic
- Mock external dependencies

```dart
// Testable: Dependencies injected
class UserService {
  UserService(this.repository);
  
  final UserRepository repository;
  
  Future<User> getUser(String id) => repository.getUser(id);
}

// Test
void main() {
  test('getUser returns user from repository', () async {
    final mockRepo = MockUserRepository();
    final service = UserService(mockRepo);
    
    when(mockRepo.getUser('1')).thenAnswer(
      (_) async => const User(id: '1', name: 'Test'),
    );
    
    final user = await service.getUser('1');
    
    expect(user.name, 'Test');
  });
}
```

## Scalability

As the application grows:

1. **Feature Modules**: Organize by feature, not layer
2. **Lazy Loading**: Load features on demand
3. **Code Generation**: Use build_runner for serialization, routing
4. **Modularization**: Split into separate packages if needed
5. **Documentation**: Maintain architecture decision records (ADRs)

## Best Practices Summary

✅ **DO:**
- Keep widgets small and focused
- Use const constructors
- Follow SOLID principles
- Write tests
- Document public APIs
- Handle errors gracefully
- Optimize performance

❌ **DON'T:**
- Mix UI and business logic
- Use global state unnecessarily
- Ignore error handling
- Skip testing
- Hardcode values
- Create deep widget trees
- Forget to dispose resources

## Resources

- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Flutter Best Practices](https://docs.flutter.dev/testing/best-practices)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Material Design Guidelines](https://m3.material.io/)
