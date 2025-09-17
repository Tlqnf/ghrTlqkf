import 'package:flutter/material.dart';
import 'package:pedal/screens/home_screen.dart';
import 'package:pedal/screens/map_screen.dart';
import 'package:pedal/screens/my_page_screen.dart';
import 'package:pedal/widgets/bar/custom_bottom_nav_bar.dart';
import 'package:pedal/widgets/bar/logo_bar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const MapScreen(), // Assuming MapScreen is for '기록 추가'
    const MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoBar(),
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
