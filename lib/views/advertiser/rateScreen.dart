import 'package:flutter/material.dart';
import '../../models/adAssignment.dart';
import '../../models/rating.dart';
import '../../services/RatingApiService.dart';


// NOTE: you must provide currentUserId from your auth/session (SharedPreferences, Provider, etc.)
class RateDriverScreen extends StatefulWidget {
  final AdAssignment assignment;
  final int adId;
  final int currentUserId;

  const RateDriverScreen({
    super.key,
    required this.assignment,
    required this.adId,
    required this.currentUserId,
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _rating = 0;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a rating (1 to 5).")),
      );
      return;
    }

    setState(() => _submitting = true);

    final model = Rating(
      ratedBy: widget.currentUserId,
      ratedTo: widget.assignment.assignId,
      ratePoints: _rating.toDouble(),
      adId: widget.adId,
      assignId: widget.assignment.assignId,
    );

    final result = await RatingApiService.addRating(model);

    if (!mounted) return;

    setState(() => _submitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );

    if (result.success) {
      Navigator.pop(context, true); // return true => refresh list
    }
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final index = i + 1;
        final filled = index <= _rating;

        return IconButton(
          onPressed: _submitting ? null : () => setState(() => _rating = index),
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: filled ? Colors.amber : Colors.grey,
            size: 34,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text("Rate Driver", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Driver header
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundImage: AssetImage("assets/profile.png"),
                    ),
                    const SizedBox(width: 12),
                    // Expanded(
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //         widget.assignment.driverName,
                    //         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    //       ),
                    //       const SizedBox(height: 2),
                    //       Text("${widget.assignment.vehicleModel}"),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  "How was your experience?",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Your feedback helps drivers improve their service",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 12),
                _buildStars(),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Submit Rating"),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text("Skip for now"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}