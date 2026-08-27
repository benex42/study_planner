import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:4000/api/v1',
);

class AuthUser {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['_id'] as String? ?? json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    avatarUrl: json['avatarUrl'] as String?,
  );
}

class AuthSession {
  const AuthSession({required this.user, required this.token});

  final AuthUser user;
  final String token;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Future<AuthSession?> restoreSession();
  Future<AuthSession> signIn({required String email, required String password});
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> signOut();
}

abstract class SocialAuthRepository {
  Future<AuthSession> signInWithIdentityToken({
    required String provider,
    required String idToken,
    String? name,
  });
}

class ApiAuthRepository implements AuthRepository, SocialAuthRepository {
  ApiAuthRepository({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'studyhub_access_token';
  final http.Client _client;
  final FlutterSecureStorage _storage;

  Uri _uri(String path) => Uri.parse('$apiBaseUrl/$path');

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    try {
      final response = await _client
          .get(_uri('auth/me'), headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 15));
      final body = _readBody(response);
      return AuthSession(
        token: token,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
    } on AuthException {
      await signOut();
      return null;
    }
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) => _authenticate('auth/login', {'email': email, 'password': password});

  @override
  Future<AuthSession> signUp({
    required String name,
    required String email,
    required String password,
  }) => _authenticate('auth/register', {
    'name': name,
    'email': email,
    'password': password,
  });

  @override
  Future<AuthSession> signInWithIdentityToken({
    required String provider,
    required String idToken,
    String? name,
  }) => _authenticate('auth/oauth', {
    'provider': provider,
    'idToken': idToken,
    if (name != null && name.isNotEmpty) 'name': name,
  });

  Future<AuthSession> _authenticate(
    String path,
    Map<String, String> payload,
  ) async {
    try {
      final response = await _client
          .post(
            _uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));
      final body = _readBody(response);
      final session = AuthSession(
        token: body['token'] as String,
        user: AuthUser.fromJson(body['user'] as Map<String, dynamic>),
      );
      await _storage.write(key: _tokenKey, value: session.token);
      return session;
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _readBody(http.Response response) {
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const AuthException('The server returned an invalid response.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        decoded['message'] as String? ?? 'Authentication failed.',
      );
    }
    return decoded;
  }

  @override
  Future<void> signOut() => _storage.delete(key: _tokenKey);
}

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository})
    : _repository = repository ?? ApiAuthRepository();

  final AuthRepository _repository;
  AuthUser? _user;
  String? _accessToken;
  bool _isLoading = true;

  AuthUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> initialize() async {
    try {
      final session = await _repository.restoreSession();
      _user = session?.user;
      _accessToken = session?.token;
    } catch (_) {
      _user = null;
      _accessToken = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    await _completeAuthentication(
      _repository.signIn(email: email.trim(), password: password),
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await _completeAuthentication(
      _repository.signUp(
        name: name.trim(),
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> signInWithGoogle() async {
    const clientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        clientId: clientId.isEmpty ? null : clientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }
      final idToken = (await account.authentication).idToken;
      if (idToken == null) {
        throw const AuthException(
          'Google did not return an identity token. Check the Google client ID setup.',
        );
      }
      await _completeSocialAuthentication(provider: 'google', idToken: idToken);
    } on AuthException {
      rethrow;
    } on PlatformException catch (error) {
      throw AuthException(
        'Google sign-in failed: ${error.message ?? error.code}',
      );
    }
  }

  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple did not return an identity token.');
      }
      final name = [
        credential.givenName,
        credential.familyName,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' ');
      await _completeSocialAuthentication(
        provider: 'apple',
        idToken: idToken,
        name: name.isEmpty ? null : name,
      );
    } on AuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Apple sign-in was cancelled.');
      }
      throw AuthException('Apple sign-in failed: ${error.message}');
    } on SignInWithAppleException catch (error) {
      throw AuthException('Apple sign-in failed: $error');
    } on PlatformException catch (error) {
      throw AuthException(
        'Apple sign-in failed: ${error.message ?? error.code}',
      );
    }
  }

  Future<void> _completeSocialAuthentication({
    required String provider,
    required String idToken,
    String? name,
  }) {
    final repository = _repository;
    if (repository is! SocialAuthRepository) {
      throw const AuthException(
        'Social sign-in is unavailable in this environment.',
      );
    }
    final socialRepository = repository as SocialAuthRepository;
    return _completeAuthentication(
      socialRepository.signInWithIdentityToken(
        provider: provider,
        idToken: idToken,
        name: name,
      ),
    );
  }

  Future<void> _completeAuthentication(Future<AuthSession> request) async {
    _isLoading = true;
    notifyListeners();
    try {
      final session = await request;
      _user = session.user;
      _accessToken = session.token;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _user = null;
    _accessToken = null;
    notifyListeners();
  }
}

class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'AuthScope is missing above this widget.');
    return scope!.notifier!;
  }
}
