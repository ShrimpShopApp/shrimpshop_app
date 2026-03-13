import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();
  static const _kCustomerToken = 'customer_access_token';

  static Future<void> saveToken(String token) => _storage.write(key: _kCustomerToken, value: token);
  static Future<String?> readToken() => _storage.read(key: _kCustomerToken);
  static Future<void> clearToken() => _storage.delete(key: _kCustomerToken);
}