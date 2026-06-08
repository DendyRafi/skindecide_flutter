import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'shared_widgets.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();

  final List<Map<String, String>> _messages = [];
  final List<Map<String, String>> _conversation = [];
  bool _isLoading = false;

  static const String _apiKey =
      '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';
  static const String _model = 'openai/gpt-oss-20b';

  static const String _systemPrompt = '''
Anda adalah "SkinDecide AI Assistant", agen cerdas virtual khusus untuk aplikasi SkinDecide yang dikembangkan oleh mahasiswa Teknik Informatika TI 4B Politeknik Negeri Jakarta.

Aplikasi ini berfungsi sebagai Sistem Pendukung Keputusan (SPK) pemilihan item skin Mobile Legends menggunakan metode PROMETHEE (Preference Ranking Organization Method for Enrichment Evaluation).

PANDUAN PENGETAHUAN UTAMA ANDA (wajib dipatuhi):
1. Kriteria Penilaian Sistem:
   - Kategori Skin (Atribut Benefit, Skala Input: 1 sampai 6, Tier: [Common, Exceptional, Deluxe, Exquisite, Grand, Legend], Default: Common).
   - Kualitas Desain Model / Estetika (Atribut Benefit, Skala Input: 1 sampai 7, Tier: [Sangat Kurang...Standar...Sangat Bagus], Default: Standar).
   - Kualitas Potret Grafis (Atribut Benefit, Skala Input: 1 sampai 7, Tier: [Sangat Kurang...Standar...Sangat Bagus], Default: Standar).
   - Kualitas Animasi Transisi / Entrance (Atribut Benefit, Skala Input: 1 sampai 7, Tier: [Sangat Kurang...Standar...Sangat Bagus], Default: Standar).
   - Kualitas Efek Visual Permainan / In-Game Effect (Atribut Benefit, Skala Input: 1 sampai 7, Tier: [Sangat Kurang...Standar...Sangat Bagus], Default: Standar).
   - Tingkat Preferensi Penggunaan Hero (Atribut Benefit, Skala Input: 1 sampai 7, Tier: [Tidak Pernah Dipakai, Sangat Jarang Dipakai, Jarang Dipakai, Kadang Kadang, Sering Dipakai, Sangat Sering Dipakai, Hero Andalan Utama (Signature)], default: Kadang Kadang).
   - Harga Perolehan / Finansial (Atribut Cost, diinput dalam satuan Diamond (Integer)).

2. Mekanisme Komputasi Metode PROMETHEE:
   Sistem memproses data lewat tahap normalisasi matriks, pembobotan dinamis sesuai preferensi personal, dan perhitungan aliran preferensi: Leaving Flow, Entering Flow, dan Net Flow. Alternatif dengan Net Flow tertinggi direkomendasikan sebagai pilihan terbaik.

3. Tujuan Utama Proyek:
   Membantu gamer mengambil keputusan pembelian virtual goods secara objektif, transparan, logis, mengoptimalkan alokasi finansial, serta meminimalkan keputusan impulsif akibat bias emosional.

GAYA BAHASA:
Jawab dengan ramah, tanpa emote, ringkas, solutif, dan sesekali gunakan istilah dunia game secara profesional.
''';

  // ─── Quick suggestion chips ───────────────────────────────────────────────
  static const List<String> _suggestions = [
    'Apa itu metode PROMETHEE?',
    'Bagaimana cara menghitung Net Flow?',
    'Apa perbedaan Leaving & Entering Flow?',
    'Skala penilaian kriteria apa saja?',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text':
          'WELCOME COMMANDER! Saya adalah SkinDecide AI Assistant. Siap membantu Anda memahami kriteria penilaian atau cara kerja metode PROMETHEE.',
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> askGroq(String message) async {
    final uri = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _systemPrompt},
      ..._conversation,
      {'role': 'user', 'content': message},
    ];

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'model': _model,
        'messages': messages,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String reply =
        data['choices']?[0]?['message']?['content']?.toString().trim() ?? '';
    if (reply.isEmpty) {
      throw Exception('Groq tidak mengembalikan jawaban.');
    }
    return reply;
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    _controller.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _conversation.add({'role': 'user', 'content': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final responseText = await askGroq(text);
      setState(() {
        _messages.add({'role': 'bot', 'text': responseText});
        _conversation.add({'role': 'assistant', 'content': responseText});
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'bot',
          'text':
              'Maaf, terjadi kesalahan saat menghubungi server AI. Silakan coba lagi beberapa saat.',
        });
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  // Tampilkan suggestion chips hanya jika percakapan masih berisi 1 pesan (welcome)
  bool get _showSuggestions => _messages.length == 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceInk,
      body: AppBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              _ChatTopBar(onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  // +1 untuk baris suggestion chips
                  itemCount: _messages.length + (_showSuggestions ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Suggestion chips muncul setelah pesan pertama (index 1)
                    if (_showSuggestions && index == 1) {
                      return _SuggestionChips(
                        suggestions: _suggestions,
                        onTap: _sendMessage,
                      );
                    }
                    final msgIndex =
                        _showSuggestions && index > 1 ? index - 1 : index;
                    final msg = _messages[msgIndex];
                    final isUser = msg['role'] == 'user';
                    if (isUser) {
                      return _UserBubble(text: msg['text'] ?? '');
                    }
                    return _BotBubble(text: msg['text'] ?? '');
                  },
                ),
              ),
              if (_isLoading) const _TypingIndicator(),
              _ChatInputBar(
                controller: _controller,
                focusNode: _inputFocusNode,
                isLoading: _isLoading,
                onSend: () => _sendMessage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _ChatTopBar extends StatelessWidget {
  const _ChatTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: kSurfaceDark.withValues(alpha: 0.88),
        border: const Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Column(
        children: [
          // Baris atas: tombol kembali + status badge
          Row(
            children: [
              GlassActionButton(label: '← KEMBALI', onTap: onBack),
              const Spacer(),
              const _OnlineBadge(),
            ],
          ),
          const SizedBox(height: 10),
          // Baris bawah: avatar + nama + subtitle
          Row(
            children: [
              const _BotAvatar(size: 38),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SKINDECIDE AI ASSISTANT',
                    style: GoogleFonts.orbitron(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Powered by Groq · Llama 3.3 70B',
                    style: GoogleFonts.syne(
                      fontSize: 9.5,
                      color: kTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Garis aksen hijau gradient (seperti home_screen)
          Container(
            height: 1.5,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  kAccentGreen.withValues(alpha: 0.85),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Online Badge ─────────────────────────────────────────────────────────────

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kAccentGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kAccentGreen.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: kAccentGreen,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kAccentGreen.withValues(alpha: 0.55),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'ONLINE',
            style: GoogleFonts.orbitron(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: kAccentGreen,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bot Avatar ───────────────────────────────────────────────────────────────

class _BotAvatar extends StatelessWidget {
  const _BotAvatar({this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kAccentGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: kAccentGreen.withValues(alpha: 0.30)),
      ),
      child: Icon(
        Icons.smart_toy_rounded,
        color: kAccentGreen,
        size: size * 0.52,
      ),
    );
  }
}

// ─── User Avatar ──────────────────────────────────────────────────────────────

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kAccentGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: kAccentGreen.withValues(alpha: 0.40)),
      ),
      child: Icon(
        Icons.person_rounded,
        color: kAccentGreen,
        size: size * 0.52,
      ),
    );
  }
}

// ─── Suggestion Chips ─────────────────────────────────────────────────────────

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.suggestions,
    required this.onTap,
  });

  final List<String> suggestions;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PERTANYAAN CEPAT',
            style: GoogleFonts.orbitron(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: kTextMuted,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () => onTap(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1016),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder),
                  ),
                  child: Text(
                    s,
                    style: GoogleFonts.syne(
                      fontSize: 11.5,
                      color: kTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

// ─── User Bubble ──────────────────────────────────────────────────────────────

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kAccentGreen,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: kAccentGreen.withValues(alpha: 0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: GoogleFonts.syne(
                  fontSize: 13.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _UserAvatar(),
        ],
      ),
    );
  }
}

// ─── Bot Bubble ───────────────────────────────────────────────────────────────

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _BotAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: kSurfaceDark.withValues(alpha: 0.92),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
                border: Border.all(color: kBorder),
              ),
              child: Text(
                text,
                style: GoogleFonts.syne(
                  fontSize: 13.5,
                  color: kTextPrimary,
                  height: 1.55,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _BotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: kSurfaceDark.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(
                    color: kAccentGreen,
                    strokeWidth: 1.8,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI sedang menganalisis kriteria...',
                  style: GoogleFonts.syne(
                    color: kTextMuted,
                    fontSize: 12,
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

// ─── Input Bar ────────────────────────────────────────────────────────────────

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kSurfaceDark.withValues(alpha: 0.96),
        border: const Border(top: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            // Focus + onKeyEvent: Enter = kirim, Shift+Enter = baris baru
            // Berlaku di semua platform (web, desktop, mobile)
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed) {
                  if (!isLoading) onSend();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: GoogleFonts.syne(
                  color: kTextPrimary,
                  fontSize: 13.5,
                ),
                maxLines: 4,
                minLines: 1,
                // TextInputAction.send: keyboard mobile tampilkan tombol "Send"
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText:
                      'Tanya kriteria, skala, atau cara kerja PROMETHEE...',
                  hintStyle: GoogleFonts.syne(
                    color: kTextMuted.withValues(alpha: 0.70),
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0B1016),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: kAccentGreen,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send button — sama persis style NeonPrimaryButton
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: kAccentGreen.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccentGreen,
                disabledBackgroundColor: kAccentGreen.withValues(alpha: 0.40),
                foregroundColor: Colors.black,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}