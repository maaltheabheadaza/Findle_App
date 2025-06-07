import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/encryption_helper.dart';
import 'chat_list_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';


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

  File? _selectedImage;

  Future<void> _showImagePickerDialog() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo),
            title: const Text('Pick from Gallery'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) _uploadAndSendImage(File(picked.path));
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take a Picture'),
            onTap: () async {
              Navigator.pop(context);
              final picked = await picker.pickImage(source: ImageSource.camera);
              if (picked != null) _uploadAndSendImage(File(picked.path));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _uploadAndSendImage(File image) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
    try {
      await Supabase.instance.client.storage
        .from('ad-images') // existing storage bucket
        .upload(fileName, image);

      final imageUrl = Supabase.instance.client.storage
        .from('ad-images')
        .getPublicUrl(fileName);

      await supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': widget.receiverId,
        'message': '', // No text
        'image_url': imageUrl,
        'seen': false,
      });

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send image: $e')),
      );
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
      Navigator.pop(context);  // Just pop back to previous screen
      return false;            // Prevent default system back behavior
    },
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF700100),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);  // Also just pop when back arrow pressed
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

                      final messageText = (msg['message'] as String?)?.trim() ?? '';
                      final imageUrl = (msg['image_url'] as String?)?.trim();

                      // ❌ Skip rendering if both are empty
                      if (messageText.isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
                        return const SizedBox.shrink();
                      }

                      String decryptedText = '';
                      final hasText = messageText.isNotEmpty;
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;

                      if (hasText) {
                        try {
                          decryptedText = EncryptionHelper.decryptText(msg['message']);
                        } catch (e) {
                          decryptedText = '[Unable to decrypt]';
                        }
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
                                TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
                                TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Unsend', style: TextStyle(color: Color(0xFF700100)))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            // Delete image if present
                            if (msg['image_url'] != null && msg['image_url'].toString().isNotEmpty) {
                              final imagePath = Uri.parse(msg['image_url']).pathSegments.last;
                              await Supabase.instance.client.storage
                                  .from('ad-images') // your bucket
                                  .remove([imagePath]);
                            }
                            // Delete the message
                            await supabase.from('messages').delete().eq('id', msg['id']);
                            setState(() {});
                          }
                        }
                      },
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (hasImage)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullImageScreen(imageUrl: imageUrl!),
                                    ),
                                  );
                                },
                                child: Image.network(
                                  imageUrl!,
                                  width: 200,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Center(child: CircularProgressIndicator()),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 200,
                                      height: 200,
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                                    );
                                  },
                                ),
                              ),
                            ),
                          if (hasText)
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
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: _showImagePickerDialog,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFF700100)),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class FullImageScreen extends StatelessWidget {
  final String imageUrl;

  const FullImageScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.broken_image, color: Colors.white, size: 60);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const CircularProgressIndicator(color: Colors.white);
              },
            ),
          ),
        ),
      ),
    );
  }
}

