import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  Timer? _refreshTimer;
  bool _loading = true;
  bool _refreshing = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll while the conversation is open so incoming messages appear without
    // requiring the user to leave/re-enter the screen.
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshSilently());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchMessages() async {
    final result = await _api.getChatMessages(widget.otherUserId);
    if (result['success'] != true) {
      throw Exception(result['message']?.toString() ?? 'Failed to load messages');
    }
    return (result['data']['messages'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) {
      setState(() => _loading = true);
    }
    try {
      final list = await _fetchMessages();
      if (!mounted) return;
      final shouldStickToBottom = _isNearBottom || _messages.isEmpty;
      setState(() {
        _messages = list;
        _loading = false;
      });
      if (shouldStickToBottom) _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refreshSilently() async {
    if (!mounted || _refreshing || _loading) return;
    _refreshing = true;
    try {
      final list = await _fetchMessages();
      if (!mounted) return;
      final changed = list.length != _messages.length ||
          (list.isNotEmpty && _messages.isNotEmpty && list.last['id']?.toString() != _messages.last['id']?.toString());
      if (changed) {
        final shouldStickToBottom = _isNearBottom;
        setState(() => _messages = list);
        if (shouldStickToBottom) _scrollToBottom();
      }
    } catch (_) {
      // Background refresh failures are intentionally silent; the manual
      // refresh button and pull-to-refresh still provide visible feedback.
    } finally {
      _refreshing = false;
    }
  }

  bool get _isNearBottom {
    if (!_scroll.hasClients) return true;
    return _scroll.position.maxScrollExtent - _scroll.position.pixels < 100;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _manualRefresh() async {
    await _load(showLoader: false);
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final result = await _api.sendChatMessage(
        receiverId: widget.otherUserId,
        message: text,
      );
      if (result['success'] == true) {
        _ctrl.clear();
        await _load(showLoader: false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']?.toString() ?? 'Failed to send')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final meId = context.watch<AuthProvider>().currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
        actions: [
          IconButton(
            tooltip: 'Refresh messages',
            onPressed: _refreshing ? null : _manualRefresh,
            icon: _refreshing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _manualRefresh,
                    child: _messages.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 180),
                              Center(child: Text('No messages yet. Start the conversation.')),
                            ],
                          )
                        : ListView.builder(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final m = _messages[i];
                              final mine = m['senderId']?.toString() == meId;
                              return Align(
                                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                  decoration: BoxDecoration(
                                    color: mine ? AppColors.primary : AppColors.borderLight.withOpacity(0.5),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(mine ? 16 : 4),
                                      bottomRight: Radius.circular(mine ? 4 : 16),
                                    ),
                                  ),
                                  child: Text(
                                    m['message']?.toString() ?? '',
                                    style: TextStyle(color: mine ? Colors.white : null),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
