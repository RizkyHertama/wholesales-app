import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';

class AdminRepository {
  final DioClient _client;
  AdminRepository(this._client);

  Future<List<dynamic>> getEmployees() async {
    final res = await _client.dio.get(ApiEndpoints.employees);
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getCompanies() async {
    final res = await _client.dio.get(ApiEndpoints.companies);
    return res.data as List<dynamic>;
  }
}
