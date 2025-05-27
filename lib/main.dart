import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'login_screen.dart';
import 'create_ad.dart';
import 'lost_and_found.dart';
import 'homepage_screen.dart';
import 'email_confirmation_screen.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://gwwvtzumbxzuonwjubpk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3d3Z0enVtYnh6dW9ud2p1YnBrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgwODg5NjIsImV4cCI6MjA2MzY2NDk2Mn0.c7nn16RL_e6_ybeeY9DzNPGXdLDDL279JjIAR7sP15E',
  );
  runApp(const MyApp());

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Handle initial URI
    final uri = await _appLinks.getInitialAppLink();
    if (uri != null) {
      _handleDeepLink(uri);
    }

    // Listen for incoming links while the app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Check if this is an email confirmation link
    if (uri.path.contains('confirm')) {
      // Navigate to the email confirmation screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const EmailConfirmationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Findle',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        colorScheme: const ColorScheme.light(
          primary: AppColors.maroon,
          secondary: AppColors.yellow,
          surface: AppColors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.maroon,
          foregroundColor: AppColors.white,
          titleTextStyle: TextStyle(
            color: AppColors.yellow,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: AppColors.lightGray,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.gray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.maroon),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.maroon,
            foregroundColor: AppColors.yellow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            shadowColor: AppColors.gray.withOpacity(0.5),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardPage(),
        '/create-ad': (context) => CreateAdPage(),
        '/lost-and-found': (context) => LostAndFoundPage(),
      },
    );
  }
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
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
      darkTheme: ThemeData(
        colorScheme: const ColorScheme.dark(
          primary: Color.fromRGBO(112, 1, 0, 1),   // #700100 (can be different for dark mode)
          secondary: Color.fromRGBO(246, 196, 1, 1), // #f6c401 (can be different for dark mode)
          surface: Color.fromRGBO(51, 51, 51, 1), // #333333
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[800],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color.fromRGBO(246, 196, 1, 1)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? displayName;

  @override
  Widget build(BuildContext context) {
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() {
    final user = Supabase.instance.client.auth.currentUser;
    final username = user?.userMetadata?['username'] ?? 'User';
    final email = user?.email ?? 'No email';

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.maroon,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: AppColors.yellow),
              iconSize: 34, 
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
        ),
        toolbarHeight: 70,
        title: Row(
          children: [
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.yellow),
            tooltip: 'About Us',
            onPressed: () => showAboutUsDialog(context),
          ),
        ],
      ),
      drawer: _CustomDrawer(username: username, email: email),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello,', style: TextStyle(color: AppColors.gray, fontSize: 22)),
            Text(username, style: const TextStyle(color: AppColors.darkGray, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
      Expanded(
        child: _DashboardCard(
          color: AppColors.paleYellow,
          icon: Icons.add_circle_outline,
          title: 'Create an advert',
          subtitle: 'Report if you find or lost\nan item.',
          height: double.infinity,
          onTap: () => Navigator.pushNamed(context, '/create-ad'),
          textColor: AppColors.maroon,
        ),
      ),
      const SizedBox(height: 16),
      Expanded(
        child: _DashboardCard(
          color:  AppColors.paleMaroon,
          icon: Icons.history,
          title: 'Lost & found items',
          subtitle: 'Go through the lost and\nfound items.',
          height: double.infinity,
          onTap: () => Navigator.pushNamed(context, '/lost-and-found'),
          textColor: Colors.white,
        ),
      ),
          ],
        ),
      ),
    );
    if (user != null) {
      setState(() {
        displayName = user.userMetadata?['display_name'] as String? ?? 
                     user.email?.split('@')[0] ?? 'User';
      });
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }
}

class _DashboardCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  final double height;
  final VoidCallback onTap;
  final Color textColor;

  const _DashboardCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.height,
    required this.onTap,
    this.textColor = AppColors.darkGray,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: 370,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 1,
              offset: Offset(4, 6),
            ),
          ],
        ),
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // vertical center
          crossAxisAlignment: CrossAxisAlignment.start, // align icon and text to the left
          children: [
            // Icon in circular background
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (displayName != null) Text('Logged in as: $displayName'),
            const SizedBox(height: 20),
            const Text('You have pushed the button this many times:'),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _CustomDrawer extends StatelessWidget {
  final String username;
  final String email;

  const _CustomDrawer({required this.username, required this.email});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.yellow,
            padding: const EdgeInsets.only(top: 48, left: 24, right: 24, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // <-- Ito ang mag-center vertically
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.white),
                const SizedBox(height: 12),
                Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(email, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
          const ListTile(title: Text('Favourites'), leading: Icon(Icons.favorite_outline)),
          const ListTile(title: Text('Messages'), leading: Icon(Icons.message_outlined)),
          ListTile(
            title: const Text('About Us'),
            leading: const Icon(Icons.info_outline),
            onTap: () {
              Navigator.pop(context); // optional: close the drawer
              showAboutUsDialog(context);
            },
          ),
          const ListTile(title: Text('Settings'), leading: Icon(Icons.settings_outlined)),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
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
    );
  }
}
