import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'package:navguide/session/userProvider.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _command = '';

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('en-US');
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> _handleVoiceCommand() async {
    _speak(
        "Please say one of the following options: Saved Routes, Start Navigation, Settings, or Logout.");

    bool available = await _speech.initialize();

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(onResult: (val) {
        if (val.hasConfidenceRating && val.confidence > 0) {
          setState(() {
            _command = val.recognizedWords.toLowerCase();
          });

          _speak("You said $_command.");

          if (_command.contains("saved routes")) {
            Navigator.pushNamed(context, '/saved_routes');
          } else if (_command.contains("start navigation")) {
            Navigator.pushNamed(context, '/start_navigation');
          } else if (_command.contains("settings")) {
            Navigator.pushNamed(context, '/settings');
          } else if (_command.contains("logout")) {
            _logout();
          } else {
            _speak("Command not recognized. Please try again.");
          }
        }
      });
    } else {
      _speak("Speech recognition not available.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Speech recognition not available.")),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      appBar: AppBar(
        title: Text('NavGuide Home'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome ${user?.firstName ?? 'User'}!!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Navigate through the app using the buttons below.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/saved_routes');
                },
                icon: Icon(Icons.map),
                label: Text('Saved Routes'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
              // const SizedBox(height: 20),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.pushNamed(context, '/start_navigation');
              //   },
              //   icon: Icon(Icons.directions_walk),
              //   label: Text('Start Navigation'),
              //   style: ElevatedButton.styleFrom(
              //     padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              //   ),
              // ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
                icon: Icon(Icons.settings),
                label: Text('Settings'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _logout();
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  backgroundColor: Colors.red,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  if (!_isListening) {
                    await _handleVoiceCommand();
                  }
                },
                icon: Icon(Icons.mic),
                label: Text('Voice Navigation'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _speech.stop();
    super.dispose();
  }
}
