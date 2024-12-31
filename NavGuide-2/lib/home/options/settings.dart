import 'package:flutter/material.dart';
import 'package:navguide/home/options/editProfile.dart';
import 'package:navguide/session/userModel.dart';
import 'package:provider/provider.dart';
import 'package:navguide/session/userProvider.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user =
        Provider.of<UserModel>(context); // Fetching user details from Provider

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Name: ${user.firstName}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Last Name: ${user.lastName}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Email: ${user.email}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Phone: ${user.phone}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Disability Type: ${user.disabilityType}',
                style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Gender: ${user.gender}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Address: ${user.address}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to the EditProfilePage
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(user: user),
                    ),
                  );
                },
                child: Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
