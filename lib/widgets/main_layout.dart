import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:himmah_app/screens/settings_page.dart';
import 'package:himmah_app/screens/about_page.dart';
import 'package:himmah_app/screens/student_home_page.dart';
import 'package:himmah_app/screens/login_page.dart';
import 'package:himmah_app/widgets/header_widget.dart';
import 'package:himmah_app/widgets/footer_widget.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNavigationBar;
  const MainLayout({super.key, required this.title, required this.body, this.actions, this.bottomNavigationBar});

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: HeaderWidget(title: title, scaffoldKey: _scaffoldKey, actions: actions),
      ),
      drawer: AppDrawer(scaffoldKey: _scaffoldKey),
      body: Column(
        children: [
          Expanded(child: body),
          const FooterWidget(),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: Navigator.of(context).canPop()
          ? FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: const Color(0xFFFF3131),
        child: const Icon(Icons.arrow_back, color: Colors.white),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

class AppDrawer extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const AppDrawer({super.key, required this.scaffoldKey});

  // أيقونات المنصات
  static const Map<String, IconData> _platformIcons = {
    'Instagram': Icons.camera_alt,
    'Facebook': Icons.facebook,
    'Twitter/X': Icons.alternate_email,
    'YouTube': Icons.play_circle,
    'TikTok': Icons.music_note,
    'Telegram': Icons.send,
    'WhatsApp': Icons.call,
    'LinkedIn': Icons.business,
    'Website': Icons.language,
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFFF3131), Color(0xFFFF8C00), Color(0xFFFFDE59)]),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, color: Color(0xFFFF3131))),
                const SizedBox(height: 8),
                Text(user?.email ?? 'المستخدم', style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.book, color: Color(0xFFFF3131)),
            title: const Text('المواد'),
            onTap: () {
              Navigator.pop(context);
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get().then((doc) {
                  final specialty = doc.get('specialty') ?? '';
                  final year = doc.get('year') ?? '';
                  Navigator.push(context, MaterialPageRoute(builder: (_) => StudentHomePage(specialty: specialty, year: year)));
                });
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: Color(0xFFFF8C00)),
            title: const Text('الإعدادات'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFFFFDE59)),
            title: const Text('حول التطبيق'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('تسجيل الخروج'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginPage()), (route) => false);
            },
          ),
          const Divider(),
          // روابط التواصل الاجتماعي من Firestore
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('تابعنا', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('socialLinks').orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final links = snapshot.data!.docs;
              return Column(
                children: links.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final platform = data['platform'] ?? '';
                  final url = data['url'] ?? '';
                  final icon = _platformIcons[platform] ?? Icons.link;
                  return ListTile(
                    leading: Icon(icon, color: _getIconColor(platform)),
                    title: Text(platform),
                    onTap: () {
                      if (url.isNotEmpty) launchUrl(Uri.parse(url));
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getIconColor(String platform) {
    switch (platform) {
      case 'Instagram': return Colors.purple;
      case 'Facebook': return Colors.blue;
      case 'Twitter/X': return Colors.black;
      case 'YouTube': return Colors.red;
      case 'TikTok': return Colors.black;
      case 'Telegram': return Colors.blue;
      case 'WhatsApp': return Colors.green;
      case 'LinkedIn': return Colors.blue;
      default: return const Color(0xFFFF8C00);
    }
  }
}