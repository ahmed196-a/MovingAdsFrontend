import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text(
          "Account",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          // PROFILE CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AVATAR
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, size: 32),
                ),

                const SizedBox(width: 12),

                // USER INFO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Ahmed Abbas",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Chip(
                        label: Text("Advertiser"),
                        backgroundColor: Colors.teal,
                        labelStyle:
                        TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      SizedBox(height: 4),
                      Text("Email: ahmed123@gmail.com"),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text("Completed Ads : 1"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // EDIT PROFILE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/editProfile");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Edit Profile",
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // LOGOUT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, "/login");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Logout",
                  style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),

    );
  }
}
