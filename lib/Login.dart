import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rrd/Signup.dart';
import 'package:rrd/HomePage.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscureText = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> loginUser() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Successful!")),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true, // Ensures the bottom fields are pushed up
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Text(
                "Welcome Back!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              Text("E-mail", style: TextStyle(fontSize: 14, color: Colors.black54)),
              TextField(
                controller: emailController,
                decoration: InputDecoration(border: UnderlineInputBorder()),
              ),
              SizedBox(height: 16),
              Text("Password", style: TextStyle(fontSize: 14, color: Colors.black54)),
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                    icon: obscureText ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Text("Forgot password?", style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: EdgeInsets.symmetric(horizontal: 100, vertical: 14),
                  ),
                  child: Text("Login", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade400)),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {}, // Implement Google Sign-In later
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network(
                          'https://banner2.cleanpng.com/20181108/vqy/kisspng-youtube-google-logo-google-images-google-account-consulting-crm-the-1-recommended-crm-for-g-suite-1713925083723.webp',
                          height: 24,
                        ),
                        SizedBox(width: 10),
                        Text("Sign in with Google", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Don’t have an account? ",
                    style: TextStyle(color: Colors.black54),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUpPage()),
                            );
                          },
                          child: Text(
                            "Sign Up",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom), // Adjust space when keyboard opens
            ],
          ),
        ),
      ),
    );
  }
}
