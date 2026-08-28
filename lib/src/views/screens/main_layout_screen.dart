// lib/src/views/screens/main_layout_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_booking_app/src/views/screens/home_screen.dart';
import 'package:appointment_booking_app/utils/app_colors.dart';
import 'package:appointment_booking_app/src/views/screens/doctor_home_screen.dart';
import 'package:appointment_booking_app/src/views/screens/my_appointments_screen.dart';
import 'package:appointment_booking_app/src/views/screens/admin_dashboard_screen.dart';
import 'package:appointment_booking_app/src/views/screens/settings_screen.dart';

class MainLayoutScreen extends StatefulWidget {
  final int initialIndex;
  const MainLayoutScreen({super.key, this.initialIndex = 0});

  @override
  State<MainLayoutScreen> createState() => MainLayoutScreenState();
}

class MainLayoutScreenState extends State<MainLayoutScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const MyAppointmentsScreen(), const SettingsScreen()];

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Theme.of(context).disabledColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
