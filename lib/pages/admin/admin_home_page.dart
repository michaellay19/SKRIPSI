import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/auth/login_page.dart';
import 'package:skripsi/provider/auth_provider.dart';

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({super.key});

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  void _logout() async {
    await Provider.of<MyAuthProvider>(context, listen: false).signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text("Admin"),
              accountEmail: Text("admin@example.com"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.admin_panel_settings,
                    size: 40, color: Colors.blueAccent),
              ),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
              ),
            ),
            _buildDrawerItem(context, 'Dashboard', Icons.dashboard, () {}),
            _buildDrawerItem(context, 'Users', Icons.people, () {}),
            _buildDrawerItem(context, 'Settings', Icons.settings, () {}),
            _buildDrawerItem(context, 'Logout', Icons.logout, () {
              _showLogoutDialog(context);
            }),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome to the Admin Dashboard",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _buildCard(
                            "Total Users", "150", Icons.people, Colors.green),
                        _buildCard("Active Sessions", "75",
                            Icons.online_prediction, Colors.orange),
                        _buildCard(
                            "Pending Requests", "5", Icons.pending, Colors.red),
                        _buildCard("Settings", "Manage", Icons.settings,
                            Colors.blueGrey),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _logout();
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
