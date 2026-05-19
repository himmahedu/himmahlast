import 'package:flutter/material.dart';

class HeaderWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget>? actions;
  const HeaderWidget({super.key, required this.title, required this.scaffoldKey, this.actions});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 90,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF3131), Color(0xFFFF8C00), Color(0xFFFFDE59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 48,
          left: MediaQuery.of(context).size.width / 2 - 32,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}