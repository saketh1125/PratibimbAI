import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../models/visualize_result.dart';
import '../services/visualize_result_provider.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

/// PratibimbAI – Processing Screen
/// Animated loading state with rotating status messages.
/// Auto-navigates to ResultScreen after 3 seconds.

class ProcessingScreen extends StatefulWidget {
  final String query;
  final bool dataSaver;
  const ProcessingScreen({super.key, required this.query, bool? dataSaver})
      : dataSaver = dataSaver ?? false;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  static const _messages = [
    'Understanding concept',
    'Building scene',
    'Preparing explanation',
  ];

  int _messageIndex = 0;
  Timer? _rotateTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startMessageRotation();
    _callApi();
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startMessageRotation() {
    _rotateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _messages.length;
        });
      }
    });
  }

  Future<void> _callApi() async {
    try {
      final network = widget.dataSaver ? 'slow' : await detectNetworkSpeed();
      final result = await ApiService.visualize(
        widget.query,
        style: 'educational',
        complexity: 'high',
        network: network,
        dataSaver: widget.dataSaver,
      );

      if (mounted) {
        _navigateToResult(result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Future<String> detectNetworkSpeed() async {
    const testUrl =
        'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png';
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse(testUrl))
          .timeout(const Duration(seconds: 3));
      stopwatch.stop();
      final bytes = response.bodyBytes.length;
      final seconds = stopwatch.elapsedMilliseconds / 1000;
      if (seconds == 0) return 'fast';
      final mbps = (bytes * 8) / seconds / 1e6;
      return mbps < 3 ? 'slow' : 'fast';
    } catch (_) {
      return 'fast';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to generate visualization: $message'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _callApi();
          },
        ),
      ),
    );
  }

  void _navigateToResult(VisualizeResult result) {
    if (!mounted) return;
    // Store result in provider for cross-screen persistence
    context.read<VisualizeResultProvider>().setResult(result);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => ResultScreen(
          query: result.query,
          blueprintJson: result.blueprintJson,
          explanation: result.explanation,
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // ── Background glow ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.15),
                  radius: 0.9,
                  colors: [
                    Color(0x306366F1),
                    Color(0xFF0A0A1A),
                  ],
                ),
              ),
            ),
          ),

          // ── Centered content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated spinner ring
                _AnimatedRing(controller: _pulseController),

                const SizedBox(height: 40),

                // Title
                const Text(
                  'Generating your\nvisualization…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                    letterSpacing: -0.3,
                  ),
                ),

                const SizedBox(height: 12),

                // Query label
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    '"${widget.query}"',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Rotating status message
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.15),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Row(
                    key: ValueKey(_messageIndex),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _messages[_messageIndex],
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Animated ring around the center
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _AnimatedRing extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedRing({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring (pulsing)
          AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final scale = 1.0 + controller.value * 0.08;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1)
                            .withOpacity(0.15 + controller.value * 0.1),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Spinning arc
          const SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
            ),
          ),

          // Center dot
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
