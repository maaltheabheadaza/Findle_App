import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class HomePageScreen extends StatefulWidget {
  const HomePageScreen({super.key});

  @override
  State<HomePageScreen> createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen> {
  final Color primaryRed = const Color.fromRGBO(112, 1, 0, 1);
  final Color primaryYellow = const Color.fromRGBO(246, 196, 1, 1);
  final Color white = const Color(0xFFF3F3F3);
  final Color textColor = const Color.fromRGBO(51, 51, 51, 1);

  String? username;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Prioritize username from auth.currentUser metadata (Display Name)
        final metaDisplayName = user.userMetadata?['display_name'] as String?;

        // Fetch other potential profile data from public.users
        final userDataResponse = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        setState(() {
          // Use display name from metadata if available, otherwise fallback to email prefix
          username = metaDisplayName ?? user.email?.split('@')[0] ?? 'User';

          // Get profile image URL from public.users if available
          profileImageUrl = userDataResponse?['profile_image_url'] as String?;

          isLoading = false;
        });
      } else {
        // If user is null, stop loading and set a default username
        setState(() {
          username = 'User';
          profileImageUrl = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
      // In case of any error, still try to get username from auth.currentUser email as fallback
      final user = Supabase.instance.client.auth.currentUser;
       setState(() {
         username = user?.userMetadata?['display_name'] as String? ?? user?.email?.split('@')[0] ?? 'User';
         profileImageUrl = null;
         isLoading = false;
       });
    }
  }

  Future<void> uploadProfileImage() async {
    // TODO: Implement image upload functionality
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        title: Text(
          'Findle',
          style: GoogleFonts.poppins(
            color: white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: white),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: primaryRed,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: uploadProfileImage,
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: white,
                        backgroundImage: profileImageUrl != null
                            ? NetworkImage(profileImageUrl!)
                            : null,
                        child: profileImageUrl == null
                            ? const Icon(Icons.person, size: 30, color: Colors.grey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Hi, $username!',
                      style: GoogleFonts.poppins(
                        color: white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.post_add, color: Colors.grey),
                title: Text(
                  'Posts',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to posts screen
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite, color: Colors.grey),
                title: Text(
                  'Favourites',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to favourites screen
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.message, color: Colors.grey),
                title: Text(
                  'Messages',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to messages screen
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: Colors.grey),
                title: Text(
                  'About Us',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to about us screen
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () {
                  // TODO: Navigate to settings screen
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.grey),
                title: Text(
                  'Log out',
                  style: GoogleFonts.poppins(
                    color: textColor,
                    fontSize: 16,
                  ),
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm Logout'),
                        content: Text('Are you sure you want to log out?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false), // Return false on cancel
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true), // Return true on confirm
                            child: Text('Logout'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : Center(
              child: Text(
                'Welcome to Findle!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
    );
  }
} 