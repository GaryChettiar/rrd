import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DonationTracker.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String name = "Loading...";
  String contact = "Loading...";
  String bloodGroup = "Loading...";
  int donations = 0;
  String email = "";
  bool isDonor = false; // Variable to store donor status
  DateTime? latestDonation; // Variable to store latest donation date
  bool isEligibleToDonate = false; // Variable to track eligibility

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        email = user.email ?? "No Email";
      });

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('uid', isEqualTo: user.uid) // Find user by UID
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        
        // Get latest donation date if it exists
        if (userData.containsKey('latestDonation') && userData['latestDonation'] != null) {
          latestDonation = (userData['latestDonation'] as Timestamp).toDate();
        }
        
        // Check eligibility - user is a donor AND either has no donation record OR last donation was > 3 months ago
        bool eligible = userData['isDonor'] ?? false;
        if (eligible && latestDonation != null) {
          final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
          
          // Debug print to verify date comparison
          print("Latest donation: ${latestDonation.toString()}");
          print("Three months ago: ${threeMonthsAgo.toString()}");
          print("Is before: ${latestDonation!.isBefore(threeMonthsAgo)}");
          
          // Correct comparison: user is eligible if latest donation is BEFORE three months ago
          eligible = latestDonation!.isBefore(threeMonthsAgo);
          
          // Additional safety check - compare timestamps directly
          final latestDonationTimestamp = latestDonation!.millisecondsSinceEpoch;
          final threeMonthsAgoTimestamp = threeMonthsAgo.millisecondsSinceEpoch;
          
          print("Latest donation timestamp: $latestDonationTimestamp");
          print("Three months ago timestamp: $threeMonthsAgoTimestamp");
          print("Difference in days: ${(threeMonthsAgoTimestamp - latestDonationTimestamp) / (1000 * 60 * 60 * 24)}");
          
          // Double-check eligibility with timestamp comparison
          eligible = latestDonationTimestamp < threeMonthsAgoTimestamp;
          print("Final eligibility: $eligible");
        }
        
        setState(() {
          name = userData['name'] ?? "Unknown";
          contact = userData['contact'] ?? "No Contact";
          bloodGroup = userData['bloodType'] ?? "Unknown";
          donations = userData['donations'] ?? 0;
          isDonor = userData['isDonor'] ?? false;
          isEligibleToDonate = eligible;
        });
      }
    }
  }

  // Format the latest donation date
  String getLastDonationText() {
    if (latestDonation == null) {
      return "No donation record";
    }
    
    // Calculate days since last donation
    final daysSinceLastDonation = DateTime.now().difference(latestDonation!).inDays;
    
    // Format the date with day, month, and year
    String formattedDate = "${latestDonation!.day}/${latestDonation!.month}/${latestDonation!.year}";
    
    // Add days since donation for clarity
    return "$formattedDate ($daysSinceLastDonation days ago)";
  }

  // Calculate days until eligible
  String getDaysUntilEligible() {
    if (latestDonation == null || isEligibleToDonate) {
      return "";
    }
    
    // Calculate eligibility date (3 months after last donation)
    final eligibilityDate = latestDonation!.add(const Duration(days: 90));
    
    // Calculate days remaining until eligible
    final daysRemaining = eligibilityDate.difference(DateTime.now()).inDays;
    
    if (daysRemaining <= 0) {
      return "Eligibility calculation error";
    }
    
    return "Eligible in $daysRemaining days";
  }

  // Logout function
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Navigate to login screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Profile Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.pink[100], // Light pink background
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile Image
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/profile.jpg'), // Change to actual image path
                    ),
                    SizedBox(width: 16),
                    // User Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        Text(
                          contact,
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        
            // Blood Group and Total Donations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(
                        bloodGroup,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Blood Group',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                  // Vertical Divider
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.black26,
                    margin: EdgeInsets.symmetric(horizontal: 30),
                  ),
                  Column(
                    children: [
                      Text(
                        '$donations',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Total Donations',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Last Donation Date
            if (latestDonation != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Colors.blue[700],
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Last Donation: ${getLastDonationText()}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Donor Status
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEligibleToDonate ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isEligibleToDonate ? Icons.check_circle : Icons.cancel,
                          color: isEligibleToDonate ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          isEligibleToDonate 
                              ? "Eligible to Donate" 
                              : (isDonor 
                                  ? "Not Eligible (Recent Donation)" 
                                  : "Not a Donor"),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isEligibleToDonate ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    
                    // Show days until eligible if user is a donor but not eligible
                    if (isDonor && !isEligibleToDonate && latestDonation != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          getDaysUntilEligible(),
                          style: TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Donation Tracker Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DonationTracker()),
                  ).then((_) {
                    // Refresh user data when returning from donation tracker
                    _fetchUserData();
                  });
                },
                icon: Icon(Icons.bloodtype),
                label: Text("Manage Donation History"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffA5231D),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ),
        
            Spacer(),
        
            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Red logout button
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
