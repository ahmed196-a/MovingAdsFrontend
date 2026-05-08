import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/request.dart';
import '../../services/requestApiService.dart';

class SentRequestScreen extends StatefulWidget {
  const SentRequestScreen({super.key});

  @override
  State<SentRequestScreen> createState() => _SentRequestScreenState();
}

class _SentRequestScreenState extends State<SentRequestScreen> {
  List<Request> allRequests = [];
  List<Request> filteredRequests = [];

  bool isLoading = true;
  int? userId;

  String selectedStatus = "pending";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('userId');

    if (userId != null) {
      allRequests = await RequestApiService.getSentRequests(userId!); // ✅ Sent
      _applyFilter();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _applyFilter() {
    filteredRequests = allRequests
        .where((r) => r.status!.toLowerCase() == selectedStatus)
        .toList();
  }

  Widget _buildFilterButton(String status) {
    bool isSelected = selectedStatus == status;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedStatus = status;
            _applyFilter();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff18B6A3) : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("Sent Requests"), // ✅ Correct title
        backgroundColor: const Color(0xff18B6A3),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [

          /// 🔹 FILTER BUTTONS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFilterButton("pending"),
                const SizedBox(width: 8),
                _buildFilterButton("accepted"),
                const SizedBox(width: 8),
                _buildFilterButton("rejected"),
              ],
            ),
          ),

          /// 🔹 REQUEST LIST
          Expanded(
            child: filteredRequests.isEmpty
                ? const Center(child: Text("No Requests Found"))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          "To: ${request.toUser ?? "N/A"}", // ✅ Show recipient
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text("Agency: ${request.agencyId}"),

                        const SizedBox(height: 6),

                        Text("Ad: ${request.adTitle}"),

                        const SizedBox(height: 6),

                        Text(
                          "Status: ${request.status}",
                          style: TextStyle(
                            color: _statusColor(request.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),


                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}