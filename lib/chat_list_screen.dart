import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'message_screen.dart';

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
  List<Map<String, dynamic>> _searchResults = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    currentUserId = supabase.auth.currentUser!.id;
    _loadConversations();

    _searchController.addListener(() {
      _filterChats(_searchController.text.trim());
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);

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

    final chatList = uniqueConversations.entries.map((entry) => entry.value).toList();

    // Fetch user info for each conversation
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
      _searchResults = [];
      _isLoading = false;
    });
  }

  Future<void> _filterChats(String query) async {
    if (query.isEmpty) {
      // Show chat list when search is cleared
      setState(() {
        _filteredChats = _allChats;
        _searchResults = [];
      });
    } else {
      // Search all users by username in supabase excluding current user
      final response = await supabase
          .from('users')
          .select('id, username, profile_image_url')
          .ilike('username', '%$query%')
          .neq('id', currentUserId)
          .limit(20);

      final List<Map<String, dynamic>> results =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        _searchResults = results;
        _filteredChats = []; // hide chat list while showing search results
      });
    }
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
          .or(
            'and(sender_id.eq.$currentUserId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$currentUserId)',
          );
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchController.text.trim().isNotEmpty;

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
                suffixIcon: isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterChats('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isSearching
              ? (_searchResults.isEmpty
                  ? const Center(child: Text('No results found.'))
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: user['profile_image_url'] != null
                                ? NetworkImage(user['profile_image_url'])
                                : null,
                            child: user['profile_image_url'] == null
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          title: Text('@${user['username']}'),
                          onTap: () async {
                            // Open chat screen for that user
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MessageScreen(
                                  receiverId: user['id'],
                                  receiverUsername: user['username'],
                                ),
                              ),
                            );
                            // Reload conversations after return
                            _loadConversations();
                          },
                        );
                      },
                    ))
              : _allChats.isEmpty
                  ? const Center(child: Text('No chats yet.'))
                  : _filteredChats.isEmpty
                      ? const Center(child: Text('No results found.'))
                      : ListView.builder(
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            final String lastMessage = chat['message'] ?? '[No message]';
                            final DateTime timestamp = DateTime.parse(chat['timestamp']);
                            final bool isUnread = chat['sender_id'] != currentUserId && (chat['seen'] == false);

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
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
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
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
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
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
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
