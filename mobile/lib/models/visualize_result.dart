import 'dart:convert';

/// VisualizeResult model representing the backend API response
class VisualizeResult {
  final String query;
  final String type;
  final String? glbUrl;
  final String? blueprintJson;
  final String? explanation;
  final bool success;
  final int? processingTime;
  final String? source;

  VisualizeResult({
    required this.query,
    required this.type,
    this.glbUrl,
    this.blueprintJson,
    this.explanation,
    required this.success,
    this.processingTime,
    this.source,
  });

  /// Create VisualizeResult from JSON response
  factory VisualizeResult.fromJson(
      Map<String, dynamic> json, String originalQuery) {
    final success = json['success'] as bool? ?? false;
    final type = json['type'] as String? ?? '';

    String? glbUrl;
    String? blueprintJson;
    String? explanation;

    if (success && json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;

      if (type == 'glb' && data['url'] != null) {
        glbUrl = data['url'] as String?;
      } else if (type == 'scene' || type == 'procedural' || type == 'json') {
        blueprintJson = jsonEncode(data);
      }
    }

    // Extract explanation from top-level response
    if (json['explanation'] != null) {
      explanation = json['explanation'] as String?;
    } else if (success && json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;
      // Fallback: extract from meta.description if present
      if (data['meta'] != null && data['meta']['description'] != null) {
        explanation = data['meta']['description'] as String?;
      }
    }

    return VisualizeResult(
      query: originalQuery,
      type: type,
      glbUrl: glbUrl,
      blueprintJson: blueprintJson,
      explanation: explanation,
      success: success,
      processingTime: json['processingTime'] as int?,
      source: json['source'] as String?,
    );
  }

  /// Check if result has 3D content
  bool get has3DContent => glbUrl != null || blueprintJson != null;

  /// Check if result has explanation
  bool get hasExplanation => explanation != null && explanation!.isNotEmpty;

  @override
  String toString() {
    return 'VisualizeResult(query: $query, type: $type, success: $success, has3DContent: $has3DContent)';
  }
}
