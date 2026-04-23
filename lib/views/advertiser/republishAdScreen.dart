import 'package:flutter/material.dart';
import '../../models/Ad.dart';
import '../../services/AdApiService.dart';

class RepublishAdScreen extends StatefulWidget {
  final Ad ad;

  const RepublishAdScreen({super.key, required this.ad});

  @override
  State<RepublishAdScreen> createState() =>
      _RepublishAdScreenState();
}

class _RepublishAdScreenState
    extends State<RepublishAdScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController titleController;
  late TextEditingController categoryController;

  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();

    titleController =
        TextEditingController(text: widget.ad.adTitle);

    categoryController =
        TextEditingController(text: widget.ad.Category);

    startDate = widget.ad.StartingDate;
    endDate = widget.ad.EndingDate;
  }

  Future<void> _republish() async {
    if (!_formKey.currentState!.validate()) return;

    if (endDate.isBefore(startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "End date must be after start date"),
        ),
      );
      return;
    }

    // 👇 Create new Ad object using SAME MEDIA
    Ad newAd = Ad(
      adId: 0,
      adTitle: titleController.text,
      mediaType: widget.ad.mediaType,
      mediaName: widget.ad.mediaName,
      mediaPath: widget.ad.mediaPath,
      userId: widget.ad.userId,
      userName: widget.ad.userName,
      userRole: widget.ad.userRole,
      status: "inactive",
      StartingDate: startDate,
      EndingDate: endDate,
      Category: categoryController.text,
    );

    bool success =
    await AdApiService.republishAd(newAd);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text("Ad Republished Successfully"),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text("Failed to republish ad"),
        ),
      );
    }
  }

  Future<void> _pickDate(bool isStart) async {
    DateTime initialDate =
    isStart ? startDate : endDate;

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        backgroundColor: const Color(0xff00c4aa),
        title: const Text(
          "Republish Ad",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme:
        const IconThemeData(color: Colors.black),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [

              // ================= MEDIA PREVIEW =================

              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius:
                  BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius:
                  BorderRadius.circular(16),
                  child: Image.network(
                    widget.ad.mediaPath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Center(
                      child: Icon(
                        Icons.image,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ================= TITLE =================

              TextFormField(
                controller: titleController,
                validator: (v) =>
                v!.isEmpty ? "Required" : null,
                decoration: const InputDecoration(
                  labelText: "Ad Title",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 15),

              // ================= CATEGORY =================

              TextFormField(
                controller: categoryController,
                validator: (v) =>
                v!.isEmpty ? "Required" : null,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              // ================= START DATE =================

              GestureDetector(
                onTap: () => _pickDate(true),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Text(
                        "Start Date: ${startDate.toLocal().toString().split(' ')[0]}",
                      ),
                      const Icon(
                          Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ================= END DATE =================

              GestureDetector(
                onTap: () => _pickDate(false),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.grey),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Text(
                        "End Date: ${endDate.toLocal().toString().split(' ')[0]}",
                      ),
                      const Icon(
                          Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ================= REPUBLISH BUTTON =================

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _republish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xff00c4aa),
                  ),
                  child: const Text(
                    "Republish Ad",
                    style: TextStyle(
                        fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}