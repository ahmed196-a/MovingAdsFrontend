import 'package:flutter/material.dart';

import '../../models/adSchedule.dart';
import '../../services/adScheduleApiService.dart';


class AdScheduleScreen extends StatefulWidget {
  final int adId;

  const AdScheduleScreen({super.key, required this.adId});

  @override
  State<AdScheduleScreen> createState() => _AdScheduleScreenState();
}

class _AdScheduleScreenState extends State<AdScheduleScreen> {

  // ── Default slots — same names already in your DB ─────────
  List<String> slots = [
    "8-10 AM",
    "12-2 PM",
    "4-6 PM",
    "8-10 PM",
  ];

  final List<String> days = [
    "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"
  ];

  late List<List<bool>> schedule;

  // For the "add slot" dialog
  final _slotController = TextEditingController();
  final _slotFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initSchedule();
  }

  void _initSchedule() {
    schedule = List.generate(
      slots.length,
          (_) => List.generate(days.length, (_) => false),
    );
  }

  // ── Validate format: "H-H AM", "HH-HH PM", etc. ──────────
  // Accepts: "8-10 AM", "12-2 PM", "9-11 AM", etc.
  String? _validateSlotName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Slot name required";
    }

    // Pattern: one or two digits, dash, one or two digits, space, AM or PM
    final regex = RegExp(r'^\d{1,2}-\d{1,2}\s+(AM|PM)$');
    if (!regex.hasMatch(value.trim())) {
      return "Format must be like  8-10 AM  or  12-2 PM";
    }

    // Check for duplicate
    if (slots.contains(value.trim())) {
      return "This slot already exists";
    }

    return null;
  }

  // ── Add a new slot row ────────────────────────────────────
  void _addSlot() {
    _slotController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Time Slot"),
        content: Form(
          key: _slotFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Format examples:",
                style: TextStyle(
                    fontSize: 12, color: Colors.black54),
              ),
              const Text(
                "  8-10 AM    12-2 PM    4-6 PM    9-11 PM",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.teal,
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slotController,
                validator: _validateSlotName,
                decoration: InputDecoration(
                  hintText: "e.g.  8-10 AM",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_slotFormKey.currentState!.validate()) {
                setState(() {
                  slots.add(_slotController.text.trim());
                  // Add a new row of unchecked days
                  schedule.add(
                      List.generate(days.length, (_) => false));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff18B6A3)),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ── Delete a slot row ─────────────────────────────────────
  void _deleteSlot(int row) {
    setState(() {
      slots.removeAt(row);
      schedule.removeAt(row);
    });
  }

  String _convertRowToBits(int row) {
    return schedule[row].map((e) => e ? "1" : "0").join();
  }

  Future<void> _saveSchedule() async {
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one slot")),
      );
      return;
    }

    List<AdScheduleModel> data = [];
    for (int i = 0; i < slots.length; i++) {
      data.add(AdScheduleModel(
        adID:     widget.adId,
        slotName: slots[i],
        bits:     _convertRowToBits(i),
      ));
    }

    bool success = await AdScheduleApiService.saveSchedule(data);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schedule Saved")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Ad Schedule"),
        backgroundColor: const Color(0xff18B6A3),
        actions: [
          // Add slot button in app bar
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: "Add Time Slot",
            onPressed: _addSlot,
          ),
        ],
      ),

      body: Column(
        children: [

          // ── FORMAT HINT ────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xff18B6A3).withOpacity(0.4)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline,
                    size: 18, color: Color(0xff18B6A3)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Slot format: H-H AM  or  H-H PM  (e.g. 8-10 AM, 12-2 PM)\nTap + to add a custom slot.",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // ── SCHEDULE TABLE ──────────────────────────────
          Expanded(
            child: slots.isEmpty
                ? const Center(
              child: Text(
                "No slots yet.\nTap + to add one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45),
              ),
            )
                : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                      const Color(0xff18B6A3).withOpacity(0.15)),
                  columns: [
                    const DataColumn(
                        label: Text("Slot",
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    ...days.map(
                          (d) => DataColumn(
                        label: Text(d,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    // Delete column header
                    const DataColumn(label: Text("")),
                  ],
                  rows: List.generate(slots.length, (row) {
                    return DataRow(
                      cells: [
                        // Slot name cell
                        DataCell(
                          SizedBox(
                            width: 80,
                            child: Text(
                              slots[row],
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        // Day checkboxes
                        ...List.generate(days.length, (col) {
                          return DataCell(
                            Checkbox(
                              activeColor:
                              const Color(0xff18B6A3),
                              value: schedule[row][col],
                              onChanged: (val) {
                                setState(() {
                                  schedule[row][col] = val!;
                                });
                              },
                            ),
                          );
                        }),
                        // Delete button
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red, size: 20),
                            onPressed: () => _deleteSlot(row),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── SAVE BUTTON ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff18B6A3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Schedule",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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


