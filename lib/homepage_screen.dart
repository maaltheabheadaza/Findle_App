import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'create_ad.dart';
import 'lost_and_found.dart';

class AppColors {
  static const white = Color(0xFFF3F3F3);
  static const maroon = Color(0xFF700100);
  static const yellow = Color(0xFFF6C401);
  static const lightGray = Color(0xFFF5F5F5);
  static const darkGray = Color(0xFF4A4A4A);
  static const gray = Color(0xFF7E7E7E);
  static const paleYellow = Color.fromARGB(255, 244, 216, 125); 
  static const paleMaroon = Color.fromARGB(255, 138, 26, 26);
}

void showAboutUsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'About Findle',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppColors.maroon,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Developed by:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text('• Ma. Althea Bhea Daza'),
          Text('• Stephanie Angel Nudalo'),
          Text('• Geraldyn Boholst'),
          SizedBox(height: 12),
          Text(
            'BS Information Technology\nEastern Visayas State University - Ormoc Campus',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppColors.gray,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'About Findle:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.darkGray,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Findle is a campus-based lost and found system designed exclusively for EVSU-Ormoc students. '
            'It allows users to report lost or found items efficiently and connect with rightful owners '
            'within the school community. This project aims to promote honesty, responsibility, and convenience.',
            style: TextStyle(height: 1.4),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Close',
            style: TextStyle(color: AppColors.maroon),
          ),
        ),
      ],
    ),
  );
}
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
            icon: const Icon(Icons.info_outline, color: AppColors.yellow),
            tooltip: 'About Us',
            onPressed: () => showAboutUsDialog(context),
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
                      '@$username',
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
                  Navigator.pop(context); // optional: close the drawer
                  showAboutUsDialog(context);
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
                  final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.logout, size: 50, color: AppColors.maroon),
                              const SizedBox(height: 15),
                              const Text(
                                'Are you sure you want to log out?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkGray,
                                ),
                              ),
                              const SizedBox(height: 23),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.lightGray,
                                      foregroundColor: AppColors.darkGray,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.maroon,
                                      foregroundColor: AppColors.yellow,
                                    ),
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  if (shouldLogout ?? false) {
                    await Supabase.instance.client.auth.signOut();
                    Navigator.pushReplacementNamed(context, '/');
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome to Findle!',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 250,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.6),
                            side: const BorderSide(color: AppColors.maroon, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreateAdPage()),
                            );
                          },
                          icon: const Icon(Icons.campaign_rounded, color: AppColors.maroon),
                          label: Text(
                            'Create a post',
                            style: GoogleFonts.poppins(
                              color: AppColors.maroon,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 250,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.6),
                            side: const BorderSide(color: AppColors.yellow, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LostAndFoundPage()),
                            );
                          },
                          icon: const Icon(Icons.search_rounded, color: AppColors.yellow),
                          label: Text(
                            'Lost and Found',
                            style: GoogleFonts.poppins(
                              color: AppColors.yellow,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
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