import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class User {
  String username;
  String email;

  User({required this.username, required this.email});
}

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> registerUser(String username, String email, String password) async {
    try {
      // Create a new user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add user data to Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The email address is already in use by another user.');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<User?> loginUser(String email, String password) async {
    try {
      // Sign in user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Return the signed-in user object
      return User(
        username: userCredential.user!.displayName ?? '', // Modify as needed
        email: userCredential.user!.email ?? '',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No user found for the provided email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      }
      return null;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> getUser(String uid) async {
    // Get user document from Firestore
    DocumentSnapshot documentSnapshot = await _firestore.collection('users').doc(uid).get();

    // Check if document exists and return user data if found
    if (documentSnapshot.exists) {
      return User(
        username: documentSnapshot.data()!['username'] as String,
        email: documentSnapshot.data()!['email'] as String,
      );
    } else {
      return null;
    }
  }
}

class MyApp extends StatelessWidget {
  final UserRepository userRepository = UserRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('User Management'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Navigate to registration screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationScreen(userRepository: userRepository)),
                  );
                },
                child: Text('Register'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen(userRepository: userRepository)),
                  );
                },
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistrationScreen extends StatefulWidget {
  final UserRepository userRepository;

  const RegistrationScreen({Key? key, required this.userRepository}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Dispose the controllers to avoid memory leaks
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String username = usernameController.text;
                String email = emailController.text;
                String password = passwordController.text;

                // Register user with Firebase
                try {
                  await widget.userRepository.registerUser(username, email, password);

                  // Show success message or navigate based on results
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      // ... (success message content)
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  // Handle registration errors (e.g., invalid email, weak password)
                  // ... (display appropriate error message to the user)
                }
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final UserRepository userRepository;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen(this.userRepository);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                String username = usernameController.text;
                String password = passwordController.text;

                // Login user with Firebase
                User? user = await userRepository.loginUser(username, password);

                if (user != null) {
                  // Navigate to user profile screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserProfileScreen(user)),
                  );
                } else {
                  // Show error message
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Error'),
                      content: Text('Invalid username or password.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('OK'),
      
