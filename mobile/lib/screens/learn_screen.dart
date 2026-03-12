import 'dart:ui';
import 'package:flutter/material.dart';
import 'processing_screen.dart';

/// PratibimbAI – Learn Screen
/// Lets the user type or pick a topic, then navigates to ProcessingScreen.

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  static const _suggestions = [
    'DNA Structure',
    'Solar System',
    'Atom Model',
    'Volcano',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProcessingScreen(query: query),
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
                  center: Alignment(0.0, -0.5),
                  radius: 1.3,
                  colors: [
                    Color(0x256366F1),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'What do you want\nto learn?',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ─── Input field ───
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter:
                                ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.07),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                maxLines: 3,
                                minLines: 2,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                decoration: const InputDecoration(
                                  hintText: 'Visualize anything...',
                                  hintStyle: TextStyle(
                                    color: Colors.white30,
                                    fontSize: 16,
                                  ),
                                  contentPadding: EdgeInsets.all(20),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── Suggestion chips ───
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _suggestions.map((s) {
                            return GestureDetector(
                              onTap: () {
                                _controller.text = s;
                                _controller.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: s.length),
                                );
                                setState(() {}); // rebuild to reflect fill
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _controller.text == s
                                      ? const Color(0xFF6366F1)
                                          .withOpacity(0.25)
                                      : Colors.white.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _controller.text == s
                                        ? const Color(0xFF6366F1)
                                            .withOpacity(0.5)
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    color: _controller.text == s
                                        ? Colors.white
                                        : Colors.white60,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 40),

                        // ─── Generate button ───
                        SizedBox(
                          width: double.infinity,
                          child: GestureDetector(
                            onTap: _submit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.4),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Generate 3D Visualization',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
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

