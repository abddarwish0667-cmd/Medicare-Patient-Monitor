import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _photoKey = 'medicare_profile_photo';

  final ImagePicker _picker = ImagePicker();

  String? _photoPath;
  bool _loadingPhoto = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_photoKey);

    if (!mounted) return;

    setState(() {
      _photoPath = savedPath;
      _loadingPhoto = false;
    });
  }

  Future<void> _choosePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1000,
      );

      if (image == null) return;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_photoKey, image.path);

      if (!mounted) return;

      setState(() {
        _photoPath = image.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture updated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select picture: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_photoKey);

    if (!mounted) return;

    setState(() {
      _photoPath = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile picture removed.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _profilePicture() {
    final path = _photoPath;

    if (_loadingPhoto) {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: Color(0xFFEAF4FF),
        child: CircularProgressIndicator(),
      );
    }

    if (path != null && File(path).existsSync()) {
      return CircleAvatar(
        radius: 60,
        backgroundColor: const Color(0xFFEAF4FF),
        backgroundImage: FileImage(File(path)),
      );
    }

    return const CircleAvatar(
      radius: 60,
      backgroundColor: Color(0xFFEAF4FF),
      child: Icon(Icons.person_rounded, size: 65, color: Color(0xFF0968D8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final name = user?.displayName?.trim();

    final displayName = name != null && name.isNotEmpty
        ? name
        : 'Medicare User';

    final email = user?.email ?? 'No email';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8FC),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF082B5C),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 35),
        children: [
          Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF082B5C), Color(0xFF0968D8)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _profilePicture(),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 4,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _choosePhoto,
                          child: const Padding(
                            padding: EdgeInsets.all(11),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: Color(0xFF0968D8),
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user?.emailVerified == true
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user?.emailVerified == true
                            ? 'Verified account'
                            : 'Email not verified',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _ProfileSection(
            title: 'Account',
            children: [
              _ProfileRow(
                icon: Icons.person_outline_rounded,
                title: 'Name',
                value: displayName,
              ),
              _ProfileRow(
                icon: Icons.mail_outline_rounded,
                title: 'Email',
                value: email,
              ),
              _ProfileRow(
                icon: Icons.verified_user_outlined,
                title: 'Account status',
                value: user?.emailVerified == true
                    ? 'Verified'
                    : 'Not verified',
              ),
            ],
          ),

          const SizedBox(height: 16),

          _ProfileSection(
            title: 'Profile Picture',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _ProfileIcon(icon: Icons.photo_library_outlined),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Add or change your profile picture'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _choosePhoto,
              ),
              if (_photoPath != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _ProfileIcon(
                    icon: Icons.delete_outline_rounded,
                    danger: true,
                  ),
                  title: const Text(
                    'Remove picture',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: _removePhoto,
                ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF0968D8)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your selected profile picture is stored locally on this device for the Medicare prototype.',
                    style: TextStyle(
                      color: Color(0xFF395875),
                      height: 1.4,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.shade200),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'LOG OUT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Center(
            child: Text(
              'MEDICARE',
              style: TextStyle(
                color: Color(0xFF082B5C),
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 4),

          const Center(
            child: Text(
              'Powered by Abd Elkoudous',
              style: TextStyle(color: Colors.blueGrey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF082B5C),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _ProfileIcon(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1B2D41),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  final IconData icon;
  final bool danger;

  const _ProfileIcon({required this.icon, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: danger ? Colors.red.shade50 : const Color(0xFFEAF4FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: danger ? Colors.red : const Color(0xFF0968D8),
        size: 21,
      ),
    );
  }
}
