import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skripsi/pages/admin/admin_attendance_list_page.dart';
import 'package:skripsi/pages/admin/admin_home_page.dart';
import 'package:skripsi/pages/admin/admin_setting_page.dart';
import 'package:skripsi/pages/admin/admin_location_page.dart';
import 'package:skripsi/pages/admin/admin_employee_list_page.dart';
import 'package:skripsi/pages/admin/admin_request_time_off_page.dart';
import 'package:skripsi/pages/admin/admin_attendance_report_page.dart';
import 'package:skripsi/pages/auth/login_page.dart';
import 'package:skripsi/provider/auth_provider.dart';
import 'package:skripsi/provider/profile_provider.dart';

class AllAdminPage extends StatefulWidget {
  const AllAdminPage({super.key});

  @override
  State<AllAdminPage> createState() => _AllAdminPageState();
}

class _AllAdminPageState extends State<AllAdminPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminHomePage(),
    const AdminSettingPage(),
    const AdminAttendanceListPage(),
    const AdminLocationPage(),
    const AdminEmployeeListPage(),
    AdminRequestTimeOffPage(),
    const AdminAttendanceReportPage()
  ];

  final List<String> _pageTitles = [
    "Dashboard",
    "Settings",
    "Attendance List",
    "Location",
    "Employee List",
    "Request Time Off List",
    "Attendance Report"
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).loadProfile();
    });
  }

  void _onDrawerItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

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
        backgroundColor: Colors.cyan,
        title: Text(_pageTitles[_selectedIndex]),
        centerTitle: true,
      ),
      drawer: _buildDrawer(),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              return DrawerHeader(
                decoration: const BoxDecoration(color: Colors.cyan),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 30,
                      backgroundImage: profileProvider.profileImage.isNotEmpty
                          ? NetworkImage(profileProvider.profileImage)
                          : null,
                      child: profileProvider.profileImage.isEmpty
                          ? const Icon(Icons.admin_panel_settings,
                              size: 40, color: Colors.cyan)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      profileProvider.name.isNotEmpty
                          ? profileProvider.name
                          : "Loading...",
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      profileProvider.role.isNotEmpty
                          ? profileProvider.role
                          : "-",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildDrawerItem(Icons.dashboard, "Dashboard", 0),
          _buildDrawerItem(Icons.list, "Attendance List", 2),
          _buildDrawerItem(Icons.people, "Employee List", 4),
          _buildDrawerItem(Icons.approval, "Request Time Off List", 5),
          const Divider(),
          _buildDrawerItem(Icons.map, "Location", 3),
          _buildDrawerItem(Icons.report, "Attendance Report", 6),
          const Divider(),
          _buildDrawerItem(Icons.settings, "Settings", 1),
          _buildDrawerItem(Icons.logout, "Logout", -1),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon, color: Colors.cyan),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      selected: _selectedIndex == index && index >= 0,
      onTap: () {
        if (index == -1) {
          _showLogoutDialog();
        } else if (index >= 0) {
          _onDrawerItemTapped(index);
        }
      },
    );
  }

  void _showLogoutDialog() {
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
            onPressed: _logout,
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}
