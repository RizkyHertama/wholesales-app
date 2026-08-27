import '../../core/api/dio_client.dart';
import '../../core/api/endpoints.dart';

class TransferRepository {
  final DioClient _client;
  TransferRepository(this._client);

  Future<void> createTransfer(Map<String, dynamic> payload) async {
    await _client.dio.post(ApiEndpoints.transfer, data: payload);
  }

  Future<List<dynamic>> getHistory() async {
    final res = await _client.dio.get(ApiEndpoints.transferHistory);
    return res.data as List<dynamic>;
  }
}
