import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

/// Floating AI assistant button + bottom sheet chat with templates.
class AiChatbotFab extends StatelessWidget {
  const AiChatbotFab({super.key});

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiChatSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _open(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.smart_toy_outlined),
      label: const Text('AI Help'),
    );
  }
}

class AiChatSheet extends StatefulWidget {
  const AiChatSheet();

  @override
  State<AiChatSheet> createState() => AiChatSheetState();
}

class AiChatSheetState extends State<AiChatSheet> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  List<String> _templates = const [
    'What should I do if I miss a dose?',
    'When should I take medicine with food?',
    'What are common side effects of Metformin?',
    'How can I improve adherence?',
    'Is it safe to take medicine with alcohol?',
    'How do I know when to refill stock?',
  ];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'assistant',
      'content':
          'Hi! I am MediTrack Assistant. Pick a quick question or type your own. I share general information only — not personal medical advice.',
    });
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final result = await _api.getAiTemplates();
      if (result['success'] == true) {
        final list = (result['data']['templates'] as List?) ?? [];
        if (list.isNotEmpty && mounted) {
          setState(() {
            _templates = list.map((e) => e.toString()).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending) return;
    setState(() {
      _messages.add({'role': 'user', 'content': msg});
      _sending = true;
    });
    _controller.clear();
    _scrollToEnd();

    try {
      final history = _messages
          .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
          .map((m) => {'role': m['role']!, 'content': m['content']!})
          .toList();
      // exclude the message we just added from duplicate if API uses full history
      final result = await _api.chatWithAi(
        message: msg,
        history: history.length > 1 ? history.sublist(0, history.length - 1) : [],
      );
      final data = result['data'] as Map?;
      var reply = data?['reply']?.toString() ??
          result['message']?.toString() ??
          'Sorry, I could not respond right now.';
      final source = data?['source']?.toString();
      final warning = data?['warning']?.toString();
      if (warning != null && warning.isNotEmpty) {
        reply = '$reply\n\n($warning)';
      } else if (source == 'local' || source == 'local_fallback') {
        // subtle note only when not using OpenAI
        reply = '$reply\n\n— offline mode (set GROQ_API_KEY or GEMINI_API_KEY in backend/.env)';
      }
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': 'Something went wrong: $e',
          });
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final height = MediaQuery.of(context).size.height * 0.78;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'MediTrack AI Assistant',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _templates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final t = _templates[i];
                  return ActionChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    onPressed: _sending ? null : () => _send(t),
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    side: BorderSide(color: AppColors.primary.withOpacity(0.25)),
                  );
                },
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Thinking…', style: TextStyle(color: AppColors.textSecondaryLight)),
                      ),
                    );
                  }
                  final m = _messages[index];
                  final isUser = m['role'] == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.82,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? AppColors.primary
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: isUser
                            ? null
                            : Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        m['content'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : null,
                          height: 1.4,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        decoration: InputDecoration(
                          hintText: 'Ask about doses, side effects…',
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                      onPressed: _sending ? null : () => _send(_controller.text),
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
