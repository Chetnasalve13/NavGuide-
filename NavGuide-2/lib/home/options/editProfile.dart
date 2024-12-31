import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:navguide/session/userModel.dart';

class EditProfilePage extends StatefulWidget {
  final UserModel user;

  EditProfilePage({required this.user});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late String firstName;
  late String lastName;
  late String phone;
  late String disabilityType;
  late String gender;
  late String address;

  @override
  void initState() {
    super.initState();
    firstName = widget.user.firstName;
    lastName = widget.user.lastName;
    phone = widget.user.phone;
    disabilityType = widget.user.disabilityType;
    gender = widget.user.gender;
    address = widget.user.address;
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Update the user data in Firebase Firestore using email as the identifier
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.email)
            .update({
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'disabilityType': disabilityType,
          'gender': gender,
          'address': address,
        });

        // Show success dialog and prompt for re-login
        _showSuccessDialog();
      } catch (e) {
        // Handle any errors here
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update profile. Please try again.')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Profile Updated'),
          content: Text(
              'Your profile has been updated successfully. Please log in again to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                _reLogin();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reLogin() async {
    // Log out the user
    await FirebaseAuth.instance.signOut();

    // Navigate to the login page or any other appropriate page
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: firstName,
                decoration: InputDecoration(labelText: 'First Name'),
                onSaved: (value) => firstName = value!,
              ),
              TextFormField(
                initialValue: lastName,
                decoration: InputDecoration(labelText: 'Last Name'),
                onSaved: (value) => lastName = value!,
              ),
              TextFormField(
                initialValue: phone,
                decoration: InputDecoration(labelText: 'Phone'),
                onSaved: (value) => phone = value!,
              ),
              TextFormField(
                initialValue: disabilityType,
                decoration: InputDecoration(labelText: 'Disability Type'),
                onSaved: (value) => disabilityType = value!,
              ),
              TextFormField(
                initialValue: gender,
                decoration: InputDecoration(labelText: 'Gender'),
                onSaved: (value) => gender = value!,
              ),
              TextFormField(
                initialValue: address,
                decoration: InputDecoration(labelText: 'Address'),
                onSaved: (value) => address = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
