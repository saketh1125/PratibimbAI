import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// PratibimbAI – Explanation Screen
/// Displays AI-generated explanation with text-to-speech support.

class ExplanationScreen extends StatefulWidget {
  final String explanation;
  const ExplanationScreen({super.key, required this.explanation});

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _tts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _tts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> speakExplanation() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() {
        _isSpeaking = false;
      });
    } else {
      await _tts.speak(widget.explanation);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      body: Stack(
        children: [
          // Background gradient
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

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'AI Explanation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Voice button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: speakExplanation,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _isSpeaking
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _isSpeaking
                                      ? const Color(0xFF6366F1).withOpacity(0.5)
                                      : Colors.white.withOpacity(0.12),
                                ),
                              ),
                              child: Icon(
                                _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                                color: _isSpeaking ? const Color(0xFF6366F1) : Colors.white70,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Explanation text
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.explanation,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.6,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom hint
                if (!_isSpeaking)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white54,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Tap the speaker icon to listen',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
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
