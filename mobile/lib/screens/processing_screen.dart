import 'dart:async';
import 'package:flutter/material.dart';
import 'result_screen.dart';

/// PratibimbAI – Processing Screen
/// Animated loading state with rotating status messages.
/// Auto-navigates to ResultScreen after 3 seconds.

class ProcessingScreen extends StatefulWidget {
  final String query;
  const ProcessingScreen({super.key, required this.query});

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
  Timer? _navTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for the ring
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Rotate status text every 2 s
    _rotateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
      }
    });

    // Auto-navigate after 3 s
    _navTimer = Timer(const Duration(seconds: 3), _navigateToResult);
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    _navTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToResult() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) =>
            ResultScreen(query: widget.query),
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
                          valueColor:
                              AlwaysStoppedAnimation(Color(0xFF6366F1)),
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
