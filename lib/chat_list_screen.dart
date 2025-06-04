import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart';
import '../utils/encryption_helper.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final supabase = Supabase.instance.client;
  late final String currentUserId;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allChats = [];
  List<Map<String, dynamic>> _filteredChats = [];
  bool _isLoading = true; // Added loading flag

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser!.id;
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true); // Start loading

    final messages = await supabase
        .from('messages')
        .select('id, sender_id, receiver_id, message, timestamp, seen')
        .order('timestamp', ascending: false);

    final uniqueConversations = <String, Map<String, dynamic>>{};

    for (var msg in messages) {
      final otherUserId = msg['sender_id'] == currentUserId
          ? msg['receiver_id']
          : msg['sender_id'];

      if (!uniqueConversations.containsKey(otherUserId)) {
        uniqueConversations[otherUserId] = msg;
      }
    }

    final chatList =
        uniqueConversations.entries.map((entry) => entry.value).toList();

    for (var convo in chatList) {
      final otherUserId = convo['sender_id'] == currentUserId
          ? convo['receiver_id']
          : convo['sender_id'];

      final userInfo = await supabase
          .from('users')
          .select('username, profile_image_url')
          .eq('id', otherUserId)
          .maybeSingle();

      convo['other_user_id'] = otherUserId;
      convo['username'] = userInfo?['username'] ?? 'Unknown';
      convo['profile_image_url'] = userInfo?['profile_image_url'];
    }

    setState(() {
      _allChats = chatList;
      _filteredChats = chatList;
      _isLoading = false; // Done loading
    });
  }

  void _filterChats(String query) {
    final filtered = _allChats.where((chat) {
      final username = chat['username']?.toLowerCase() ?? '';
      return username.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredChats = filtered;
    });
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }

  Future<void> _deleteConversation(String otherUserId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .or('and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete conversation')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF700100),
        title: const Text('Chats', style: TextStyle(color: Colors.white)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterChats,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allChats.isEmpty
              ? const Center(child: Text('No chats yet.'))
              : _filteredChats.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : ListView.builder(
                      itemCount: _filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
                        String decryptedLastMessage;
                        try {
                          decryptedLastMessage =
                              EncryptionHelper.decryptText(chat['message']);
                        } catch (_) {
                          decryptedLastMessage = '[Encrypted message]';
                        }

                        final DateTime timestamp =
                            DateTime.parse(chat['timestamp']);
                        final bool isUnread =
                            chat['sender_id'] != currentUserId &&
                                (chat['seen'] == false);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: chat['profile_image_url'] != null
                                ? NetworkImage(chat['profile_image_url'])
                                : null,
                            child: chat['profile_image_url'] == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '@${chat['username']}',
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            decryptedLastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          onTap: () async {
                            await supabase
                                .from('messages')
                                .update({'seen': true})
                                .match({
                                  'sender_id': chat['other_user_id'],
                                  'receiver_id': currentUserId,
                                });

                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessageScreen(
                                  receiverId: chat['other_user_id'],
                                  receiverUsername: chat['username'],
                                ),
                              ),
                            );

                            _loadConversations();
                          },
                          onLongPress: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Conversation?'),
                                content: Text(
                                  'This will also delete it for @${chat['username']}',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _deleteConversation(chat['other_user_id']);
                              _loadConversations();
                            }
                          },
                        );
                      },
                    ),
    );
  }
}
