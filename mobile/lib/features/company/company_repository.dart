import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/storage/secure_storage.dart';

class CompanyRepository {
  final DioClient _client;
  final SecureStorage _storage; // ← tambah ini

  CompanyRepository(this._client, this._storage); // ← tambah storage

  Future<double> getBalance() async {
    final companyId = await _storage.getCompanyId(); // ← ambil dari storage

    final res = await _client.dio.get(
      ApiEndpoints.balance,
      queryParameters: {'company_id': companyId}, // ← kirim ?company_id=4
    );

    final body = res.data;
    final map = (body is Map && body['data'] is Map)
        ? body['data'] as Map
        : body as Map;

    return (map['balance'] as num).toDouble();
  }
}
