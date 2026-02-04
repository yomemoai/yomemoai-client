import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "https://api.yomemo.ai/api/v1"));

  void updateApiKey(String key) {
    _dio.options.headers["X-Memo-API-Key"] = key;
    _dio.options.headers["Content-Type"] = "application/json";
  }

  Future<List<dynamic>> fetchMemories() async {
    final response = await _dio.get("/memory");
    return response.data['data'] ?? [];
  }

  Future<void> syncMemory({
    required String handle,
    required String encryptedBase64,
    String? description,
    String? existingIdempotentKey,
    Map<String, dynamic>? metadata,
  }) async {
    final String keyToUse = existingIdempotentKey ?? const Uuid().v4();
    await _dio.post(
      "/memory",
      data: {
        "handle": handle,
        "ciphertext": encryptedBase64,
        "description": description,
        "idempotent_key": keyToUse,
        "metadata": ?metadata,
      },
    );
  }
}
