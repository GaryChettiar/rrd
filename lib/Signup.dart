import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rrd/Login.dart';
import 'package:rrd/SignUp2.dart';

class SignUpPage extends StatefulWidget {
  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  Future<void> _signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Account Created Successfully!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignUpPage2()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 40),
              Text(
                "Create An Account",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),

              // Email Input
              Text("E-mail", style: TextStyle(fontSize: 14, color: Colors.black54)),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(border: UnderlineInputBorder()),
              ),
              SizedBox(height: 16),

              // Password Input
              Text("Password", style: TextStyle(fontSize: 14, color: Colors.black54)),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: obscurePassword ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Confirm Password Input
              Text("Confirm Password", style: TextStyle(fontSize: 14, color: Colors.black54)),
              TextField(
                controller: confirmPasswordController,
                obscureText: obscureConfirmPassword,
                decoration: InputDecoration(
                  border: UnderlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                    icon: obscureConfirmPassword ? Icon(Icons.visibility) : Icon(Icons.visibility_off),
                    color: Colors.grey,
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Sign Up Button
              Center(
                child: isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 14),
                        ),
                        child: Text("Next", style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
              ),
              SizedBox(height: 20),

              // Login Text
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.black54),
                    children: [
                      WidgetSpan(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
