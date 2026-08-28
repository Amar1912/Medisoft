import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appointment_booking_app/utils/app_colors.dart';
import 'package:appointment_booking_app/src/views/screens/login_screen.dart';
import 'package:appointment_booking_app/utils/app_constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedSpecialty;
  final _priceController = TextEditingController();
  final _aboutController = TextEditingController();
  final _locationController = TextEditingController();
  final _qualificationController = TextEditingController();

  Future<void> _addDoctor() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim().toLowerCase();
    final String password = _passwordController.text.trim();
    final String specialty = _selectedSpecialty ?? '';
    
    if (name.isEmpty || email.isEmpty || password.isEmpty || specialty.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name, Email, Password and Specialty are required'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    FirebaseApp? secondaryApp;

    try {
      // 1. Create a secondary Firebase app instance to register the doctor without logging out admin
      secondaryApp = await Firebase.initializeApp(
        name: 'DoctorCreator_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final auth = FirebaseAuth.instanceFor(app: secondaryApp);
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      final String doctorUid = userCredential.user!.uid;

      // 2. Save doctor details to 'doctors' collection
      int price = int.tryParse(_priceController.text.trim()) ?? 100;
      
      await FirebaseFirestore.instance.collection('doctors').doc(doctorUid).set({
        'id': doctorUid,
        'name': name,
        'email': email,
        'specialty': specialty,
        'price': price,
        'about': _aboutController.text.trim().isEmpty ? 'Experienced specialist.' : _aboutController.text.trim(),
        'location': _locationController.text.trim().isEmpty ? 'City Clinic' : _locationController.text.trim(),
        'qualification': _qualificationController.text.trim().isEmpty ? 'MBBS' : _qualificationController.text.trim(),
        'rating': 5.0,
        'slots': 10,
        'image': '', 
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Save role to 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(doctorUid).set({
        'email': email,
        'role': 'doctor',
        'createdAt': FieldValue.serverTimestamp(),
        'profileComplete': true,
      });

      // 4. Cleanup and Success
      if (mounted) {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          _selectedSpecialty = null;
        });
        _priceController.clear();
        _aboutController.clear();
        _locationController.clear();
        _qualificationController.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Doctor $name added successfully! They can now login.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      // Very important: delete the secondary app to prevent memory leaks/re-init issues
      await secondaryApp?.delete();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isLoading = false;

  void _showAddDoctorDialog() {
    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Register New Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person))),
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Login Email', prefixIcon: Icon(Icons.email))),
                TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Login Password', prefixIcon: Icon(Icons.lock))),
                const Divider(height: 30),
                
                DropdownButtonFormField<String>(
                  value: _selectedSpecialty,
                  decoration: const InputDecoration(labelText: 'Specialty', prefixIcon: Icon(Icons.medical_services)),
                  items: AppConstants.specialtyNames.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setDialogState(() {
                      _selectedSpecialty = newValue;
                    });
                  },
                ),
                
                TextField(controller: _qualificationController, decoration: const InputDecoration(labelText: 'Qualification', prefixIcon: Icon(Icons.school))),
                TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on))),
                TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.monetization_on)), keyboardType: TextInputType.number),
                TextField(controller: _aboutController, decoration: const InputDecoration(labelText: 'About'), maxLines: 2),
              ],
            ),
          ),
          actions: [
            if (!_isLoading) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setDialogState(() => _isLoading = true);
                await _addDoctor();
                setDialogState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save & Create Account', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontFamily: 'Ubuntu', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                debugPrint('Logout error: $e');
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            color: AppColors.primary.withOpacity(0.05),
            child: const Text('Manage Doctors', style: TextStyle(fontFamily: 'Ubuntu', fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No doctors found.'));
                
                final doctors = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final data = doctors[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey[200]!)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['specialty'] ?? 'Specialty'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => FirebaseFirestore.instance.collection('doctors').doc(doctors[index].id).delete(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add_doctor_fab'),
        onPressed: () => _showAddDoctorDialog(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Doctor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
