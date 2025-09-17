import 'package:flutter/material.dart';
import 'package:pedal/screens/home_screen.dart';
import 'package:pedal/screens/my_page_screen.dart';
import 'package:pedal/screens/map_screen.dart'; // Import MapScreen
import 'package:pedal/widgets/bar/custom_bottom_nav_bar.dart';
import 'package:pedal/widgets/bar/logo_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomePage(),
    const MyPageScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onMapButtonPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MapScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LogoBar(), // AppBar for HomePage and MyPageScreen
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onMapButtonPressed,
        child: const Icon(Icons.map),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
