import 'package:flutter/material.dart';
import 'package:payfxglobal/widgets/logout_dialog.dart';

class CustomAppDrawer extends StatelessWidget {
  const CustomAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF22C7F3)),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.of(context).pushNamed('/home'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            onTap: () => Navigator.of(context).pushNamed('/edit_profile'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              LogoutDialog.show(context);
            },
          ),
        ],
      ),
    );
  }
}
