// lib/src/views/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:appointment_booking_app/utils/app_colors.dart';
import 'package:appointment_booking_app/src/views/screens/category_doctors_screen.dart';
import 'package:appointment_booking_app/src/views/widgets/doctor_card.dart';
import 'package:appointment_booking_app/src/views/screens/notifications_screen.dart';
import 'package:appointment_booking_app/services/doctor_service.dart';
import 'package:appointment_booking_app/src/views/screens/main_layout_screen.dart';
import 'package:appointment_booking_app/utils/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DoctorService _doctorService = DoctorService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20.0),
                // Header Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(fontFamily: 'Ubuntu', fontSize: 24.0, fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(
                                text: 'Hello, ',
                                style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              TextSpan(
                                text: 'MediSlot 👋',
                                style: TextStyle(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          'How are you today?',
                          style: TextStyle(fontFamily: 'Ubuntu', fontSize: 14.0, color: Colors.grey[400], fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    // Notification Bell
                    Container(
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(Icons.notifications_outlined, color: Theme.of(context).iconTheme.color, size: 28),
                        onPressed: () {
                          // Navigate to Notifications Screen
                          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),

                // Specialty Categories
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: AppConstants.specialties.map((specialty) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: _buildSpecialtyCard(specialty['name'], specialty['icon']),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30.0),

                // Top Doctors Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Doctors',
                      style: TextStyle(fontFamily: 'Ubuntu', fontSize: 20.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CategoryDoctorsScreen(categoryName: null)));
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(fontFamily: 'Ubuntu', fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Top Doctors List with StreamBuilder
                StreamBuilder<List<Doctor>>(
                  stream: _doctorService.getTopDoctors(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('No doctors found.')));
                    }

                    final doctors = snapshot.data!;
                    return Column(
                      children: doctors.map((doctor) {
                        return DoctorCard(doctor: doctor.toMap());
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Specialty Card Widget
  Widget _buildSpecialtyCard(String name, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => CategoryDoctorsScreen(categoryName: name)));
      },
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 2, blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Icon(icon, size: 35, color: Theme.of(context).iconTheme.color),
          ),
          const SizedBox(height: 8.0),
          Text(
            name,
            style: TextStyle(fontFamily: 'Ubuntu', fontSize: 12.0, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }
}
