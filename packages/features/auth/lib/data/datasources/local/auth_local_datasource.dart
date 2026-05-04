import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../models/user_model.dart';
import 'dart:convert';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser();
  Future<void> deleteUser();
  
  // Remember me functionality
  Future<void> saveCredentials(String identifier, String password);
  Future<Map<String, String>?> getCredentials();
  Future<void> deleteCredentials();
  Future<void> setRememberMe(bool remember);
  Future<bool> getRememberMe();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage secureStorage;
  
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _identifierKey = 'saved_identifier';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';

  AuthLocalDataSourceImpl({required this.secureStorage});

  @override
  Future<void> saveToken(String token) async {
    await secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> deleteToken() async {
    await secureStorage.delete(key: _tokenKey);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await secureStorage.write(key: _userKey, value: userJson);
  }

  @override
  Future<UserModel?> getUser() async {
    final userJson = await secureStorage.read(key: _userKey);
    if (userJson == null) return null;
    
    final userMap = jsonDecode(userJson) as Map<String, dynamic>;
    return UserModel.fromJson(userMap);
  }

  @override
  Future<void> deleteUser() async {
    await secureStorage.delete(key: _userKey);
  }

  @override
  Future<void> saveCredentials(String identifier, String password) async {
    await secureStorage.write(key: _identifierKey, value: identifier);
    await secureStorage.write(key: _passwordKey, value: password);
  }

  @override
  Future<Map<String, String>?> getCredentials() async {
    final identifier = await secureStorage.read(key: _identifierKey);
    final password = await secureStorage.read(key: _passwordKey);
    
    if (identifier == null || password == null) return null;
    
    return {
      'identifier': identifier,
      'password': password,
    };
  }

  @override
  Future<void> deleteCredentials() async {
    await secureStorage.delete(key: _identifierKey);
    await secureStorage.delete(key: _passwordKey);
  }

  @override
  Future<void> setRememberMe(bool remember) async {
    await secureStorage.write(key: _rememberMeKey, value: remember.toString());
  }

  @override
  Future<bool> getRememberMe() async {
    final value = await secureStorage.read(key: _rememberMeKey);
    return value == 'true';
  }
}
