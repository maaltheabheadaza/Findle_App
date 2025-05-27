import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'settings_screen.dart';

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
  
  // Track selected menu item
  int _selectedIndex = -1;

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
              _buildDrawerItem(
                icon: Icons.post_add,
                title: 'Posts',
                index: 0,
                onTap: () {
                  // TODO: Navigate to posts screen
                },
              ),
              _buildDrawerItem(
                icon: Icons.favorite,
                title: 'Favourites',
                index: 1,
                onTap: () {
                  // TODO: Navigate to favourites screen
                },
              ),
              _buildDrawerItem(
                icon: Icons.message,
                title: 'Messages',
                index: 2,
                onTap: () {
                  // TODO: Navigate to messages screen
                },
              ),
              _buildDrawerItem(
                icon: Icons.info,
                title: 'About Us',
                index: 3,
                onTap: () {
                  // TODO: Navigate to about us screen
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'Settings',
                index: 4,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Log out',
                index: 5,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm Logout'),
                        content: Text('Are you sure you want to log out?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
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
          : Stack(
              children: [
                // Patterned background with many student-related icons
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.13,
                    child: Stack(
                      children: [
                        // Row 1
                        Positioned(top: 40, left: 20, child: Icon(Icons.book_rounded, size: 50, color: primaryRed)),
                        Positioned(top: 80, right: 30, child: Icon(Icons.backpack_rounded, size: 40, color: primaryYellow)),
                        Positioned(top: 60, left: 120, child: Icon(Icons.laptop_mac_rounded, size: 35, color: primaryYellow)),
                        Positioned(top: 120, right: 100, child: Icon(Icons.edit_note_rounded, size: 30, color: primaryRed)),
                        Positioned(top: 30, right: 80, child: Icon(Icons.science_rounded, size: 38, color: primaryRed)),
                        // Row 2
                        Positioned(top: 180, left: 60, child: Icon(Icons.search_rounded, size: 40, color: primaryRed)),
                        Positioned(top: 200, right: 40, child: Icon(Icons.school_rounded, size: 45, color: primaryYellow)),
                        Positioned(top: 220, left: 180, child: Icon(Icons.calculate_rounded, size: 32, color: primaryYellow)),
                        Positioned(top: 160, right: 120, child: Icon(Icons.palette_rounded, size: 36, color: primaryRed)),
                        // Row 3
                        Positioned(bottom: 220, left: 40, child: Icon(Icons.menu_book_rounded, size: 40, color: primaryRed)),
                        Positioned(bottom: 200, right: 60, child: Icon(Icons.sports_esports_rounded, size: 38, color: primaryYellow)),
                        Positioned(bottom: 180, left: 120, child: Icon(Icons.headphones_rounded, size: 32, color: primaryYellow)),
                        Positioned(bottom: 160, right: 100, child: Icon(Icons.coffee_rounded, size: 36, color: primaryRed)),
                        // Row 4
                        Positioned(bottom: 120, left: 60, child: Icon(Icons.search_rounded, size: 40, color: primaryRed)),
                        Positioned(bottom: 60, right: 80, child: Icon(Icons.laptop_mac_rounded, size: 55, color: primaryYellow)),
                        Positioned(bottom: 40, left: 180, child: Icon(Icons.edit_note_rounded, size: 45, color: primaryRed)),
                        Positioned(bottom: 30, right: 30, child: Icon(Icons.science_rounded, size: 38, color: primaryRed)),
                        // Extra scattered
                        Positioned(top: 300, left: 30, child: Icon(Icons.book_rounded, size: 30, color: primaryRed)),
                        Positioned(top: 350, right: 60, child: Icon(Icons.backpack_rounded, size: 30, color: primaryYellow)),
                        Positioned(bottom: 300, left: 100, child: Icon(Icons.palette_rounded, size: 28, color: primaryRed)),
                        Positioned(bottom: 350, right: 120, child: Icon(Icons.calculate_rounded, size: 28, color: primaryYellow)),
                      ],
                    ),
                  ),
                ),
                // Main content
                Center(
                  child: Text(
                    'Welcome to Findle!',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    final bool isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryRed : Colors.grey,
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: isSelected ? primaryRed : textColor,
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        onTap();
      },
    );
  }
} 