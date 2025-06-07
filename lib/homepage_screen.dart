import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_screen.dart';
import 'create_ad.dart';
import 'lost_and_found.dart';
import 'notifications_screen.dart';
import 'chat_list_screen.dart';

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
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
      // Fetch profile data from public.users
      final userDataResponse = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        // Use username from users table if available, otherwise fallback to email prefix
        username = userDataResponse?['username'] as String? ?? user.email?.split('@')[0] ?? 'User';
        profileImageUrl = userDataResponse?['profile_image_url'] as String?;
        isLoading = false;
      });
    } else {
      setState(() {
        username = 'User';
        profileImageUrl = null;
        isLoading = false;
      });
    }
  } catch (e) {
    print('❌ Error fetching user data: $e');
    final user = Supabase.instance.client.auth.currentUser;
    setState(() {
      username = user?.email?.split('@')[0] ?? 'User';
      profileImageUrl = null;
      isLoading = false;
    });
  }
}
  Future<void> uploadProfileImage() async {
    // TODO: Implement image upload functionality
  }

  void _showExpandedProfileImage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: profileImageUrl != null
                      ? Image.network(
                          profileImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: primaryRed,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.person, size: 100, color: Colors.grey[400]);
                          },
                        )
                      : Icon(Icons.person, size: 100, color: Colors.grey[400]),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                    onTap: () {
                      if (profileImageUrl != null) {
                        _showExpandedProfileImage();
                      } else {
                        uploadProfileImage();
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: white,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(Icons.person, size: 30, color: Colors.grey)
                              : null,
                        ),
                        if (profileImageUrl != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                      ],
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
                  const SizedBox(height: 4),
                  Text(
                    Supabase.instance.client.auth.currentUser?.email ?? '',
                    style: GoogleFonts.poppins(
                      color: white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
              _buildDrawerItem(
                 icon: Icons.post_add,
                  title: 'My Posts',
                  index: 0,
                  onTap: () {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LostAndFoundPage(
                            userId: user.id,
                            showMyPosts: true,
                          ),
                        ),
                      );
                    }
                  },
                ),
              _buildDrawerItem(
                icon: Icons.message,
                title: 'Messages',
                index: 2,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatListScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.notifications,
                title: 'Notifications',
                index: 3,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.info,
                title: 'About Us',
                index: 4,
                onTap: () {
                  Navigator.pop(context); // optional: close the drawer
                  showAboutUsDialog(context);
                },
              ),
             _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  index: 5,
                  onTap: () async {
                    Navigator.pop(context);
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                    if (updated == true) {
                      fetchUserData(); // Refresh user data after returning from settings
                    }
                  },
                ),
              const Divider(),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'Log out',
                index: 6,
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
                    Navigator.pushReplacementNamed(context, '/login');
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
                opacity: 0.06, // Even more subtle
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
            
            // Subtle gradient overlay for depth
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main content with premium design
            Center(
              child: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Premium brand header
                      Container(
                        margin: const EdgeInsets.only(bottom: 50),
                        child: Column(
                          children: [
                            // Brand logo placeholder (you can replace with actual logo)
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.maroon.withOpacity(0.8),
                                    AppColors.yellow.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.maroon.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.search_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            
                            // Premium title section
                            Text(
                              'FINDLE',
                              style: GoogleFonts.poppins(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: 3.0,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Where Lost Things Live',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: textColor.withOpacity(0.7),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Elegant divider
                            Container(
                              height: 2,
                              width: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppColors.maroon.withOpacity(0.5),
                                    AppColors.yellow.withOpacity(0.5),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Premium action buttons
                      Column(
                        children: [
                          // Create Post Button - Premium Design
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.85),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.maroon.withOpacity(0.08),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.maroon.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CreateAdScreen()),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.maroon.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Icon(
                                          Icons.campaign_rounded,
                                          color: AppColors.maroon,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Create New Post',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.maroon,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Lost and Found Button - Premium Design
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.95),
                                  Colors.white.withOpacity(0.85),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.yellow.withOpacity(0.08),
                                  blurRadius: 25,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 1,
                                  offset: const Offset(0, 1),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.yellow.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(30),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const LostAndFoundPage()),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.yellow.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: Icon(
                                          Icons.search_rounded,
                                          color: AppColors.yellow,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Lost and Found',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.yellow,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Premium footer text
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Find • Return • Repeat',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: textColor.withOpacity(0.5),
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
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