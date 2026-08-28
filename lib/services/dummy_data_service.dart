import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DummyDataService {
  static Future<void> addSampleDoctors() async {
    final firestore = FirebaseFirestore.instance;
    final doctorsCollection = firestore.collection('doctors');

    // Create Admin Account if it doesn't exist
    try {
      final auth = FirebaseAuth.instance;
      // We can't easily check if a user exists without trying to sign in or sign up
      // But we can check our 'users' collection
      final userDoc = await firestore.collection('users').where('email', isEqualTo: 'admin@gmail.com').get();
      if (userDoc.docs.isEmpty) {
        print('Creating static admin account...');
        try {
          UserCredential cred = await auth.createUserWithEmailAndPassword(email: 'admin@gmail.com', password: 'Admin@123');
          await firestore.collection('users').doc(cred.user!.uid).set({'email': 'admin@gmail.com', 'role': 'admin', 'createdAt': FieldValue.serverTimestamp(), 'profileComplete': true});
          print('Admin account created successfully.');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            print('Admin email already in use in Auth, but missing in Firestore. Fixed.');
          } else {
            print('Failed to create admin auth account: ${e.message}');
          }
        }
      }
    } catch (e) {
      print('Error ensuring admin account exists: $e');
    }

    // Check if doctors already exist
    final snapshot = await doctorsCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      print('Doctors already exist in database. Skipping.');
      return;
    }

    final List<Map<String, dynamic>> sampleDoctors = [
      {
        'name': 'Dr. Sarah Wilson',
        'specialty': 'Neurologist',
        'rating': 4.8,
        'price': 150,
        'slots': 5,
        'image': 'https://firebasestorage.googleapis.com/v0/b/mad-project-c09af.firebasestorage.app/o/doctor_1.png?alt=media',
        'about': 'Dr. Sarah Wilson is a highly experienced Neurologist with over 12 years of experience in treating complex neurological disorders.',
        'qualification': 'MD, DM - Neurology',
        'location': 'City Central Hospital'
      },
      {
        'name': 'Dr. James Miller',
        'specialty': 'Cardiologist',
        'rating': 4.9,
        'price': 200,
        'slots': 3,
        'image': 'https://firebasestorage.googleapis.com/v0/b/mad-project-c09af.firebasestorage.app/o/doctor_2.png?alt=media',
        'about': 'Dr. James Miller is a renowned Cardiologist specializing in interventional cardiology and heart failure management.',
        'qualification': 'MD, FACC',
        'location': 'Metro Heart Institute'
      },
      {
        'name': 'Dr. Emily Chen',
        'specialty': 'Dentist',
        'rating': 4.7,
        'price': 80,
        'slots': 10,
        'image': '',
        'about': 'Dr. Emily Chen provides comprehensive dental care with a focus on preventive and cosmetic dentistry.',
        'qualification': 'DDS',
        'location': 'Smile Dental Clinic'
      },
      {
        'name': 'Dr. Robert Brown',
        'specialty': 'Therapist',
        'rating': 4.6,
        'price': 120,
        'slots': 8,
        'image': '',
        'about': 'Dr. Robert Brown is a licensed therapist specializing in cognitive behavioral therapy and mental wellness.',
        'qualification': 'PhD in Psychology',
        'location': 'Wellness Center'
      },
    ];

    for (var doctor in sampleDoctors) {
      await doctorsCollection.add(doctor);
    }
    print('Sample doctors added to database.');
  }
}
