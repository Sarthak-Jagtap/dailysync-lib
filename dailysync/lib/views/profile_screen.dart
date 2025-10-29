import 'package:dailysync/controllers/theme_controller.dart';
import 'package:dailysync/views/account_settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';     
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'achievements_screen.dart';
import 'streak_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = true;
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late final Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
    } else {
      _userFuture = Future.error("No user logged in.");
    }
  }

  
  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    int numWords = 2;

    if (names.isNotEmpty) {
      if (names.length < numWords) {
        numWords = names.length;
      }
      for (var i = 0; i < numWords; i++) {
        initials += names[i][0];
      }
    }
    return initials.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeController>(context);
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("You are not logged in."),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text("Go to Login"),
              )
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userFuture, 
        builder: (context, snapshot) {
          
         
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text("Error: Could not load profile. ${snapshot.error}"),
            );
          }

         
          final userData = snapshot.data!.data();

          if (userData == null) {
            return const Center(child: Text("Error: Profile data is empty."));
          }

          
          final String userName = userData['name'] ?? 'Guest User';
          final String userEmail = userData['email'] ?? 'No email found';
          final String userInitials = _getInitials(userName);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(userName, userEmail, userInitials),
                const SizedBox(height: 24),
                _buildStatsGrid(context),
                const SizedBox(height: 24),
                Text(
                  'Settings',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildSettingsList(themeNotifier, context),
                const SizedBox(height: 32),
                _buildSignOutButton(context),
              ],
            ),
          );
        },
      ),
    );
  }
  Widget _buildProfileHeader(String userName, String userEmail, String userInitials) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.deepPurple,
              child: Text(
                userInitials, 
                style: const TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              userName, 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail, 
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: '87%', label: 'Health Score'),
                _StatItem(value: '\$2,340', label: 'Saved'),
                _StatItem(value: '156', label: 'Tasks Done'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
   
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Achievements',
            value: '24',
            icon: Icons.emoji_events,
            color: Colors.green,
            onTap: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AchievementsScreen()));
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Streak',
            value: '12',
            icon: Icons.local_fire_department,
            color: Colors.blue,
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const StreakScreen()));
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Goals',
            value: '8/10',
            icon: Icons.flag,
            color: Colors.purple,
            onTap: () {
              // Navigator.of(context)
              //     .push(MaterialPageRoute(builder: (_) => const GoalsScreen()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(ThemeController themeNotifier, BuildContext context) {
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            trailing: Switch(
              value: themeNotifier.isDarkMode,
              onChanged: (value) {
                themeNotifier.toggleTheme();
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Push notifications'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Notifications ${value ? "enabled" : "disabled"}')),
                );
              },
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
              );
            },
            leading: const Icon(Icons.person_outline),
            title: const Text('Account Settings'),
            subtitle: const Text('Manage your account'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
        ],
      ),
    );
  }
  Widget _buildSignOutButton(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: () async {
          
          await FirebaseAuth.instance.signOut();
          
          if (mounted) { 
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
            );
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Sign Out'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }
}


class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}


class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color,
                foregroundColor: Colors.white,
                child: Icon(icon),
              ),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }}