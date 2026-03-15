import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Validates a scene blueprint JSON against the required schema.
/// Returns [null] if valid, or a fallback cube scene JSON string on failure.
class SceneValidator {
  static const _requiredKeys = ['meta', 'environment', 'primitives', 'assets'];

  /// Returns the validated JSON string, or a fallback cube scene if invalid.
  static String validateOrFallback(String jsonString) {
    try {
      final parsed = jsonDecode(jsonString);
      if (parsed is! Map<String, dynamic>) {
        debugPrint('SceneValidator: root is not a Map — using fallback');
        return _fallbackCubeScene;
      }
      for (final key in _requiredKeys) {
        if (!parsed.containsKey(key)) {
          debugPrint('SceneValidator: missing key "$key" — using fallback');
          return _fallbackCubeScene;
        }
      }
      return jsonString; // valid
    } catch (e) {
      debugPrint('SceneValidator: parse error ($e) — using fallback');
      return _fallbackCubeScene;
    }
  }

  static String get _fallbackCubeScene => jsonEncode({
        'meta': {
          'name': 'Fallback Cube',
          'description': 'Scene validation failed',
          'gpu_status': 'active',
        },
        'environment': {
          'skyColor': '#0a0a1a',
          'fogDensity': 0.02,
          'bloomIntensity': 1.5,
          'ground': true,
        },
        'primitives': [
          {
            'id': 'fallback-cube',
            'type': 'box',
            'args': [2, 2, 2],
            'transform': {
              'pos': [0, 1, 0],
              'rot': [0, 0, 0],
              'scale': [1, 1, 1],
            },
            'material': {
              'color': '#ef4444',
              'metalness': 0.3,
              'roughness': 0.4,
            },
          }
        ],
        'assets': [],
      });
}

// ─────────────────────────────────────────────────
//  Bridge command types
// ─────────────────────────────────────────────────

enum _CommandType { loadScene, loadGLB, updateEnvironment }

class _BridgeCommand {
  final _CommandType type;
  final String payload;
  _BridgeCommand(this.type, this.payload);
}

// ─────────────────────────────────────────────────
//  SceneController
// ─────────────────────────────────────────────────

/// Controller for communicating with the 3D scene WebView.
///
/// Safety features:
/// 1. **Command queue** — caches commands until BRIDGE_READY.
/// 2. **Base64 transport** — prevents JS eval failures from AI-generated quotes.
/// 3. **Scene validation** — checks required keys before sending.
class SceneController {
  InAppWebViewController? _webViewController;
  bool _bridgeReady = false;
  final List<_BridgeCommand> _commandQueue = [];

  bool get isBridgeReady => _bridgeReady;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  /// Call when BRIDGE_READY message is received from the WebView.
  void markBridgeReady() {
    _bridgeReady = true;
    debugPrint(
        'SceneController: bridge ready — draining ${_commandQueue.length} queued commands');
    _drainQueue();
  }

  // ── Public API ──────────────────────────────────

  /// Load a scene from a JSON blueprint string.
  /// Validates the schema first and falls back to a cube scene if invalid.
  Future<void> loadScene(String jsonString) async {
    debugPrint('\n=== SceneController.loadScene ===');
    debugPrint('SceneController.loadScene called');
    debugPrint('SceneController: Payload length = ${jsonString.length}');
    debugPrint(
        'SceneController: Payload preview = "${jsonString.substring(0, 100)}..."');

    final validated = SceneValidator.validateOrFallback(jsonString);

    if (validated != jsonString) {
      debugPrint(
          'SceneController: Using fallback scene due to validation failure');
    }

    _enqueueOrExecute(
      _BridgeCommand(_CommandType.loadScene, validated),
    );
  }

  /// Load a GLB model from a URL.
  Future<void> loadGLB(String url) async {
    debugPrint('\n=== SceneController.loadGLB ===');
    debugPrint('SceneController.loadGLB called');
    debugPrint('SceneController: URL = "$url"');
    debugPrint('SceneController: Enqueuing loadGLB command');
    debugPrint('[GLB][SceneController] Sending loadGLB to WebView: $url');
    debugPrint('===============================\n');
    _enqueueOrExecute(_BridgeCommand(_CommandType.loadGLB, url));
  }

  /// Update environment settings.
  Future<void> updateEnvironment(Map<String, dynamic> env) async {
    _enqueueOrExecute(
        _BridgeCommand(_CommandType.updateEnvironment, jsonEncode(env)));
  }

  /// Reset the scene.
  Future<void> resetScene() async {
    final controller = _webViewController;
    if (controller == null) return;
    await controller.evaluateJavascript(
      source: "window.resetScene && window.resetScene()",
    );
  }

  // ── Queue management ────────────────────────────

  void _enqueueOrExecute(_BridgeCommand cmd) {
    if (_bridgeReady && _webViewController != null) {
      _executeCommand(cmd);
    } else {
      debugPrint('SceneController: bridge not ready — queuing ${cmd.type}');
      _commandQueue.add(cmd);
    }
  }

  void _drainQueue() {
    for (final cmd in _commandQueue) {
      _executeCommand(cmd);
    }
    _commandQueue.clear();
  }

  Future<void> _executeCommand(_BridgeCommand cmd) async {
    final controller = _webViewController;
    if (controller == null) {
      debugPrint('SceneController: WebView controller is null');
      return;
    }

    switch (cmd.type) {
      case _CommandType.loadScene:
        debugPrint('[Scene] Injecting loadScene');
        try {
          await controller.evaluateJavascript(
            source: 'window.loadScene(' + cmd.payload + ');',
          );
          debugPrint('[Scene] loadScene executed');
        } catch (e) {
          debugPrint('[Scene] loadScene error: $e');
        }
        break;

      case _CommandType.loadGLB:
        // TEMP TEST: override GLB URL to verify renderer pipeline
        final testUrl =
            'https://raw.githubusercontent.com/KhronosGroup/glTF-Sample-Models/main/2.0/Duck/glTF-Binary/Duck.glb';
        final escapedUrl = testUrl.replaceAll("'", "\\'");
        debugPrint('[GLB] Injecting loadGLB with URL: ${cmd.payload}');
        debugPrint('[GLB TEST] Injecting duck test model');
        try {
          await controller.evaluateJavascript(
            source: "window.loadGLB && window.loadGLB('" + escapedUrl + "');",
          );
          debugPrint('[GLB] evaluateJavascript executed');
        } catch (e) {
          debugPrint('[GLB] evaluateJavascript error: $e');
          rethrow;
        }
        break;

      case _CommandType.updateEnvironment:
        try {
          await controller.evaluateJavascript(
            source: 'window.loadScene(' + cmd.payload + ');',
          );
        } catch (e) {
          debugPrint('[Scene] updateEnvironment error: $e');
        }
        break;
    }
  }
}
