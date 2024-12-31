import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart'; // Text-to-Speech package
import 'package:validators/validators.dart'; // For email validation
import 'package:firebase_auth/firebase_auth.dart'; // For Firebase Authentication
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore Database
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // Speech-to-Text package

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final FlutterTts _flutterTts = FlutterTts();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final stt.SpeechToText _speech = stt.SpeechToText();

  String? _firstName,
      _lastName,
      _email,
      _phone,
      _address,
      _disabilityType,
      _gender,
      _password;
  bool _isListening = false;
  String _currentField = '';

  // TextEditingControllers to dynamically update the fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _disabilityTypeController =
      TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final List<String> _disabilityTypes = [
    'Visual',
    'Hearing',
    'Mobility',
    'Cognitive'
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage('en-US');
    _speak(
        "Welcome! Please fill out the registration form. You can use voice input by pressing the microphone buttons.");
  }

  void _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        // Create user with email and password
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _email!,
          password: _password!,
        );

        // Save additional user data to Firestore
        await _firestore.collection('users').doc(_email).set({
          'userId': userCredential.user!.uid,
          'firstName': _firstName,
          'lastName': _lastName,
          'email': _email,
          'phone': _phone,
          'address': _address,
          'disabilityType': _disabilityType,
          'gender': _gender,
        });

        _speak("Registration successful! Redirecting to login page.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Registration successful! Redirecting to login page.'),
          ),
        );

        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(context);
      } catch (e) {
        print('Error: $e');

        _speak("Registration failed. Please try again.");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleVoiceInput(String fieldName) async {
    setState(() {
      _currentField = fieldName;
    });

    _speak("Please say your $fieldName.");

    bool available = await _speech.initialize(
      onError: (val) {
        print('Speech recognition error: $val');
        _speak("An error occurred. Please try again.");
      },
      onStatus: (val) {
        print('Speech recognition status: $val');
      },
    );

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (val) {
          if (val.hasConfidenceRating && val.confidence > 0) {
            setState(() {
              String recognizedWords = val.recognizedWords;
              switch (fieldName) {
                case 'first name':
                  _firstNameController.text = recognizedWords;
                  _firstName = recognizedWords;
                  break;
                case 'last name':
                  _lastNameController.text = recognizedWords;
                  _lastName = recognizedWords;
                  break;
                case 'email':
                  _emailController.text = recognizedWords;
                  _email = recognizedWords;
                  break;
                case 'phone number':
                  _phoneController.text = recognizedWords;
                  _phone = recognizedWords;
                  break;
                case 'address':
                  _addressController.text = recognizedWords;
                  _address = recognizedWords;
                  break;
                case 'password':
                  _passwordController.text = recognizedWords;
                  _password = recognizedWords;
                  break;
                default:
                  break;
              }

              // Speak back the recognized value to the user
              _speak("You entered $recognizedWords for $fieldName.");
            });
          }
        },
      );
    } else {
      _speak("Speech recognition not available.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Speech recognition not available.")),
      );
      return;
    }
  }

  Future<void> _stopListeningAndProcess() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });

    // Provide instant feedback by setting text in the corresponding field
    _speak("Field updated.");
  }

  Future<void> _centralizedVoiceInput() async {
    _speak("Which field would you like to fill?");

    bool available = await _speech.initialize();

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(onResult: (val) {
        if (val.hasConfidenceRating && val.confidence > 0) {
          setState(() {
            _currentField = val.recognizedWords.toLowerCase();
          });

          _speak("You chose $_currentField. Please say your $_currentField.");
          _handleVoiceInput(_currentField);
        }
      });
    } else {
      _speak("Speech recognition not available.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Speech recognition not available.")),
      );
    }
  }

  Widget _buildDropdownFormField({
    required String label,
    required String fieldName,
    required String? value,
    required List<String> items,
    required FormFieldSetter<String> onSaved,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: GestureDetector(
              onLongPressStart: (_) async {
                if (!_isListening) {
                  await _handleVoiceInput(fieldName);
                }
              },
              onLongPressEnd: (_) async {
                if (_isListening && _currentField == fieldName) {
                  await _stopListeningAndProcess();
                }
              },
              child: Icon(
                Icons.mic,
                color: _isListening && _currentField == fieldName
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
          ),
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              if (fieldName == 'disability type') {
                _disabilityType = newValue!;
                _disabilityTypeController.text = newValue;
              } else if (fieldName == 'gender') {
                _gender = newValue!;
                _genderController.text = newValue;
              }
            });
          },
          onSaved: onSaved,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTextFormField({
    required String label,
    required String fieldName,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: GestureDetector(
              onLongPressStart: (_) async {
                if (!_isListening) {
                  await _handleVoiceInput(fieldName);
                }
              },
              onLongPressEnd: (_) async {
                if (_isListening && _currentField == fieldName) {
                  await _stopListeningAndProcess();
                }
              },
              child: Icon(
                Icons.mic,
                color: _isListening && _currentField == fieldName
                    ? Colors.red
                    : Colors.grey,
              ),
            ),
          ),
          textInputAction: TextInputAction.next,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onSaved: onSaved,
        ),
        SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              _buildTextFormField(
                label: 'First Name',
                fieldName: 'first name',
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _firstName = value;
                },
              ),
              _buildTextFormField(
                label: 'Last Name',
                fieldName: 'last name',
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _lastName = value;
                },
              ),
              _buildTextFormField(
                label: 'Email',
                fieldName: 'email',
                controller: _emailController,
                validator: (value) {
                  if (value == null || !isEmail(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
                onSaved: (value) {
                  _email = value;
                },
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextFormField(
                label: 'Phone Number',
                fieldName: 'phone number',
                controller: _phoneController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
                onSaved: (value) {
                  _phone = value;
                },
                keyboardType: TextInputType.phone,
              ),
              _buildTextFormField(
                label: 'Address',
                fieldName: 'address',
                controller: _addressController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
                onSaved: (value) {
                  _address = value;
                },
              ),
              _buildDropdownFormField(
                label: 'Disability Type',
                fieldName: 'disability type',
                value: _disabilityType,
                items: _disabilityTypes,
                onSaved: (value) {
                  _disabilityType = value;
                },
              ),
              _buildDropdownFormField(
                label: 'Gender',
                fieldName: 'gender',
                value: _gender,
                items: _genders,
                onSaved: (value) {
                  _gender = value;
                },
              ),
              _buildTextFormField(
                label: 'Password',
                fieldName: 'password',
                controller: _passwordController,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value;
                },
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Register'),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.mic),
                label: Text('Use Voice Input'),
                onPressed: _centralizedVoiceInput,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _disabilityTypeController.dispose();
    _genderController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
