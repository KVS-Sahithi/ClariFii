import 'dart:developer';

import 'package:auth_firebase/auth/auth_service.dart';
import 'package:auth_firebase/widgets/home_screen.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _auth = AuthService();

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _age = TextEditingController();

  String? errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const Spacer(),
            const Text(
              "Sign Up",
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),

            // Email
            TextField(
              controller: _email,
              decoration: const InputDecoration(
                labelText: "Email",
                hintText: "Enter Email",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Password
            TextField(
              controller: _password,
              decoration: const InputDecoration(
                labelText: "Password",
                hintText: "Enter Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Age
            TextField(
              controller: _age,
              decoration: const InputDecoration(
                labelText: "Age",
                hintText: "Enter your age",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signup,
              child: const Text("Sign Up"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void goToHome(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _signup() async {
    setState(() => errorMessage = null);

    final email = _email.text.trim();
    final password = _password.text.trim();
    final ageText = _age.text.trim();

    if (email.isEmpty || password.isEmpty || ageText.isEmpty) {
      setState(() => errorMessage = "All fields are required.");
      return;
    }

    int? age = int.tryParse(ageText);
    if (age == null || age <= 0) {
      setState(() => errorMessage = "Please enter a valid age.");
      return;
    }

    try {
      final user = await _auth.createUserWithEmailAndPassword(email, password);

      if (user != null) {
        log("User Registered with age: $age");

        // Optional: Store age in Firestore if needed
        // await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        //   "email": email,
        //   "age": age,
        // });

        goToHome(context);
      } else {
        setState(() => errorMessage = "Signup failed. Try again.");
      }
    } catch (e) {
      setState(() => errorMessage = e.toString());
    }
  }
}
