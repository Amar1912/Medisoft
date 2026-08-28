import 'package:flutter/material.dart';
import 'package:appointment_booking_app/utils/app_colors.dart';

import 'package:appointment_booking_app/src/views/screens/notifications_screen.dart';
import 'package:appointment_booking_app/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_booking_app/src/views/screens/schedule_appointment_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  String _selectedTab = 'upcoming';
  int? _selectedAppointmentIndex;
  String? _selectedAppointmentId; // Added to track selected doc ID

  final AppointmentService _appointmentService = AppointmentService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final bool isUpcoming = _selectedTab == 'upcoming';

    if (_currentUser == null) {
      return const Center(child: Text('Please log in to view appointments.'));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20.0),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: TextStyle(fontFamily: 'Ubuntu', fontSize: 24.0, fontWeight: FontWeight.bold),
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
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NotificationsScreen()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30.0),

              // --- Toggle Buttons ---
              _buildToggleButtons(),
              const SizedBox(height: 30.0),

              // --- Appointments List ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _appointmentService.getAppointments(_currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No appointments found.'));
                    }

                    // Sort appointments by date on the client side
                    final allDocs = snapshot.data!.docs.toList();
                    allDocs.sort((a, b) {
                      final aDate = ((a.data() as Map<String, dynamic>)['date'] as Timestamp).toDate();
                      final bDate = ((b.data() as Map<String, dynamic>)['date'] as Timestamp).toDate();
                      return aDate.compareTo(bDate);
                    });

                    final filteredAppointments = allDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'Upcoming';
                      if (isUpcoming) {
                        return status == 'Upcoming' || status == 'Rescheduled';
                      } else {
                        return status == 'Completed' || status == 'Cancelled';
                      }
                    }).toList();

                    if (filteredAppointments.isEmpty) {
                      return Center(
                        child: Text(isUpcoming ? 'No upcoming appointments.' : 'No past appointments.', style: TextStyle(color: AppColors.text)),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredAppointments.length,
                      itemBuilder: (context, index) {
                        final doc = filteredAppointments[index];
                        final appt = doc.data() as Map<String, dynamic>;
                        return _buildAppointmentCard(appt: appt, docId: doc.id, index: index, isSelected: isUpcoming && _selectedAppointmentIndex == index);
                      },
                    );
                  },
                ),
              ),

              // --- Reschedule/Cancel Buttons (if Upcoming) or Delete (if Past) ---
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButtons() {
    final bool isUpcoming = _selectedTab == 'upcoming';

    return Row(
      children: [
        Expanded(
          child: _buildTabButton('Upcoming', isUpcoming, () {
            setState(() {
              _selectedTab = 'upcoming';
              _selectedAppointmentIndex = null;
              _selectedAppointmentId = null;
            });
          }),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: _buildTabButton('Completed', !isUpcoming, () {
            setState(() {
              _selectedTab = 'completed';
              _selectedAppointmentIndex = null;
              _selectedAppointmentId = null;
            });
          }),
        ),
      ],
    );
  }

  Widget _buildTabButton(String text, bool isSelected, VoidCallback onPressed) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : Theme.of(context).cardColor,
          foregroundColor: isSelected ? Colors.white : AppColors.text,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          elevation: 0,
        ),
        child: Text(
          text,
          style: TextStyle(fontFamily: 'Ubuntu', fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard({required Map<String, dynamic> appt, required String docId, required int index, required bool isSelected}) {
    final bool isUpcoming = _selectedTab == 'upcoming';

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedAppointmentIndex == index) {
            _selectedAppointmentIndex = null;
            _selectedAppointmentId = null;
          } else {
            _selectedAppointmentIndex = index;
            _selectedAppointmentId = docId;
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.0),
          border: isSelected ? Border.all(color: AppColors.primary, width: 2.0) : null,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: Offset(0, 5))],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey[200],
                child: appt['doctorImage'] != null && appt['doctorImage'].toString().isNotEmpty
                    ? Image.network(
                        appt['doctorImage'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 40, color: Colors.grey),
                      )
                    : Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appt['doctorName'] ?? 'Doctor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'Ubuntu', fontSize: 18.0, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                        ),
                      ),
                      _buildStatusBadge(appt['status'] ?? 'Upcoming'),
                    ],
                  ),
                  const SizedBox(height: 6.0),
                  Row(
                    children: [
                      Icon(Icons.calendar_month_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4.0),
                      Text(
                        '${(appt['date'] as Timestamp).toDate().toString().split(' ')[0]}',
                        style: TextStyle(fontFamily: 'Ubuntu', fontSize: 13.0, color: AppColors.text, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 12.0),
                      Icon(Icons.access_time, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4.0),
                      Text(
                        '${appt['timeSlot']}',
                        style: TextStyle(fontFamily: 'Ubuntu', fontSize: 13.0, color: AppColors.text, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Patient: ${appt['patientName'] ?? 'Me'}',
                    style: TextStyle(fontFamily: 'Ubuntu', fontSize: 13.0, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Upcoming':
        color = AppColors.primary;
        break;
      case 'Rescheduled':
        color = Colors.orange;
        break;
      case 'Completed':
        color = Colors.green;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = AppColors.text;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(
        status,
        style: TextStyle(fontFamily: 'Ubuntu', fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isAppointmentSelected = _selectedAppointmentIndex != null;
    final bool isUpcoming = _selectedTab == 'upcoming';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Row(
        children: [
          if (isUpcoming) ...[
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isAppointmentSelected
                      ? () async {
                          if (_selectedAppointmentId == null) return;

                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(child: CircularProgressIndicator()),
                          );

                          try {
                            final docSnapshot = await FirebaseFirestore.instance.collection('appointments').doc(_selectedAppointmentId).get();

                            if (!docSnapshot.exists) {
                              if (context.mounted) Navigator.pop(context);
                              return;
                            }

                            final appointment = docSnapshot.data() as Map<String, dynamic>;
                            final String doctorName = appointment['doctorName'] ?? 'Doctor';

                            // Fetch doctor details by name
                            final doctorQuery = await FirebaseFirestore.instance.collection('doctors').where('name', isEqualTo: doctorName).limit(1).get();

                            Map<String, dynamic> doctorData;
                            if (doctorQuery.docs.isNotEmpty) {
                              doctorData = doctorQuery.docs.first.data();
                              doctorData['id'] = doctorQuery.docs.first.id;
                            } else {
                              // Fallback
                              doctorData = {'name': doctorName, 'image': 'https://randomuser.me/api/portraits/men/32.jpg', 'qualification': 'Specialist', 'location': 'Hospital'};
                            }

                            final patientData = {'name': appointment['patientName'] ?? 'User'};

                            if (!context.mounted) return;
                            Navigator.pop(context); // Close loading

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ScheduleAppointmentScreen(doctorData: doctorData, patientData: patientData, appointmentId: _selectedAppointmentId),
                              ),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                    foregroundColor: isAppointmentSelected ? AppColors.primary : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      side: BorderSide(color: isAppointmentSelected ? AppColors.primary : Colors.grey, width: 2.0),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                  ),
                  child: Text(
                    'Reschedule',
                    style: TextStyle(fontFamily: 'Ubuntu', fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isAppointmentSelected
                      ? () {
                          _showCancelConfirmationDialog();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAppointmentSelected ? AppColors.primary : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontFamily: 'Ubuntu', fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: isAppointmentSelected
                      ? () {
                          _showDeleteConfirmationDialog();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAppointmentSelected ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: Text(
                    'Delete',
                    style: TextStyle(fontFamily: 'Ubuntu', fontSize: 18.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            'Cancel Appointment?',
            style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          content: Text(
            'Are you sure you want to cancel this appointment?',
            style: TextStyle(fontFamily: 'Ubuntu', color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: AppColors.text),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_selectedAppointmentId != null) {
                  await _appointmentService.cancelAppointment(_selectedAppointmentId!);

                  if (!context.mounted) return;

                  setState(() {
                    _selectedAppointmentIndex = null;
                    _selectedAppointmentId = null;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment cancelled successfully.')));
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Yes, Cancel',
                style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Text(
            'Delete Appointment?',
            style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
          ),
          content: Text(
            'Are you sure you want to delete this appointment history?',
            style: TextStyle(fontFamily: 'Ubuntu', color: Theme.of(context).textTheme.bodyMedium?.color),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: AppColors.text),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_selectedAppointmentId != null) {
                  await _appointmentService.deleteAppointment(_selectedAppointmentId!);

                  if (!context.mounted) return;

                  setState(() {
                    _selectedAppointmentIndex = null;
                    _selectedAppointmentId = null;
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Appointment deleted successfully.')));
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                'Yes, Delete',
                style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
