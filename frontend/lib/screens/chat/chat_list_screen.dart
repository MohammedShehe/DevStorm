import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/page_transitions.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _api = ApiService();
  bool _loading = true;
  List<Map<String, dynamic>> _partners = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getChatConversations();
      if (result['success'] == true) {
        final list = (result['data']['partners'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() {
          _partners = list;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message']?.toString();
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _partners.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No linked contacts yet.\nLink a caregiver or patient first to start chatting.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _partners.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = _partners[i];
                        final name = p['fullName']?.toString() ?? 'User';
                        final email = p['email']?.toString() ?? '';
                        final id = p['id']?.toString() ?? '';
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(email),
                          onTap: () => pushFadeSlide(
                            context,
                            ChatScreen(otherUserId: id, otherUserName: name),
                          ),
                        );
                      },
                    ),
    );
  }
}
