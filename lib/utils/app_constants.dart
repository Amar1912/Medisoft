import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const List<Map<String, dynamic>> specialties = [
    {'name': 'Neurologist', 'icon': Icons.psychology},
    {'name': 'Cardiologist', 'icon': Icons.favorite},
    {'name': 'Dentist', 'icon': Icons.healing},
    {'name': 'Therapist', 'icon': Icons.medical_services},
    {'name': 'Orthopedic', 'icon': Icons.accessible},
    {'name': 'Pediatrician', 'icon': Icons.child_care},
  ];

  static List<String> get specialtyNames => specialties.map((e) => e['name'] as String).toList();
}
