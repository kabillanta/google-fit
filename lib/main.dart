import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Data App',
      home: SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/fitness.activity.read', // Google Fit Scope
    ],
  );

  bool _isLoading = false;
  bool _isSignedIn = false;
  String _steps = "0";
  String _heartRate = "0";
  String _sleep = "0";

  Future<void> _handleSignIn() async {
    try {
      final user = await _googleSignIn.signIn();
      if (user == null) {
        print("User cancelled sign-in");
        return;
      }

      final auth = await user.authentication;
      final accessToken = auth.accessToken;

      if (accessToken != null) {
        print("Access Token: $accessToken");
        setState(() {
          _isLoading = true;
          _isSignedIn = true;
        });
        await _fetchFitnessData(accessToken);
      } else {
        print("Failed to get access token");
      }
    } catch (e) {
      print('Sign-in failed: $e');
    }
  }

  Future<void> _fetchFitnessData(String accessToken) async {
    const serverUrl =
        'http://172.16.70.13:5000/fetch-fitness-data'; // Update to your Flask server URL

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _steps = data['steps'].toString();
          _heartRate = data['heart_rate'].toString();
          _sleep = data['sleep_minutes'].toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _steps = "Error";
          _heartRate = "Error";
          _sleep = "Error";
          _isLoading = false;
        });
        print('Failed to fetch data: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      setState(() {
        _steps = "Error";
        _heartRate = "Error";
        _sleep = "Error";
        _isLoading = false;
      });
      print('Error connecting to server: $e');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _isSignedIn = false;
      _steps = "0";
      _heartRate = "0";
      _sleep = "0";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Fit Data')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _isSignedIn
                  ? _buildFitnessDataView()
                  : ElevatedButton(
                      onPressed: _handleSignIn,
                      child: const Text('Sign in with Google'),
                    ),
        ),
      ),
    );
  }

  Widget _buildFitnessDataView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fitness Data:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Steps: $_steps', style: const TextStyle(fontSize: 18)),
        Text('Heart Rate: $_heartRate bpm',
            style: const TextStyle(fontSize: 18)),
        Text('Sleep: $_sleep minutes', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _handleSignOut,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Logout', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
