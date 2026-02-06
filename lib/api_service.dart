import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: "https://api.yomemo.ai/api/v1"));

  void updateApiKey(String key) {
    _dio.options.headers["X-Memo-API-Key"] = key;
    _dio.options.headers["Content-Type"] = "application/json";
  }

  /// Fetch memories with cursor-based pagination.
  /// Returns a map with:
  /// - `data`: List of memory JSON objects.
  /// - `nextCursor`: String cursor for the next page (empty when no more).
  Future<Map<String, dynamic>> fetchMemories({
    String? cursor,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      "/memory",
      queryParameters: {
        "limit": limit,
        if (cursor != null && cursor.isNotEmpty) "cursor": cursor,
      },
    );
    final body = response.data ?? {};
    return {
      "data": body["data"] ?? [],
      "nextCursor": body["next_cursor"] ?? "",
    };
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
