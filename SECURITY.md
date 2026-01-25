# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Just Another Day, please report it by emailing the maintainers or opening a private security advisory on GitHub. 

**Please do not report security vulnerabilities through public GitHub issues.**

### What to Include

- Type of vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We will acknowledge receipt of your report within 48 hours and provide a more detailed response within 7 days.

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Best Practices

This document outlines security guidelines and best practices for the Just Another Day Flutter web application.

## Table of Contents

- [Code Security](#code-security)
- [Dependencies](#dependencies)
- [Data Security](#data-security)
- [Web Security](#web-security)
- [Authentication & Authorization](#authentication--authorization)
- [API Security](#api-security)
- [Secure Coding Guidelines](#secure-coding-guidelines)

## Code Security

### Input Validation

**Always validate and sanitize user input:**

```dart
// Good: Validate before processing
String sanitizeInput(String input) {
  if (input.isEmpty) {
    throw ArgumentError('Input cannot be empty');
  }
  
  // Remove potentially dangerous characters
  return input
      .trim()
      .replaceAll(RegExp(r'[<>\"\'&]'), '');
}

// Avoid: Using input directly
void processInput(String userInput) {
  // Dangerous: No validation
  database.query('SELECT * FROM users WHERE name = $userInput');
}
```

### SQL Injection Prevention

**Use parameterized queries:**

```dart
// Good: Parameterized query
Future<User> getUser(String id) async {
  final result = await database.query(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );
  return User.fromMap(result.first);
}

// Avoid: String concatenation
Future<User> getUser(String id) async {
  final result = await database.rawQuery(
    'SELECT * FROM users WHERE id = $id', // SQL Injection risk!
  );
  return User.fromMap(result.first);
}
```

### Cross-Site Scripting (XSS) Prevention

**Flutter's Text widget automatically escapes HTML, but be careful with HTML rendering:**

```dart
// Good: Flutter automatically escapes
Text(userInput) // Safe by default

// Avoid: Rendering HTML directly
HtmlWidget(userInput) // Could be dangerous without sanitization

// Good: Sanitize HTML input
String sanitizeHtml(String html) {
  return html
      .replaceAll('<script>', '')
      .replaceAll('</script>', '')
      .replaceAll('javascript:', '')
      .replaceAll('onerror=', '')
      .replaceAll('onclick=', '');
}
```

### Sensitive Data

**Never hardcode sensitive information:**

```dart
// Avoid: Hardcoded secrets
const apiKey = 'sk_live_abc123xyz'; // NEVER DO THIS
const password = 'mysecretpassword'; // NEVER DO THIS

// Good: Use environment variables or secure storage
final apiKey = const String.fromEnvironment('API_KEY');
final password = await secureStorage.read(key: 'password');
```

**Don't log sensitive information:**

```dart
// Avoid: Logging sensitive data
print('User password: $password'); // NEVER DO THIS
print('Credit card: ${user.creditCard}'); // NEVER DO THIS

// Good: Log without sensitive data
print('User authenticated: ${user.id}');
print('Payment processed for user: ${user.id}');
```

## Dependencies

### Regular Updates

Keep dependencies up to date to patch security vulnerabilities:

```bash
# Check for outdated packages
flutter pub outdated

# Update dependencies
flutter pub upgrade

# Audit for known vulnerabilities
flutter pub deps
```

### Verify Package Sources

- Only use packages from trusted sources (pub.dev)
- Check package popularity and maintenance status
- Review package source code for suspicious activity
- Use specific version constraints

```yaml
# Good: Specific version constraints
dependencies:
  http: ^1.1.0
  provider: ^6.0.0

# Avoid: Any version
dependencies:
  suspicious_package: any
```

### Dependency Scanning

Add dependency scanning to CI/CD:

```yaml
# .github/workflows/security.yml
name: Security Scan

on: [push, pull_request]

jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run dependency check
        run: flutter pub deps
```

## Data Security

### Secure Storage

**Use secure storage for sensitive data:**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Good: Secure storage
final storage = const FlutterSecureStorage();

// Store sensitive data
await storage.write(key: 'auth_token', value: token);

// Read sensitive data
final token = await storage.read(key: 'auth_token');

// Delete sensitive data
await storage.delete(key: 'auth_token');
```

**Never store sensitive data in SharedPreferences:**

```dart
// Avoid: Storing sensitive data in SharedPreferences
final prefs = await SharedPreferences.getInstance();
await prefs.setString('password', password); // INSECURE!
await prefs.setString('credit_card', cardNumber); // INSECURE!

// Good: Use SharedPreferences for non-sensitive data only
await prefs.setString('theme_mode', 'dark');
await prefs.setBool('notifications_enabled', true);
```

### Data Encryption

**Encrypt sensitive data before storage:**

```dart
import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final key = Key.fromSecureRandom(32);
  final iv = IV.fromSecureRandom(16);
  
  String encrypt(String plainText) {
    final encrypter = Encrypter(AES(key));
    return encrypter.encrypt(plainText, iv: iv).base64;
  }
  
  String decrypt(String encrypted) {
    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt64(encrypted, iv: iv);
  }
}
```

### Data Transmission

**Always use HTTPS:**

```dart
// Good: HTTPS
final response = await http.get(
  Uri.parse('https://api.example.com/data'),
);

// Avoid: HTTP for sensitive data
final response = await http.get(
  Uri.parse('http://api.example.com/data'), // Insecure!
);
```

**Implement certificate pinning for critical APIs:**

```dart
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

Future<void> secureFetch() async {
  List<String> allowedSHAs = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];
  
  try {
    await HttpCertificatePinning.check(
      serverURL: 'https://api.example.com',
      allowedSHAs: allowedSHAs,
      timeout: 50,
    );
  } catch (e) {
    // Handle certificate pinning failure
    throw SecurityException('Certificate pinning failed');
  }
}
```

## Web Security

### Content Security Policy (CSP)

Configure CSP in `web/index.html`:

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline' 'unsafe-eval'; 
               style-src 'self' 'unsafe-inline'; 
               img-src 'self' data: https:; 
               font-src 'self' data:; 
               connect-src 'self' https://api.example.com;">
```

### CORS Configuration

Configure CORS properly on your backend:

```dart
// Backend example (not Flutter)
// Only allow specific origins
app.use(cors({
  origin: 'https://yourdomain.com',
  credentials: true,
}));
```

### Clickjacking Prevention

Add X-Frame-Options header:

```html
<meta http-equiv="X-Frame-Options" content="DENY">
```

### XSS Protection

Enable browser XSS protection:

```html
<meta http-equiv="X-XSS-Protection" content="1; mode=block">
```

## Authentication & Authorization

### Password Security

**Never store plain text passwords:**

```dart
// IMPORTANT: Password hashing should ALWAYS be done on the backend
// The following examples are for educational purposes only

// Avoid: Using fast hashing algorithms like SHA-256
import 'package:crypto/crypto.dart';
import 'dart:convert';

String hashPasswordWrong(String password) {
  final bytes = utf8.encode(password);
  final hash = sha256.convert(bytes);
  return hash.toString(); // INSECURE! Vulnerable to brute force
}

// Good: Use bcrypt, scrypt, or argon2 (backend only)
// Example using bcrypt (pseudocode for backend):
// import 'package:bcrypt/bcrypt.dart';
// 
// String hashPassword(String password) {
//   final salt = BCrypt.gensalt();
//   return BCrypt.hashpw(password, salt);
// }
// 
// bool verifyPassword(String password, String hash) {
//   return BCrypt.checkpw(password, hash);
// }

// Frontend: Never hash passwords client-side
// Always send passwords over HTTPS to backend for proper hashing
```

**Implement password strength requirements:**

```dart
bool isPasswordStrong(String password) {
  // At least 8 characters
  if (password.length < 8) return false;
  
  // Contains uppercase
  if (!password.contains(RegExp(r'[A-Z]'))) return false;
  
  // Contains lowercase
  if (!password.contains(RegExp(r'[a-z]'))) return false;
  
  // Contains number
  if (!password.contains(RegExp(r'[0-9]'))) return false;
  
  // Contains special character
  if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
  
  return true;
}
```

### Token Management

**Store tokens securely:**

```dart
class AuthService {
  final storage = const FlutterSecureStorage();
  
  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }
  
  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }
  
  Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
  }
}
```

**Implement token expiration:**

```dart
class TokenValidator {
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      
      final exp = payload['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      return now > exp;
    } catch (e) {
      return true;
    }
  }
}
```

### Session Management

**Implement automatic logout:**

```dart
class SessionManager {
  Timer? _inactivityTimer;
  final Duration timeout = const Duration(minutes: 15);
  
  void resetInactivityTimer(VoidCallback onTimeout) {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(timeout, () {
      onTimeout(); // Logout user
    });
  }
  
  void dispose() {
    _inactivityTimer?.cancel();
  }
}
```

## API Security

### Request Authentication

**Include authentication tokens:**

```dart
Future<http.Response> authenticatedRequest(String url) async {
  final token = await authService.getToken();
  
  if (token == null) {
    throw UnauthenticatedException();
  }
  
  return await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
}
```

### Rate Limiting

**Implement client-side rate limiting:**

```dart
class RateLimiter {
  final int maxRequests;
  final Duration duration;
  final List<DateTime> _requests = [];
  
  RateLimiter({
    required this.maxRequests,
    required this.duration,
  });
  
  bool canMakeRequest() {
    final now = DateTime.now();
    final cutoff = now.subtract(duration);
    
    // Remove old requests
    _requests.removeWhere((time) => time.isBefore(cutoff));
    
    // Check if under limit
    if (_requests.length < maxRequests) {
      _requests.add(now);
      return true;
    }
    
    return false;
  }
}
```

### Error Handling

**Don't expose sensitive information in errors:**

```dart
// Good: Generic error message
try {
  await apiService.fetchData();
} catch (e) {
  showError('Unable to load data. Please try again.');
}

// Avoid: Exposing internal details
try {
  await apiService.fetchData();
} catch (e) {
  showError('Database connection failed: ${e.toString()}'); // Too much info!
}
```

## Secure Coding Guidelines

### 1. Principle of Least Privilege

Only request necessary permissions:

```yaml
# web/manifest.json
{
  "permissions": [
    "storage"
    // Only include what you need
  ]
}
```

### 2. Fail Securely

Default to secure state on failure:

```dart
bool isAuthorized(User? user) {
  if (user == null) return false; // Fail securely
  
  try {
    return checkAuthorization(user);
  } catch (e) {
    return false; // Fail securely
  }
}
```

### 3. Defense in Depth

Implement multiple layers of security:

- Input validation
- Authentication
- Authorization
- Encryption
- Logging and monitoring

### 4. Security by Design

Consider security from the start:

- Threat modeling
- Security requirements
- Secure architecture
- Security testing

### 5. Regular Security Audits

- Code reviews focusing on security
- Dependency vulnerability scans
- Penetration testing
- Security training

## Security Checklist

Before deployment, verify:

- [ ] No hardcoded secrets or credentials
- [ ] All sensitive data encrypted
- [ ] HTTPS used for all external communication
- [ ] Input validation implemented
- [ ] Authentication and authorization working
- [ ] Error messages don't expose sensitive info
- [ ] Dependencies up to date
- [ ] Security headers configured
- [ ] CSP implemented
- [ ] Logging doesn't include sensitive data
- [ ] Token expiration implemented
- [ ] Rate limiting in place
- [ ] Security testing completed

## Common Vulnerabilities to Avoid

### 1. Insecure Data Storage

❌ **Don't:**
- Store passwords in plain text
- Use SharedPreferences for sensitive data
- Store tokens in local storage without encryption

✅ **Do:**
- Use FlutterSecureStorage
- Encrypt sensitive data
- Implement proper key management

### 2. Insufficient Transport Layer Protection

❌ **Don't:**
- Use HTTP for sensitive data
- Accept any SSL certificate
- Ignore certificate validation errors

✅ **Do:**
- Always use HTTPS
- Implement certificate pinning
- Validate SSL certificates

### 3. Unintended Data Leakage

❌ **Don't:**
- Log sensitive information
- Include sensitive data in error messages
- Cache sensitive data unnecessarily

✅ **Do:**
- Sanitize logs
- Use generic error messages
- Clear sensitive data from memory

### 4. Broken Cryptography

❌ **Don't:**
- Use weak encryption algorithms
- Hard-code encryption keys
- Implement custom cryptography

✅ **Do:**
- Use strong, standard algorithms (AES-256)
- Store keys securely
- Use established cryptography libraries

## Resources

- [OWASP Mobile Security Project](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [Dart Security Guidelines](https://dart.dev/guides/security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Common Vulnerability Scoring System (CVSS)](https://www.first.org/cvss/)

## Contact

For security concerns, please contact the security team at [security@example.com](mailto:security@example.com).
