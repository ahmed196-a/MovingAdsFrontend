import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/AdApiService.dart';

class PostNewAdScreen extends StatefulWidget {
  const PostNewAdScreen({super.key});

  @override
  State<PostNewAdScreen> createState() => _PostNewAdScreenState();
}

class _PostNewAdScreenState extends State<PostNewAdScreen> {
  String? adType;
  String? category;

  DateTime? startDate;
  DateTime? endDate;

  File? selectedMedia;

  final ImagePicker _picker = ImagePicker();

  final TextEditingController titleController = TextEditingController();

  // ================= MEDIA PICKER =================

  Future<void> pickMedia() async {
    if (adType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Ad Type first")),
      );
      return;
    }

    XFile? file;

    if (adType == "Image") {
      file = await _picker.pickImage(source: ImageSource.gallery);
    } else if (adType == "Video") {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    }

    if (file != null) {
      setState(() {
        selectedMedia = File(file!.path);
      });
    }
  }

  // ================= DATE PICKER =================

  Future<void> pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      // ── Date validation ──────────────────────────
      if (!isStart && startDate != null && !picked.isAfter(startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("End date must be after start date")),
        );
        return;
      }
      if (isStart && endDate != null && !picked.isBefore(endDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Start date must be before end date")),
        );
        return;
      }

      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Post New Ad",
          style: TextStyle(color: Colors.black),
        ),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // MAIN CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ================= AD CONTENT =================
                  const Text(
                    "Ad Content*",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: pickMedia,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: selectedMedia == null
                          ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload, size: 40),
                            SizedBox(height: 8),
                            Text("Upload Ad Image or Video"),
                          ],
                        ),
                      )
                          : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: adType == "Image"
                            ? Image.file(
                          selectedMedia!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                            : const Center(
                          child: Icon(Icons.videocam, size: 50),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ================= AD TITLE =================
                  const Text(
                    "Ad Title*",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Enter ad title",
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= AD TYPE =================
                  const Text("Ad Type"),
                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    value: adType,
                    items: const [
                      DropdownMenuItem(value: "Image", child: Text("Image")),
                      DropdownMenuItem(value: "Video", child: Text("Video")),
                    ],
                    onChanged: (value) {
                      setState(() => adType = value);
                    },
                    decoration: _dropdownDecoration(),
                  ),

                  const SizedBox(height: 14),

                  // ================= CATEGORY =================
                  const Text(
                    "Category*",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  DropdownButtonFormField<String>(
                    value: category,
                    items: const [
                      DropdownMenuItem(value: "Retail", child: Text("Retail")),
                      DropdownMenuItem(value: "Education", child: Text("Education")),
                      DropdownMenuItem(value: "Fashion", child: Text("Fashion")),
                    ],
                    onChanged: (value) {
                      setState(() => category = value);
                    },
                    decoration: _dropdownDecoration(hint: "Select Category"),
                  ),

                  const SizedBox(height: 14),

                  // ================= DATES =================
                  Row(
                    children: [
                      Expanded(child: _dateField("Start Date*", true)),
                      const SizedBox(width: 12),
                      Expanded(child: _dateField("End Date*", false)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= ACTION BUTTONS =================
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {

                      if (selectedMedia == null ||
                          adType == null ||
                          category == null ||
                          startDate == null ||
                          endDate == null ||
                          titleController.text.isEmpty) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill all required fields")),
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('userId');

                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User not logged in")),
                        );
                        return;
                      }

                      bool success = await AdApiService.postAd(
                        title: titleController.text,
                        mediaType: adType!,
                        category: category!,
                        startingDate: startDate!,
                        endingDate: endDate!,
                        userId: userId,
                        mediaFile: selectedMedia!,
                        status: "inactive",
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ad Posted Successfully")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to post ad")),
                        );
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Post Ad"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {

                      if (selectedMedia == null ||
                          adType == null ||
                          category == null ||
                          startDate == null ||
                          endDate == null ||
                          titleController.text.isEmpty) {

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please fill all required fields")),
                        );
                        return;
                      }

                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('userId');

                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("User not logged in")),
                        );
                        return;
                      }

                      bool success = await AdApiService.postAd(
                        title: titleController.text,
                        mediaType: adType!,
                        category: category!,
                        startingDate: startDate!,
                        endingDate: endDate!,
                        userId: userId,
                        mediaFile: selectedMedia!,
                        status: "drafted",
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ad Saved as Draft")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to save draft")),
                        );
                      }
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text("Save to Drafts"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade300,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Cancel"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= DECORATION =================

  InputDecoration _dropdownDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade200,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ================= DATE FIELD =================

  Widget _dateField(String label, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => pickDate(isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isStart
                      ? (startDate == null
                      ? "Select date"
                      : "${startDate!.day}/${startDate!.month}/${startDate!.year}")
                      : (endDate == null
                      ? "Select date"
                      : "${endDate!.day}/${endDate!.month}/${endDate!.year}"),
                ),
                const Icon(Icons.calendar_today),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
