import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart'; // Import provider package
import 'theme_provider.dart'; // Import ThemeProvider

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Color primaryRed = const Color.fromRGBO(112, 1, 0, 1);
  final Color primaryYellow = const Color.fromRGBO(246, 196, 1, 1);
  final Color white = const Color(0xFFF3F3F3);
  final Color textColor = const Color.fromRGBO(51, 51, 51, 1);

  String? username;
  String? email;
  String? profileImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Prioritize username from auth.currentUser metadata (Display Name)
        final metaDisplayName = user.userMetadata?['username'] as String?;

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
          email = user.email;
          isLoading = false;
        });
      } else {
        // If user is null, stop loading and set a default username
        setState(() {
          username = 'User';
          profileImageUrl = null;
          email = null;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
      // In case of any error, still try to get username from auth.currentUser email as fallback
      final user = Supabase.instance.client.auth.currentUser;
      setState(() {
        username = user?.userMetadata?['username'] as String? ?? user?.email?.split('@')[0] ?? 'User';
        profileImageUrl = null;
        email = user?.email;
        isLoading = false;
      });
    }
  }

  Future<void> uploadProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        isLoading = true;
      });

      // Upload image to Supabase Storage
      final String fileExt = image.path.split('.').last;
      final String fileName = '${user.id}/profile.$fileExt';
      
      // Upload the file
      await Supabase.instance.client.storage
          .from('profiles')
          .upload(fileName, File(image.path), fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ));

      // Get the public URL
      final String imageUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Update user profile in database
      await Supabase.instance.client
          .from('users')
          .update({'profile_image_url': imageUrl})
          .eq('id', user.id);

      setState(() {
        profileImageUrl = imageUrl;
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image == null) return;

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      setState(() {
        isLoading = true;
      });

      // Upload image to Supabase Storage
      final String fileExt = image.path.split('.').last;
      final String fileName = '${user.id}/profile.$fileExt';
      
      // Upload the file
      await Supabase.instance.client.storage
          .from('profiles')
          .upload(fileName, File(image.path), fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: true,
          ));

      // Get the public URL
      final String imageUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(fileName);

      // Update user profile in database
      await Supabase.instance.client
          .from('users')
          .update({'profile_image_url': imageUrl})
          .eq('id', user.id);

      setState(() {
        profileImageUrl = imageUrl;
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      print('❌ Error uploading profile image: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // Access ThemeProvider

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryRed,
        elevation: 0,
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            color: white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryRed))
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryRed.withOpacity(0.1),
                    Colors.white,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Profile Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (BuildContext context) {
                                  return SafeArea(
                                    child: Wrap(
                                      children: <Widget>[
                                        ListTile(
                                          leading: const Icon(Icons.photo_library),
                                          title: Text(
                                            'Choose from Gallery',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            uploadProfileImage();
                                          },
                                        ),
                                        ListTile(
                                          leading: const Icon(Icons.camera_alt),
                                          title: Text(
                                            'Take a Photo',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                            takePhoto();
                                          },
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: white,
                                  backgroundImage: profileImageUrl != null
                                      ? NetworkImage(profileImageUrl!)
                                      : null,
                                  child: profileImageUrl == null
                                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                      : null,
                                ),
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
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            '@$username',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            email ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Dark Mode Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                themeProvider.themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                                color: themeProvider.themeMode == ThemeMode.dark ? Colors.amber : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Dark Mode',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Theme.of(context).brightness == Brightness.dark 
                                      ? Colors.white 
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: themeProvider.themeMode == ThemeMode.dark,
                            onChanged: (bool value) {
                              themeProvider.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                            },
                            activeColor: primaryRed,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 