import 'package:flutter/material.dart';
import 'package:pedal/screens/main_screen.dart';
import 'package:pedal/screens/my_page_screen.dart';
import 'package:pedal/screens/map_screen.dart'; // Import MapScreen
import 'package:pedal/widgets/bar/bottom_nav_bar.dart';
import 'package:pedal/widgets/bar/logo_app_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onMapButtonPressed() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const MapScreen(),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const MainScreen(),
      const MyPageScreen(),
    ];

    return Scaffold(
      appBar: const LogoBar(), // AppBar for HomePage and MyPageScreen
      body: screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: _onMapButtonPressed,
        child: const Icon(Icons.map, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
