import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'homepage_screen.dart'; // Make sure PostDetailScreen is here or update import
import 'lost_and_found.dart';

// Custom colors
class AppColors {
  static const Color maroon = Color(0xFF800000);
  static const Color white = Colors.white;
  static const Color gray = Colors.grey;
  static const Color darkGray = Color(0xFF4F4F4F);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color paleYellow = Color(0xFFFFF9C4);
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  final Map<String, String> _usernames = {};
  final Map<String, String> _profileImages = {};

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userPostsResponse = await Supabase.instance.client
          .from('post')
          .select('category, post_type')
          .eq('user_id', currentUser.id) as List;

      if (userPostsResponse.isEmpty) {
        setState(() {
          _notifications = [];
          _isLoading = false;
        });
        return;
      }

      // Prepare filter list
      final filters = userPostsResponse.map<Map<String, String>>((post) {
        final category = post['category'] ?? '';
        final postType = post['post_type'] ?? '';
        final oppositePostType =
            postType.toLowerCase() == 'lost' ? 'found' : 'lost';
        return {
          'category': category,
          'post_type': oppositePostType,
        };
      }).toList();

      // Fetch all notifications with related posts
      final notificationsResponse = await Supabase.instance.client
          .from('notifications')
          .select('*, post:post!notifications_post_id_fkey(*), user:users(*)')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);
  

      final allNotifications =
          List<Map<String, dynamic>>.from(notificationsResponse ?? []);

      // Manual filter
      final filtered = allNotifications.where((notif) {
        final post = notif['post'] as Map<String, dynamic>?;
        if (post == null) return false;
        final postCategory = post['category'] ?? '';
        final postType = post['post_type']?.toLowerCase() ?? '';
        final postUserId = post['user_id'];

        return filters.any((filter) =>
            filter['category'] == postCategory &&
            filter['post_type'] == postType);
      }).toList();

      // Get all unique user IDs from posts
      final userIds = filtered
          .where((notif) => notif['post']?['user_id'] != null)
          .map((notif) => notif['post']['user_id'])
          .toSet()
          .toList();

      if (userIds.isNotEmpty) {
        try {
          final usersResponse = await Supabase.instance.client
              .from('users')
              .select('id, username, profile_image_url')
              .inFilter('id', userIds);

          final users = List<Map<String, dynamic>>.from(usersResponse);
          setState(() {
            for (var user in users) {
              _usernames[user['id']] = user['username'];
              _profileImages[user['id']] = user['profile_image_url'];
            }
          });
        } catch (e) {
          print('Error fetching usernames: $e');
        }
      }

      setState(() {
        _notifications = filtered;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

Future<void> markAllAsRead() async {
  try {
    for (final notif in _notifications) {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notif['id']);
    }

    await _fetchNotifications(); // Refresh list
  } catch (e) {
    print('❌ Error marking all as read: $e');
  }
}

Future<void> _deleteNotification(String notificationId) async {
  try {
    final response = await Supabase.instance.client
        .from('notifications')
        .delete()
        .eq('id', notificationId)
        .select(); // <- ADD THIS LINE to force a real response

    print('Delete response: $response');

    if (response == null || response.isEmpty) {
      print('❌ Delete failed: No rows deleted');
      return;
    }

    print('✅ Notification deleted from Supabase');
  } catch (e) {
    print('❌ Exception deleting notification: $e');
  }
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFFBF0), // Warm white background
    appBar: AppBar(
      centerTitle: false,
      backgroundColor: Color.fromARGB(255, 112, 1, 0),
      iconTheme: const IconThemeData(color: Colors.white), // Maroon
      elevation: 0,
      shadowColor: Colors.black12,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Notifications',
        style: TextStyle(
          color: Colors.white, // Maroon
          fontWeight: FontWeight.w700,
          fontSize: 24,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DC), // Light yellow
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.done_all_rounded,
                size: 18,
                color: Color.fromARGB(255, 1112, 1, 0), // Maroon
              ),
            ),
            tooltip: 'Mark all as read',
            onPressed: markAllAsRead,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 12),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8DC), // Light yellow
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Color.fromARGB(255, 1112, 1, 0), // Maroon
              ),
            ),
            tooltip: 'Refresh',
            onPressed: _fetchNotifications,
          ),
        ),
      ],
    ),
    body: _isLoading
        ? const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color.fromARGB(255, 1112, 1, 0),// Maroon
            ),
          )
        : _notifications.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8DC), // Light yellow
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color.fromARGB(255, 1112, 1, 0).withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 48,
                        color: Color.fromARGB(255, 1112, 1, 0), // Maroon
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No notifications yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 1112, 1, 0), // Maroon
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'When you get notifications, they\'ll show up here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B4E71), // Muted maroon
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notification = _notifications[index];
                          final post = notification['post'] as Map<String, dynamic>?;
                          final isUnread = notification['is_read'] != true;


                           return Dismissible(
                                  key: Key(notification['id'].toString()),
                                  direction: DismissDirection.endToStart, // swipe left only
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(left: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                 onDismissed: (direction) async {
                                    final notificationId = notification['id'];

                                    await _deleteNotification(notificationId.toString());

                                    // Re-fetch notifications to confirm
                                    await _fetchNotifications();

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Notification deleted')),
                                    );
                                  },
                          child : Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isUnread
                                  ? Border.all(
                                      color: const Color(0xFFFFD700).withOpacity(0.6), // Golden yellow
                                      width: 2,
                                    )
                                  : Border.all(
                                      color: const Color(0xFFF5F5F5),
                                      width: 1,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                                if (isUnread)
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.15), // Golden yellow shadow
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (post != null) {
                                    _markAsRead(notification['id']);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostDetailScreen(
                                          post: post,
                                          usernames: _usernames,
                                          profileImages: _profileImages,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: isUnread
                                        ? LinearGradient(
                                            colors: [
                                              const Color(0xFFFFFDF7), // Very light yellow
                                              Colors.white,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Modern notification icon
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isUnread
                                                  ? [
                                                      const Color.fromARGB(255, 1112, 1, 0), // Maroon
                                                      const Color.fromARGB(255, 1112, 1, 0), // Lighter maroon
                                                    ]
                                                  : [
                                                      const Color(0xFFFFF8DC), // Light yellow
                                                      const Color(0xFFFFF0CD), // Slightly darker yellow
                                                    ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isUnread 
                                                  ? const Color(0xFFFFD700).withOpacity(0.3)
                                                  : const Color.fromARGB(255, 1112, 1, 0).withOpacity(0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: isUnread
                                                ? [
                                                    BoxShadow(
                                                      color: const Color.fromARGB(255, 1112, 1, 0).withOpacity(0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Icon(
                                            Icons.notifications_rounded,
                                            color: isUnread ? Colors.white : const Color.fromARGB(255, 1112, 1, 0),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Content section
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Main notification message
                                              Text(
                                                notification['message'] ?? 'New notification',
                                                style: TextStyle(
                                                  color: const Color.fromARGB(255, 1112, 1, 0), // Maroon
                                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                                                  fontSize: 16,
                                                  height: 1.4,
                                                  letterSpacing: -0.2,
                                                ),
                                              ),
                                              if (post != null) ...[
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFFFDF7), // Very light yellow
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(
                                                      color: const Color(0xFFFFD700).withOpacity(0.3), // Golden yellow border
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: const Color.fromARGB(255, 1112, 1, 0).withOpacity(0.1), // Light maroon
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Icon(
                                                          Icons.article_rounded,
                                                          size: 14,
                                                          color: Color.fromARGB(255, 1112, 1, 0), // Maroon
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Expanded(
                                                        child: Text(
                                                          post['title'] ?? 'Untitled Post',
                                                          style: const TextStyle(
                                                            color: Color(0xFF6B4E71), // Muted maroon
                                                            fontWeight: FontWeight.w500,
                                                            fontSize: 14,
                                                            height: 1.3,
                                                          ),
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 12),
                                              // Timestamp and status
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.schedule_rounded,
                                                    size: 14,
                                                    color: const Color(0xFF6B4E71), // Muted maroon
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    notification['created_at'] != null
                                                        ? DateFormat('MMM dd, yyyy').format(
                                                            DateTime.parse(
                                                              notification['created_at'],
                                                            ),
                                                          )
                                                        : '',
                                                    style: const TextStyle(
                                                      color: Color(0xFF6B4E71), // Muted maroon
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  if (isUnread)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient: const LinearGradient(
                                                          colors: [
                                                            Color(0xFFFFD700), // Golden yellow
                                                            Color(0xFFFFA500), // Orange yellow
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius.circular(12),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: const Color(0xFFFFD700).withOpacity(0.3),
                                                            blurRadius: 4,
                                                            offset: const Offset(0, 1),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Text(
                                                        'NEW',
                                                        style: TextStyle(
                                                          color: Color.fromARGB(255, 112, 1, 0), // Maroon text
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                ),
                                ),
                              ),
                            ),
                          ),
                        ),
                          );  
                        },
                        childCount: _notifications.length,
                      ),
                    ),
                  ),
                ],
              ),
  );
}
}