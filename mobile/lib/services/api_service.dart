import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/visualize_result.dart';

/// Centralized API service for all backend communication
class ApiService {
  static const String _baseUrl =
      'https://ai-3d-backend-526063550551.us-central1.run.app';
  static const String _visualizeEndpoint = '/visualize';
  static const Duration _timeout = Duration(seconds: 30);

  /// Visualize a query using the backend API
  ///
  /// [query] The search query for visualization
  /// [style] Optional style parameter (e.g., 'educational')
  /// [complexity] Optional complexity parameter (e.g., 'medium')
  ///
  /// Returns a [VisualizeResult] object
  /// Throws [ApiException] on error
  static Future<VisualizeResult> visualize(
    String query, {
    String? style,
    String? complexity,
    required String network,
    required bool dataSaver,
  }) async {
    debugPrint('\n=== API REQUEST ===');
    debugPrint('API REQUEST: query = "$query"');
    if (style != null) debugPrint('API REQUEST: style = "$style"');
    if (complexity != null)
      debugPrint('API REQUEST: complexity = "$complexity"');
    debugPrint('==================\n');

    final Uri url = Uri.parse('$_baseUrl$_visualizeEndpoint');

    final Map<String, dynamic> requestBody = {
      'query': query,
      if (style != null) 'style': style,
      if (complexity != null) 'complexity': complexity,
      'network': network,
      'dataSaver': dataSaver,
    };

    debugPrint('=== API REQUEST BODY ===');
    debugPrint(jsonEncode(requestBody));
    debugPrint('========================');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(_timeout);

      debugPrint('\n=== API RESPONSE ===');
      debugPrint('API RESPONSE STATUS: ${response.statusCode}');
      debugPrint('API RESPONSE JSON: ${response.body}');
      debugPrint('===================\n');

      if (response.statusCode != 200) {
        throw ApiException(
          'Server returned status code ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['success'] != true) {
        final errorMessage = responseData['error'] ?? 'Unknown server error';
        throw ApiException(errorMessage);
      }

      final result = VisualizeResult.fromJson(responseData, query);

      if (responseData['type'] == 'glb' &&
          responseData['data']?['url'] != null) {
        debugPrint(
            '[GLB][Flutter] API returned GLB: ${responseData['data']['url']} (network=${requestBody['network']})');
      }

      debugPrint('\n=== PARSED RESULT ===');
      debugPrint('PARSED RESULT: type = "${result.type}"');
      debugPrint('PARSED RESULT: success = ${result.success}');
      debugPrint('PARSED RESULT: has3DContent = ${result.has3DContent}');
      debugPrint('PARSED RESULT: hasExplanation = ${result.hasExplanation}');
      if (result.glbUrl != null) {
        debugPrint('PARSED RESULT: glbUrl = "${result.glbUrl}"');
      }
      if (result.blueprintJson != null) {
        debugPrint(
            'PARSED RESULT: blueprintJson length = ${result.blueprintJson!.length} characters');
      }
      if (result.explanation != null) {
        debugPrint(
            'PARSED RESULT: explanation length = ${result.explanation!.length} characters');
      }
      if (result.processingTime != null) {
        debugPrint(
            'PARSED RESULT: processingTime = ${result.processingTime}ms');
      }
      debugPrint('====================\n');

      return result;
    } on http.ClientException catch (e) {
      debugPrint('[ApiService] Network error: $e');
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[ApiService] Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: ${e.toString()}');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException: $message';
}
