import 'package:flutter/material.dart';
import 'package:skripsi/components/nav_bar.dart';
import 'package:skripsi/pages/users/home/home_page.dart';
import 'package:skripsi/pages/users/profile/profile_page.dart';
import 'package:skripsi/pages/users/request/request_page.dart';

class AllPages extends StatefulWidget {
  const AllPages({super.key});

  @override
  State<AllPages> createState() => _AllPagesState();
}

class _AllPagesState extends State<AllPages> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const RequestPage(),
    const HomePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar:
          NaviBar(selectedIndex: _selectedIndex, onItemTapped: _onItemTapped),
    );
  }
}
