import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_page.dart';
import 'kitchen_page.dart';
import 'register_page.dart';
import 'hall_access_page.dart';
import 'super_admin_home_page.dart';
import 'kingdom_school.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> loginUser() async {
    final String email = emailController.text.trim();
    final String pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showMessage("Please fill in email and password.");
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final UserCredential cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);

      final User? user = cred.user;
      if (user == null) {
        showMessage("Login error. Try again.");
        setState(() {
          loading = false;
        });
        return;
      }

      // Busca o papel (role) do usuário no Firestore
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = userDoc.data() != null
          ? Map<String, dynamic>.from(userDoc.data() as Map)
          : <String, dynamic>{};

      final String role = (data['role'] ?? '').toString();
      final String location =
          (data['location'] ?? 'Kingdom Boca Raton').toString();

      Widget nextPage;

            switch (role) {
        case 'superadmin':
          nextPage = const SuperAdminHomePage();
          break;

        case 'adminkbr':
        case 'adminkfl':
        case 'admin':
          nextPage = const AdminPage();
          break;

        case 'hallkbr':
          nextPage = const HallAccessPage(location: "Kingdom Boca Raton");
          break;
        case 'hallkfl':
          nextPage = const HallAccessPage(location: "Kingdom Fort Lauderdale");
          break;
        case 'hallkpl':
          nextPage = const HallAccessPage(location: "Kingdom Port St. Lucie");
          break;

        case 'kitchenkbr':
          nextPage = const KitchenPage(location: "Kingdom Boca Raton");
          break;
        case 'kitchenkfl':
          nextPage = const KitchenPage(location: "Kingdom Fort Lauderdale");
          break;
        case 'kitchenkpl':
          nextPage = const KitchenPage(location: "Kingdom Port St. Lucie");
          break;

        case 'server':
          nextPage = const KingdomSchoolHomePage();
          break;

        default:
          nextPage = const UserPage();
          break;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Login failed.");
    } catch (e) {
      showMessage("Unexpected error: $e");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Login"),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text("Create account"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Página simples caso o usuário não tenha um role específico
class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Home"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          "Welcome, User 🙋‍♀️",
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}