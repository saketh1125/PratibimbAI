/// PratibimbAI - Flutter Mobile Shell
/// Educational 3D Engine with WebView integration
///
/// Architecture:
/// - Layer 0: InAppWebView (hosting React Three Fiber engine)
/// - Layer 1: Glassmorphic UI overlay (Search bar, Sidebar)

import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const PratibimbAIApp());
}

class PratibimbAIApp extends StatelessWidget {
  const PratibimbAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PratibimbAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF8B5CF6),
          surface: const Color(0xFF1E1E2E),
          background: const Color(0xFF0A0A1A),
        ),
      ),
      home: const PratibimbAIHome(),
    );
  }
}

class PratibimbAIHome extends StatefulWidget {
  const PratibimbAIHome({super.key});

  @override
  State<PratibimbAIHome> createState() => _PratibimbAIHomeState();
}

class _PratibimbAIHomeState extends State<PratibimbAIHome> {
  // Controllers
  late InAppWebViewController _webViewController;
  final TextEditingController _searchController = TextEditingController();
  final SceneController _sceneController = SceneController();

  // State
  bool _isLoading = true;
  bool _isSidebarOpen = false;
  bool _isSearching = false;
  String _currentScene = 'Taj Mahal';
  Timer? _loadingTimer;
  bool _bridgeReady = false;
  bool _uiVisible = true;
  Timer? _uiHideTimer;

  // API Configuration
  static const String apiBaseUrl =
      'http://localhost:8000'; // Change for production

  @override
  void initState() {
    super.initState();
    // Fallback timeout after 10 seconds
    _loadingTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
        _showError('Scene loading timeout - showing default view');
      }
    });
    // Start UI auto-hide timer
    _resetUiTimer();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _loadingTimer?.cancel();
    _uiHideTimer?.cancel();
    super.dispose();
  }

  /// Handle messages from the WebView
  void _handleBridgeMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;

      switch (type) {
        case 'SCENE_LOADED':
          setState(() => _isLoading = false);
          break;
        case 'BRIDGE_READY':
          setState(() => _bridgeReady = true);
          debugPrint('Bridge is ready - can now load scenes');
          break;
        case 'ERROR':
          _showError(data['error'] ?? 'Unknown error');
          break;
        default:
          debugPrint('Unknown bridge message type: $type');
      }
    } catch (e) {
      debugPrint('Bridge message parse error: $e');
    }
  }

  /// Load a scene from the API
  Future<void> _loadScene(String query) async {
    setState(() => _isSearching = true);

    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/v1/visualize'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'query': query,
          'style': 'educational',
          'complexity': 'medium',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          if (data['blueprint'] != null) {
            // Load synthesized scene
            await _sceneController.loadScene(
              jsonEncode(data['blueprint']),
            );
            setState(() => _currentScene = data['blueprint']['meta']['name']);
          } else if (data['glb_url'] != null) {
            // Load GLB model
            await _sceneController.loadGLB(data['glb_url']);
          }
        } else {
          _showError(data['error'] ?? 'Failed to generate scene');
        }
      } else {
        _showError('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: Send directly to WebView for local demo scenes
      _webViewController.evaluateJavascript(
        source: "window.loadScene && window.loadScene('$query')",
      );
      debugPrint('API error (using fallback): $e');
    } finally {
      setState(() {
        _isSearching = false;
        _isSidebarOpen = false;
      });
      _searchController.clear();
    }
  }

  /// Load a demo scene
  Future<void> _loadDemoScene(String sceneName) async {
    setState(() {
      _isLoading = true;
      _isSidebarOpen = false;
      _currentScene = sceneName;
    });

    // Wait for bridge to be ready
    if (!_bridgeReady) {
      debugPrint('Waiting for bridge to be ready...');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!_bridgeReady) {
        _showError('Bridge not ready - please try again');
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      // Test with hardcoded cube scene first
      if (sceneName == 'test') {
        final testScene = {
          'meta': {
            'name': 'Test Cube',
            'description': 'Simple test scene',
            'gpu_status': 'active'
          },
          'environment': {
            'skyColor': '#0a0a1a',
            'fogDensity': 0.02,
            'bloomIntensity': 1.5,
            'ground': true
          },
          'primitives': [
            {
              'id': 'test-cube',
              'type': 'box',
              'args': [2, 2, 2],
              'transform': {
                'pos': [0, 1, 0],
                'rot': [0, 0, 0],
                'scale': [1, 1, 1]
              },
              'material': {
                'color': '#6366f1',
                'metalness': 0.3,
                'roughness': 0.4
              }
            }
          ],
          'assets': []
        };
        await _sceneController.loadScene(jsonEncode(testScene));
        setState(() => _currentScene = 'Test Cube');
      } else {
        final response = await http.get(
          Uri.parse('$apiBaseUrl/v1/demo/$sceneName'),
        );

        if (response.statusCode == 200) {
          debugPrint('Demo API success: Loaded $sceneName');
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic> &&
                decoded.containsKey('blueprint')) {
              await _sceneController
                  .loadScene(jsonEncode(decoded['blueprint']));
            } else {
              await _sceneController.loadScene(response.body);
            }
          } catch (e) {
            await _sceneController.loadScene(response.body);
          }
        } else {
          debugPrint('Demo API returned ${response.statusCode}');
          _showError('Failed to load demo scene: ${response.statusCode}');
        }
      }
    } catch (e) {
      // Fallback to local demos if API unreachable
      debugPrint('Demo API error (using local fallback): $e');
      if (sceneName == 'taj') {
        final tajFallback = {
          'meta': {'name': 'Taj Mahal', 'gpu_status': 'active'},
          'environment': {
            'skyColor': '#1a0a2e',
            'fogDensity': 0.008,
            'bloomIntensity': 1.5,
            'ground': true
          },
          'primitives': [
            {
              'type': 'box',
              'args': [20, 1, 20],
              'transform': {
                'pos': [0, 0.5, 0],
                'rot': [0, 0, 0],
                'scale': [1, 1, 1]
              },
              'material': {
                'color': '#8b0000',
                'metalness': 0.3,
                'roughness': 0.8
              }
            },
            {
              'type': 'cylinder',
              'args': [3.5, 3.5, 1.5, 64],
              'transform': {
                'pos': [0, 8.5, 0],
                'rot': [0, 0, 0],
                'scale': [1, 1, 1]
              },
              'material': {
                'color': '#faf8f5',
                'metalness': 0.2,
                'roughness': 0.3
              }
            },
            {
              'type': 'sphere',
              'args': [3.2, 64, 32, 0, 6.28, 0, 1.57],
              'transform': {
                'pos': [0, 9.5, 0],
                'rot': [0, 0, 0],
                'scale': [1, 1.3, 1]
              },
              'material': {
                'color': '#faf8f5',
                'metalness': 0.3,
                'roughness': 0.2
              }
            }
          ],
          'assets': []
        };
        await _sceneController.loadScene(jsonEncode(tajFallback));
        setState(() => _currentScene = 'Taj Mahal (Local)');
      } else if (sceneName == 'heart') {
        final heartFallback = {
          'meta': {'name': 'Heart', 'gpu_status': 'active'},
          'environment': {
            'skyColor': '#2a0a1e',
            'fogDensity': 0.01,
            'bloomIntensity': 2.0,
            'ground': false
          },
          'primitives': [
            {
              'type': 'sphere',
              'args': [2, 32, 32],
              'transform': {
                'pos': [-1, 2, 0],
                'rot': [0, 0, 0],
                'scale': [1, 1, 1]
              },
              'material': {
                'color': '#ff0044',
                'metalness': 0.1,
                'roughness': 0.2
              }
            },
            {
              'type': 'sphere',
              'args': [2, 32, 32],
              'transform': {
                'pos': [1, 2, 0],
                'rot': [0, 0, 0],
                'scale': [1, 1, 1]
              },
              'material': {
                'color': '#ff0044',
                'metalness': 0.1,
                'roughness': 0.2
              }
            },
            {
              'type': 'cone',
              'args': [2.82, 4, 32],
              'transform': {
                'pos': [0, -0.4, 0],
                'rot': [0, 0, 3.14159],
                'scale': [1, 1, 1]
              },
              'material': {
                'color': '#ff0044',
                'metalness': 0.1,
                'roughness': 0.2
              }
            }
          ],
          'assets': []
        };
        await _sceneController.loadScene(jsonEncode(heartFallback));
        setState(() => _currentScene = 'Heart (Local)');
      } else {
        _showError('No local fallback available for $sceneName');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Reset the UI auto-hide timer
  void _resetUiTimer() {
    _uiHideTimer?.cancel();
    setState(() => _uiVisible = true);
    _uiHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _uiVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetUiTimer(),
        child: Stack(
          children: [
            /// FULLSCREEN WEBVIEW - No GestureDetector wrapper!
            Positioned.fill(
              child: _buildWebView(),
            ),

            /// UI OVERLAY with auto-hide - handles its own touches
            AnimatedOpacity(
              opacity: _uiVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: _buildUIOverlay(),
            ),

            /// SIDEBAR (always visible when open) - handles its own touches
            _buildSidebar(),

            /// LOADING (always visible when loading) - handles its own touches
            if (_isLoading || _isSearching)
              Positioned.fill(child: _buildLoadingOverlay()),
          ],
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialFile: 'assets/www/index.html',
      initialOptions: InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          transparentBackground: true,
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          javaScriptEnabled: true,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
          hardwareAcceleration: true,
        ),
        ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true),
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
        _sceneController.setWebViewController(controller);
        // Add bridge handler for communication from React
        controller.addJavaScriptHandler(
          handlerName: 'onBridgeMessage',
          callback: (args) {
            if (args.isNotEmpty) {
              _handleBridgeMessage(args.first.toString());
            }
          },
        );
      },
      onLoadStart: (controller, url) {
        setState(() => _isLoading = true);
      },
      onLoadStop: (controller, url) {
        setState(() => _isLoading = false);
      },
      onConsoleMessage: (controller, consoleMessage) {
        debugPrint('[WebView Console] ${consoleMessage.message}');
      },
    );
  }

  Widget _buildUIOverlay() {
    return Stack(
      children: [
        /// TOP CONTROL BAR - Compact height
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: Row(
            children: [
              // Menu button
              GlassButton(
                onTap: () {
                  _resetUiTimer();
                  setState(() => _isSidebarOpen = true);
                },
                child: const Icon(Icons.menu, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              // Search container - reduced height
              Expanded(
                child: GlassContainer(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white54, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Visualize...',
                            hintStyle:
                                TextStyle(color: Colors.white38, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (value) {
                            _resetUiTimer();
                            if (value.trim().isNotEmpty) {
                              _loadScene(value.trim());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: GlassButton(
                          onTap: () {
                            _resetUiTimer();
                            if (_searchController.text.trim().isNotEmpty) {
                              _loadScene(_searchController.text.trim());
                            }
                          },
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          child: const Text(
                            'Go',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        /// GESTURE HINT - Positioned below top bar
        Positioned(
          top: 90,
          left: 16,
          right: 16,
          child: Center(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: const Text(
                'Drag to rotate • Pinch to zoom',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),

        /// BOTTOM INFO PANEL - Compact
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Scene info with ellipsis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _currentScene,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const Text(
                        '3D Scene',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // GPU status - compact
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'WebGL',
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      left: _isSidebarOpen ? 0 : -320,
      top: 0,
      bottom: 0,
      width: 320,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx < -10) {
            _resetUiTimer();
            setState(() => _isSidebarOpen = false);
          }
        },
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1A1A2E).withOpacity(0.95),
                    const Color(0xFF0A0A1A).withOpacity(0.98),
                  ],
                ),
                border: const Border(right: BorderSide(color: Colors.white10)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF6366F1),
                                Color(0xFF8B5CF6),
                                Color(0xFFEC4899),
                              ],
                            ).createShader(bounds),
                            child: const Text(
                              'PratibimbAI',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          GlassButton(
                            onTap: () {
                              _resetUiTimer();
                              setState(() => _isSidebarOpen = false);
                            },
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Demo Scenes',
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Demo list
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildDemoTile(
                            '🧪',
                            'Test Cube',
                            'Debug scene injection',
                            'test',
                          ),
                          _buildDemoTile(
                            '🕌',
                            'Taj Mahal',
                            'Iconic marble monument',
                            'taj',
                          ),
                          _buildDemoTile(
                            '❤️',
                            'Heart',
                            'Compositional geometry',
                            'heart',
                          ),
                          _buildDemoTile(
                            '⚛️',
                            'Atom Model',
                            'Educational physics',
                            'atom',
                          ),
                          _buildDemoTile(
                            '🏛️',
                            'Pyramid',
                            'Ancient wonder',
                            'pyramid',
                          ),
                          _buildDemoTile(
                            '🤖',
                            'Robot',
                            'Character design',
                            'robot',
                          ),
                          _buildDemoTile(
                            '🧬',
                            'DNA Helix',
                            'Biology structure',
                            'dna',
                          ),
                          _buildDemoTile(
                            '🌍',
                            'Planet',
                            'Ringed planet',
                            'planet',
                          ),
                          _buildDemoTile(
                            '⛄',
                            'Snowman',
                            'Classic stacked spheres',
                            'snowman',
                          ),
                          _buildDemoTile(
                            '🏠',
                            'House',
                            'Simple architecture',
                            'house',
                          ),
                          _buildDemoTile(
                            '🌲',
                            'Tree',
                            'Nature element',
                            'tree',
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            'Touch to rotate • Pinch to zoom',
                            style: TextStyle(
                              color: Colors.white30,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v1.0.0 • WebGL 2.0',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoTile(String emoji, String name, String desc, String key) {
    return GestureDetector(
      onTap: () => _loadDemoScene(key),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isSearching ? 'Generating 3D Scene...' : 'Loading...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Using compositional geometry',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Controller for communicating with the 3D scene
class SceneController {
  InAppWebViewController? _webViewController;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
  }

  /// Load a scene from JSON blueprint
  Future<void> loadScene(String jsonString) async {
    final controller = _webViewController;
    if (controller == null) {
      debugPrint('SceneController: WebView controller not ready');
      return;
    }

    final safeLog = jsonString.length > 200
        ? '${jsonString.substring(0, 200)}...'
        : jsonString;
    debugPrint('SceneController: Incoming JSON: $safeLog');

    // Properly encode the JSON string as a JavaScript literal
    final jsLiteral = jsonEncode(jsonString);
    final jsCode = "window.loadScene && window.loadScene($jsLiteral)";
    debugPrint('SceneController: Executing JS: ${jsCode.substring(0, 100)}...');

    await controller.evaluateJavascript(source: jsCode);
  }

  /// Load a GLB model
  Future<void> loadGLB(String url) async {
    final controller = _webViewController;
    if (controller == null) return;

    await controller.evaluateJavascript(
      source: "window.loadGLB && window.loadGLB('$url')",
    );
  }

  /// Update environment settings
  Future<void> updateEnvironment(Map<String, dynamic> env) async {
    final controller = _webViewController;
    if (controller == null) return;

    final escapedJson = jsonEncode(env).replaceAll("'", "\\'");
    await controller.evaluateJavascript(
      source:
          "window.updateEnvironment && window.updateEnvironment('$escapedJson')",
    );
  }

  /// Reset the scene
  Future<void> resetScene() async {
    final controller = _webViewController;
    if (controller == null) return;

    await controller.evaluateJavascript(
      source: "window.resetScene && window.resetScene()",
    );
  }

  /// Take a screenshot
  Future<void> takeScreenshot() async {
    // Implementation for screenshot capture
  }
}

/// Glassmorphic container widget
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glassmorphic button widget
class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Gradient? gradient;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? Colors.white.withOpacity(0.1) : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
