import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/encryption_helper.dart';
import 'chat_list_screen.dart';

class MessageScreen extends StatefulWidget {
  final String receiverId;
  final String receiverUsername;

  const MessageScreen({
    super.key,
    required this.receiverId,
    required this.receiverUsername,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final supabase = Supabase.instance.client;

  late final String senderId;
  String? avatarUrl;
  Timer? _timer;

  List<int> _searchMatchIndexes = [];
  int _currentMatchIndex = 0;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    senderId = supabase.auth.currentUser!.id;
    _loadReceiverAvatar();
    _startUpdateTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startUpdateTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadReceiverAvatar() async {
    final data = await supabase
        .from('users')
        .select('profile_image_url')
        .eq('id', widget.receiverId)
        .maybeSingle();

    setState(() {
      avatarUrl = data?['profile_image_url'];
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final encryptedText = EncryptionHelper.encryptText(text);

    await supabase.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': widget.receiverId,
      'message': encryptedText,
      'seen': false,
    });

    _messageController.clear();
    setState(() {});
  }

  Future<void> _markMessagesAsSeen(List<Map<String, dynamic>> messages) async {
    final unseenMessages = messages.where((m) =>
        m['receiver_id'] == senderId &&
        m['sender_id'] == widget.receiverId &&
        m['seen'] == false).toList();

    if (unseenMessages.isNotEmpty) {
      final unseenIds = unseenMessages.map((m) => m['id']).toList();
      await supabase
          .from('messages')
          .update({
            'seen': true,
            'seen_at': DateTime.now().toIso8601String(),
          })
          .filter('id', 'in', unseenIds);
    }
  }

  String formatTimestamp(dynamic timestampInput) {
    if (timestampInput == null) return '';
    DateTime timestamp;
    try {
      if (timestampInput is DateTime) {
        timestamp = timestampInput.toLocal();
      } else if (timestampInput is String) {
        timestamp = DateTime.parse(timestampInput).toLocal();
      } else {
        return '';
      }
    } catch (e) {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final msgDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (now.difference(timestamp).inMinutes < 1) {
      return "Just now";
    } else if (msgDate == today) {
      return "Sent at ${DateFormat.jm().format(timestamp)}";
    } else if (msgDate == yesterday) {
      return "Sent Yesterday at ${DateFormat.jm().format(timestamp)}";
    } else if (msgDate.isAfter(startOfWeek)) {
      return "Sent on ${DateFormat.E().format(timestamp)} at ${DateFormat.jm().format(timestamp)}";
    } else {
      return "Sent on ${DateFormat('MM/dd/yy').format(timestamp)} at ${DateFormat.jm().format(timestamp)}";
    }
  }

  void _searchMessages() {
    setState(() {
      _searchMatchIndexes.clear();
      _currentMatchIndex = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_searchMatchIndexes.isNotEmpty) {
        _scrollToMatch(0);
      }
    });
  }

  void _scrollToMatch(int index) {
    if (_searchMatchIndexes.isEmpty) return;
    final targetIndex = _searchMatchIndexes[index];
    _scrollController.animateTo(
      targetIndex * 100.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextMatch() {
    if (_searchMatchIndexes.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatchIndexes.length;
    });
    _scrollToMatch(_currentMatchIndex);
  }

  void _previousMatch() {
    if (_searchMatchIndexes.isEmpty) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatchIndexes.length) % _searchMatchIndexes.length;
    });
    _scrollToMatch(_currentMatchIndex);
  }

  void _toggleSearchBar() {
    setState(() {
      _isSearching = !_isSearching;
      _searchController.clear();
      _searchMatchIndexes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF700100),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                child: avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                '@${widget.receiverUsername}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: _toggleSearchBar,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _searchMessages(),
                        decoration: InputDecoration(
                          hintText: 'Search messages...',
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: _previousMatch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward),
                      onPressed: _nextMatch,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _toggleSearchBar,
                    )
                  ],
                ),
              ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('messages')
                    .select()
                    .or('sender_id.eq.$senderId,receiver_id.eq.$senderId')
                    .order('timestamp', ascending: true),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final messages = snapshot.data!
                      .where((m) =>
                          (m['sender_id'] == senderId && m['receiver_id'] == widget.receiverId) ||
                          (m['receiver_id'] == senderId && m['sender_id'] == widget.receiverId))
                      .toList();
                  _markMessagesAsSeen(messages);
                  _searchMatchIndexes.clear();

                  if (messages.isEmpty) {
                    return Center(
                      child: Text("You're now chatting with @${widget.receiverUsername}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['sender_id'] == senderId;
                      String decryptedText;
                      try {
                        decryptedText = EncryptionHelper.decryptText(msg['message']);
                      } catch (e) {
                        decryptedText = '[Unable to decrypt]';
                      }

                      if (_searchController.text.isNotEmpty &&
                          decryptedText.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        _searchMatchIndexes.add(index);
                      }

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: GestureDetector(
                          onLongPress: () async {
                            if (isMe) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  title: const Text('Unsend Message', style: TextStyle(color: Color(0xFF700100))),
                                  content: const Text('Are you sure you want to unsend this message?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Unsend', style: TextStyle(color: Color(0xFF700100)))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await supabase.from('messages').delete().eq('id', msg['id']);
                                setState(() {});
                              }
                            }
                          },
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFFF6C401) : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(decryptedText),
                              ),
                              Text(formatTimestamp(msg['timestamp']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              if (isMe && msg['seen'] == true && msg['seen_at'] != null)
                                Text('✓ Seen ${formatTimestamp(msg['seen_at'])}', style: const TextStyle(fontSize: 10, color: Colors.green)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.send, color: Color(0xFF700100)), onPressed: _sendMessage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
