import 'package:flutter/material.dart';
import 'explanation_screen.dart';

/// PratibimbAI – Result Screen
/// Shows the completed visualization with three action buttons.

class ResultScreen extends StatelessWidget {
  final String query;
  final String? blueprintJson;
  final String? explanation;
  const ResultScreen(
      {super.key, required this.query, this.blueprintJson, this.explanation});

  void _playExplanationAudio(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔊 Audio explanation coming soon…'),
        backgroundColor: Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
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
                  center: Alignment(0.0, -0.4),
                  radius: 1.1,
                  colors: [
                    Color(0x286366F1),
                    Color(0xFF0A0A1A),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──
          SafeArea(
            child: Column(
              children: [
                // ─── Top bar ───
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70, size: 20),
                      ),
                    ],
                  ),
                ),

                // ─── Body ───
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success icon
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF6366F1).withOpacity(0.35),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 36),
                        ),

                        const SizedBox(height: 28),

                        // Topic title
                        Text(
                          query,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Subtitle
                        const Text(
                          'Your AI visualization is ready.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white54,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 48),

                        // ─── Action buttons ───
                        _GradientActionButton(
                          icon: Icons.view_in_ar_rounded,
                          label: 'View 3D Model',
                          onTap: () {
                            if (blueprintJson != null) {
                              Navigator.of(context).pushNamed(
                                '/viewer',
                                arguments: blueprintJson,
                              );
                            } else {
                              Navigator.of(context).pushNamed(
                                '/viewer',
                                arguments: '{"meta": {"name": "$query"}}',
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        _GradientActionButton(
                          icon: Icons.article_rounded,
                          label: 'Read Explanation',
                          outlined: true,
                          onTap: () {
                            if (explanation != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExplanationScreen(
                                      explanation: explanation!),
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        _GradientActionButton(
                          icon: Icons.headphones_rounded,
                          label: 'Listen Explanation',
                          outlined: true,
                          onTap: () {
                            if (explanation != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ExplanationScreen(
                                      explanation: explanation!),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
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
//  Gradient / Outlined Action Button
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GradientActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _GradientActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  State<_GradientActionButton> createState() => _GradientActionButtonState();
}

class _GradientActionButtonState extends State<_GradientActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: widget.outlined
              ? BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.12),
                  ),
                )
              : BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
