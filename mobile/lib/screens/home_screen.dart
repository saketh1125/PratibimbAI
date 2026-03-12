import 'dart:ui';
import 'package:flutter/material.dart';
import 'learn_screen.dart';

/// PratibimbAI Home Screen
/// Apple Vision Pro–inspired dark glassmorphic layout.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // ── Layer 1 — Radial gradient background ──
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.35),
                  radius: 1.2,
                  colors: [
                    Color(0x306366F1), // indigo glow, low opacity
                    Color(0xFF0A0A1A), // deep dark
                  ],
                ),
              ),
            ),
          ),

          // ── Layer 2 + 3 — Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  // ─── Hero Section ───
                  _HeroSection(
                    onLearn: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const LearnScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // ─── Concept Cards Grid ───
                  _ConceptGrid(
                    onCardTap: (String label) {
                      // Demo cards on HomeScreen navigate to viewer passing 'demoSceneJson'
                      // (passing label as placeholder for actual JSON)
                      Navigator.of(context).pushNamed(
                        '/viewer',
                        arguments: '{"meta": {"name": "$label"}}',
                      );
                    },
                  ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Hero Section
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _HeroSection extends StatelessWidget {
  final VoidCallback onLearn;
  const _HeroSection({required this.onLearn});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFF8B5CF6)],
          ).createShader(bounds),
          child: const Text(
            'PratibimbAI',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.white, // needed for shader mask
              height: 1.2,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Tagline
        const Text(
          'Visualize knowledge in 3D',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white54,
            letterSpacing: 0.3,
            height: 1.5,
          ),
        ),

        const SizedBox(height: 32),

        // CTA button
        GestureDetector(
          onTap: onLearn,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Text(
              '✨  Learn Something',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Concept Card Grid
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _ConceptGrid extends StatelessWidget {
  final void Function(String label) onCardTap;
  const _ConceptGrid({required this.onCardTap});

  static const _items = [
    _CardData(emoji: '🧬', label: 'DNA Helix'),
    _CardData(emoji: '⚛️', label: 'Atom Model'),
    _CardData(emoji: '🌍', label: 'Solar System'),
    _CardData(emoji: '❤️', label: 'Human Heart'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: _items.map((item) {
        final width =
            (MediaQuery.of(context).size.width - 24 * 2 - 16) / 2;
        return _GlassCard(
          width: width,
          emoji: item.emoji,
          label: item.label,
          onTap: () => onCardTap(item.label),
        );
      }).toList(),
    );
  }
}

class _CardData {
  final String emoji;
  final String label;
  const _CardData({required this.emoji, required this.label});
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Glass Card
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class _GlassCard extends StatefulWidget {
  final double width;
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _GlassCard({
    required this.width,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  State<_GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<_GlassCard>
    with SingleTickerProviderStateMixin {
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
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: widget.width,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
