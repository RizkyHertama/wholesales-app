import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/storage/secure_storage.dart';

class AuthRepository {
  final DioClient _client;
  final SecureStorage _storage;

  AuthRepository(this._client, this._storage);

  // Future<void> login(String email, String password) async {
  //   try {
  //     final response = await _client.dio.post(
  //       ApiEndpoints.login,
  //       data: {'email': email, 'password': password},
  //     );

  //     final responseData = response.data;

  //     // 1. Ekstrak token dari respons (baik di root JSON maupun di dalam objek 'data')
  //     final token = responseData is Map && responseData.containsKey('token')
  //         ? responseData['token']
  //         : (responseData is Map && responseData['data'] is Map
  //             ? responseData['data']['token']
  //             : null);

  //     // 2. Simpan token ke storage agar tidak terlempar balik oleh GoRouter
  //     if (token != null) {
  //       await _storage.saveToken(token.toString());
  //     }
  //   } on DioException catch (e) {
  //     if (e.response != null && e.response?.data != null) {
  //       final responseData = e.response?.data;
  //       final errorMessage = responseData is Map
  //           ? (responseData['message'] ?? 'Terjadi kesalahan')
  //           : 'Terjadi kesalahan';

  //       throw Exception(errorMessage);
  //     }

  //     // Tampilkan detail error Dio di konsol untuk analisa koneksi
  //     throw Exception('Gagal terhubung ke server: ${e.message}');
  //   } catch (e) {
  //     throw Exception(e.toString());
  //   }
  // }

  Future<void> login(String email, String password) async {
    try {
      final response = await _client.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );

      final responseData = response.data;

      // Ekstrak dari { "data": { "token": "...", "company_id": 4 } }
      final data = responseData is Map && responseData['data'] is Map
          ? responseData['data'] as Map
          : responseData as Map;

      final token = data['token'];
      final companyId = data['company_id'];
      final companyName = data['company_name'];

      if (token != null) {
        await _storage.saveToken(token.toString());
      }
      if (companyId != null) {
        await _storage.saveCompanyId(companyId.toString());
      }
      if (companyName != null) {
        await _storage.saveName(companyName.toString());
      }
      await _storage.saveRole('company');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response?.data;
        final errorMessage = responseData is Map
            ? (responseData['message'] ?? 'Terjadi kesalahan')
            : 'Terjadi kesalahan';
        throw Exception(errorMessage);
      }
      throw Exception('Gagal terhubung ke server: ${e.message}');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> register(
      String companyName, String email, String password) async {
    await _client.dio.post(ApiEndpoints.register, data: {
      'company_name': companyName,
      'email': email,
      'password': password
    });
  }

  Future<void> logout() => _storage.clear();
}
