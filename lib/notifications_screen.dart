import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'homepage_screen.dart';
import 'lost_and_found.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final response = await Supabase.instance.client
            .from('notifications')
            .select('*, post:post_id(*)')
            .eq('user_id', currentUser.id)
            .order('created_at', ascending: false);

        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response ?? []);
          _isLoading = false;
        });
      }
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
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGray,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(color: AppColors.maroon),
        elevation: 1,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.maroon,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchNotifications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
                  ? const Center(
                      child: Text(
                        'No notifications yet.',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.gray,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final post = notification['post'] as Map<String, dynamic>?;
                        
                        return Card(
                          color: notification['is_read'] == true 
                              ? AppColors.white 
                              : AppColors.paleYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              if (post != null) {
                                _markAsRead(notification['id']);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostDetailScreen(post: post),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.notifications,
                                        color: notification['is_read'] == true 
                                            ? AppColors.gray 
                                            : AppColors.maroon,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          notification['message'] ?? 'New notification',
                                          style: TextStyle(
                                            color: notification['is_read'] == true 
                                                ? AppColors.gray 
                                                : AppColors.darkGray,
                                            fontWeight: notification['is_read'] == true 
                                                ? FontWeight.normal 
                                                : FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (post != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      post['title'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.maroon,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Text(
                                    notification['created_at'] != null
                                        ? notification['created_at'].toString().substring(0, 10)
                                        : '',
                                    style: const TextStyle(
                                      color: AppColors.gray,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
} 