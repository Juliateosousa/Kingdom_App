import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPassController = TextEditingController();
  final codeController = TextEditingController();

  bool loading = false;

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> registerUser() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final confirm = confirmPassController.text.trim();

    if (email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (pass != confirm) {
      showMessage("Passwords do not match");
      return;
    }

    if (Firebase.apps.isEmpty) {
      showMessage("Firebase is not initialized. (Works on Android for now)");
      return;
    }

    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: pass,
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final code = codeController.text.trim();
      String role = "user";

      if (code == "AdministratorKingdom") {
        role = "superadmin";
      } else if (code == "Administrator") {
        role = "adminkbr";
      } else if (code == "SalãoKbr") {
        role = "hallkbr";
      } else if (code == "KitchenKbr") {
        role = "kitchenkbr";
      } else if (code == "SalãoKfl") {
        role = "hallkfl";
      } else if (code == "KitchenKfl") {
        role = "kitchenkfl";
      } else if (code == "SalãoKpl") {
        role = "hallkpl";
      } else if (code == "KitchenKpl") {
        role = "kitcherkpl";
      } else if (code == "Server") {
        role = "server";
      }

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "email": email,
        "role": role,
      });

      showMessage("Account created successfully!");

      if (!mounted) return;
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException in registerUser:');
      debugPrint('  code: ${e.code}');
      debugPrint('  message: ${e.message}');
      final msg = e.message ?? "Firebase error: ${e.code}";
      showMessage(msg);
    } catch (e, st) {
      debugPrint('🔥 Unexpected error in registerUser: $e');
      debugPrint(st.toString());
      showMessage("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm password"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: "Access code (optional)",
              ),
            ),
            const SizedBox(height: 12),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registerUser,
                    child: const Text("Create account"),
                  ),
          ],
        ),
      ),
    );
  }
}