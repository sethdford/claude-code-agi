# Flutter Preset

Flutter conventions for Claude Code agents building or maintaining Flutter applications.

## Project Structure

```
lib/
├── main.dart                # App entry point
├── screens/                 # Full-page widgets
│   ├── home_screen.dart
│   ├── detail_screen.dart
│   └── settings_screen.dart
├── widgets/                 # Reusable widgets
│   ├── common/             # Generic widgets (buttons, cards)
│   ├── forms/              # Form inputs
│   └── navigation/         # Navigation widgets
├── models/                  # Data models
│   ├── user.dart
│   ├── product.dart
│   └── api_response.dart
├── services/               # API, database, external services
│   ├── api_service.dart
│   ├── storage_service.dart
│   └── auth_service.dart
├── providers/              # State management (Riverpod/BLoC)
│   ├── user_provider.dart
│   ├── product_provider.dart
│   └── theme_provider.dart
├── utils/                  # Utilities, constants, extensions
│   ├── constants.dart
│   ├── logger.dart
│   └── extensions.dart
├── routes/                 # Navigation/routing
│   └── app_router.dart
└── theme/                  # Theme configuration
    └── app_theme.dart

test/                       # Unit and widget tests
├── unit/
├── widget/
└── integration/

pubspec.yaml               # Dependencies and metadata
analysis_options.yaml      # Linter rules
```

## Widget Patterns

### Stateless Widget

```dart
import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final VoidCallback onTap;

  const UserCard({
    required this.name,
    required this.email,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(email),
        onTap: onTap,
      ),
    );
  }
}
```

### Stateful Widget

```dart
import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  const CounterWidget({Key? key}) : super(key: key);

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Counter: $_counter'),
        ElevatedButton(
          onPressed: _incrementCounter,
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

## State Management with Riverpod

### Simple Provider

```dart
// lib/providers/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserProvider = FutureProvider<User>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCurrentUser();
});
```

### State Notifier Provider

```dart
class UserNotifier extends StateNotifier<List<User>> {
  final ApiService apiService;

  UserNotifier(this.apiService) : super([]);

  Future<void> loadUsers() async {
    state = await apiService.getUsers();
  }

  Future<void> addUser(User user) async {
    await apiService.createUser(user);
    state = [...state, user];
  }

  Future<void> deleteUser(String id) async {
    await apiService.deleteUser(id);
    state = state.where((u) => u.id != id).toList();
  }
}

final usersProvider = StateNotifierProvider<UserNotifier, List<User>>((ref) {
  final apiService = ref.read(apiServiceProvider);
  return UserNotifier(apiService);
});
```

### Consumer Widget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserListScreen extends ConsumerWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return usersAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
      data: (users) => ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) => UserCard(
          user: users[index],
          onDelete: () => ref.read(usersProvider.notifier).deleteUser(users[index].id),
        ),
      ),
    );
  }
}
```

## State Management with BLoC

### BLoC Pattern

```dart
// lib/models/user_event.dart
abstract class UserEvent {}

class FetchUsersEvent extends UserEvent {}

class DeleteUserEvent extends UserEvent {
  final String userId;
  DeleteUserEvent(this.userId);
}

// lib/models/user_state.dart
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;
  UserLoaded(this.users);
}

class UserError extends UserState {
  final String message;
  UserError(this.message);
}

// lib/blocs/user_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final ApiService apiService;

  UserBloc(this.apiService) : super(UserInitial()) {
    on<FetchUsersEvent>(_onFetchUsers);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  Future<void> _onFetchUsers(
    FetchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      emit(UserLoading());
      final users = await apiService.getUsers();
      emit(UserLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await apiService.deleteUser(event.userId);
      final currentState = state;
      if (currentState is UserLoaded) {
        final updatedUsers = currentState.users
            .where((u) => u.id != event.userId)
            .toList();
        emit(UserLoaded(updatedUsers));
      }
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}

// Usage in widget
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        if (state is UserInitial) {
          context.read<UserBloc>().add(FetchUsersEvent());
        }

        if (state is UserLoading) {
          return const CircularProgressIndicator();
        }

        if (state is UserLoaded) {
          return ListView.builder(
            itemCount: state.users.length,
            itemBuilder: (context, index) => UserCard(
              user: state.users[index],
            ),
          );
        }

        if (state is UserError) {
          return Text('Error: ${state.message}');
        }

        return const SizedBox();
      },
    );
  }
}
```

## Navigation

### GoRouter Pattern

```dart
// lib/routes/app_router.dart
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'user/:id',
          builder: (context, state) => UserDetailScreen(
            userId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
);

// Usage in main.dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      title: 'My App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}
```

### Navigation Example

```dart
// Navigate to route
context.push('/user/${user.id}');

// Navigate and replace
context.pushReplacementNamed('login');

// Pop back
context.pop();

// Pop until
context.go('/');
```

## API Service Pattern

```dart
// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'https://api.example.com';

  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((u) => User.fromJson(u)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getUserById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<User> createUser(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(user.toJson()),
    );

    if (response.statusCode == 201) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }
}
```

## Models and JSON Serialization

```dart
// lib/models/user.dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String name;
  final String email;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```

Run code generation:
```bash
flutter pub run build_runner build
```

## Testing with flutter_test

### Unit Test

```dart
// test/models/user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/user.dart';

void main() {
  group('User Model', () {
    test('User.fromJson creates correct instance', () {
      final json = {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
      };

      final user = User.fromJson(json);

      expect(user.id, '1');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
    });

    test('User.toJson returns correct map', () {
      final user = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );

      expect(user.toJson(), {
        'id': '1',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': null,
      });
    });
  });
}
```

### Widget Test

```dart
// test/widgets/user_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/models/user.dart';
import 'package:myapp/widgets/user_card.dart';

void main() {
  group('UserCard', () {
    testWidgets('displays user name and email', (WidgetTester tester) async {
      final user = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(
              user: user,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      final user = User(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UserCard(
              user: user,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(UserCard));
      expect(tapped, true);
    });
  });
}
```

### Integration Test

```dart
// test/integration/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:myapp/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Test', () {
    testWidgets('navigates to user detail', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.byType(UserListScreen), findsOneWidget);

      await tester.tap(find.byType(UserCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(UserDetailScreen), findsOneWidget);
    });
  });
}
```

## Theme Configuration

```dart
// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
}

// Usage in main.dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
```

## Platform Channels (Native Communication)

```dart
// lib/services/native_service.dart
import 'package:flutter/services.dart';

class NativeService {
  static const platform = MethodChannel('com.example.myapp/native');

  static Future<String> getDeviceInfo() async {
    try {
      final String result = await platform.invokeMethod('getDeviceInfo');
      return result;
    } catch (e) {
      return 'Error: $e';
    }
  }

  static Future<void> openNativeCamera() async {
    try {
      await platform.invokeMethod('openCamera');
    } catch (e) {
      print('Error: $e');
    }
  }
}
```

## Conventions

- **File naming**: Use snake_case for file names
- **Class naming**: Use PascalCase for class names
- **Variable naming**: Use camelCase for variables and functions
- **Const constructors**: Mark constructors const where possible
- **Private members**: Prefix with underscore (_varName)
- **State management**: Choose one (Riverpod or BLoC), not both
- **API calls**: Put in services, inject via providers or constructors
- **Models**: Use json_serializable for JSON serialization
- **Testing**: Test all state changes, navigation, and error handling
- **Theme**: Use ThemeData and ColorScheme, avoid hardcoded colors
- **Dispose**: Always dispose of controllers (TextEditingController, AnimationController)
- **Async**: Use try-catch for API calls, handle timeouts
- **Null safety**: Use ! only when 100% certain, prefer ?? and if-let patterns
- **Comments**: Document complex logic, skip obvious code

## pubspec.yaml Template

```yaml
name: myapp
description: A Flutter application.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.1.0

  # Navigation
  go_router: ^13.0.0

  # API and serialization
  http: ^1.1.0
  json_annotation: ^4.8.0

  # Local storage
  shared_preferences: ^2.2.0

  # Logging
  logger: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code generation
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  riverpod_generator: ^2.3.0

  # Testing
  mockito: ^5.4.0
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
```

## Agent Task Template

```markdown
# Flutter Feature: [Name]

## Requirements
- [ ] Design widget hierarchy
- [ ] Define data models
- [ ] Implement API service methods
- [ ] Set up state management (Riverpod/BLoC)
- [ ] Create screens and widgets
- [ ] Add navigation routes
- [ ] Implement forms with validation
- [ ] Handle error states and loading
- [ ] Write unit tests for models and services
- [ ] Write widget tests for UI
- [ ] Test on Android and iOS
- [ ] Check accessibility (color contrast, text size)

## Files to Create/Modify
- `lib/models/...`
- `lib/services/...`
- `lib/screens/...`
- `lib/widgets/...`
- `lib/providers/...` or `lib/blocs/...`
- `test/...`

## Testing
```bash
flutter test
flutter test --coverage
```

## Verification
- [ ] All tests pass
- [ ] No analyzer warnings
- [ ] Hot reload works
- [ ] Both platforms (iOS/Android) build
- [ ] App doesn't crash on error states
```
