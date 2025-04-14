import 'package:flutter/material.dart';
import 'package:skripsi/constants/app_colors.dart';

class NaviBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const NaviBar({super.key, required this.selectedIndex, required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(
                Icons.access_time,
              ),
              label: 'Request',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person,
              ),
              label: 'Profile',
            ),
          ],
          currentIndex: selectedIndex,
          onTap: onItemTapped,
          selectedItemColor: AppColors.primary,
          iconSize: 30.0,
          selectedFontSize: 14.0,
          unselectedFontSize: 12.0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
        ),
      ],
    );
  }
}
