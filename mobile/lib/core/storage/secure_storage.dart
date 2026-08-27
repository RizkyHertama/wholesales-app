import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final _storage = const FlutterSecureStorage();

  static const _token = 'jwt_token';
  static const _role = 'user_role';

  static const _keyCompanyId = 'company_id';
  static const _keyCompanyName = 'company_name';

  Future<void> saveCompanyId(String id) =>
      _storage.write(key: _keyCompanyId, value: id);

  Future<String?> getCompanyId() => _storage.read(key: _keyCompanyId);

  Future<void> saveName(String name) =>
      _storage.write(key: _keyCompanyName, value: name);

  Future<String?> getName() => _storage.read(key: _keyCompanyName);

  Future<void> saveToken(String token) =>
      _storage.write(key: _token, value: token);
  Future<String?> getToken() => _storage.read(key: _token);
  Future<void> saveRole(String role) => _storage.write(key: _role, value: role);
  Future<String?> getRole() => _storage.read(key: _role);
  Future<void> clear() => _storage.deleteAll();
}
