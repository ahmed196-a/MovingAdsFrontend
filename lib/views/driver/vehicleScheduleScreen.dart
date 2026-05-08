import 'package:flutter/material.dart';
import '../../models/vehicleSchedule.dart';
import '../../services/vehicleScheduleApiService.dart';

class VehicleScheduleScreen extends StatefulWidget {
  final String vehicleReg;

  const VehicleScheduleScreen({super.key, required this.vehicleReg});

  @override
  State<VehicleScheduleScreen> createState() =>
      _VehicleScheduleScreenState();
}

class _VehicleScheduleScreenState extends State<VehicleScheduleScreen> {
  // ── Default slots ─────────────────────────────────────────
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

  // ── Validate slot name ────────────────────────────────────
  // Accepts:
  //   Single time  : "9 AM", "12 PM"
  //   Range (-)    : "8-10 AM", "12-2 PM"
  //   With minutes : "10:30-11:30 AM", "9:00 PM"
  //   24-h style   : "08:00-10:00", "14:30-16:00"
  // Rejects: plain numbers, random text, empty
  String? _validateSlotName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Slot name is required";
    }

    final v = value.trim();

    // time unit: digits with optional :minutes  → e.g.  8  |  10  |  8:30  |  14:00
    const t = r'\d{1,2}(?::\d{2})?';

    // full pattern: one or two time units separated by optional " - " or "-",
    // optionally followed by AM/PM (case-insensitive)
    final regex = RegExp(
      r'^' + t + r'(?:\s*[-–]\s*' + t + r')?' + r'(?:\s*[AaPp][Mm])?$',
    );

    if (!regex.hasMatch(v)) {
      return "Enter a valid time like  8-10 AM  or  10:30-11:30 AM";
    }

    if (slots.contains(v)) {
      return "This slot already exists";
    }

    return null;
  }

  // ── Add slot ──────────────────────────────────────────────
  void _addSlot() {
    _slotController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add Time Slot"),
        content: Form(
          key: _slotFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter any time range, e.g.:",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                "  8-10 AM  •  10:30-11:30 AM  •  12-2 PM  •  9 PM",
                style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff18B6A3),
                    fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slotController,
                validator: _validateSlotName,
                decoration: InputDecoration(
                  hintText: "e.g. 10:30-11:30 AM",
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
                  schedule.add(List.generate(days.length, (_) => false));
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff18B6A3)),
            child: const Text("Add", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Delete slot ───────────────────────────────────────────
  void _deleteSlot(int row) {
    setState(() {
      slots.removeAt(row);
      schedule.removeAt(row);
    });
  }

  // ── Toggle a single day ───────────────────────────────────
  void _toggleDay(int row, int col) {
    setState(() {
      schedule[row][col] = !schedule[row][col];
    });
  }

  // ── Toggle all days for a slot ────────────────────────────
  void _toggleAllDays(int row) {
    final allSelected = schedule[row].every((v) => v);
    setState(() {
      for (int c = 0; c < days.length; c++) {
        schedule[row][c] = !allSelected;
      }
    });
  }

  String _convertRowToBits(int row) =>
      schedule[row].map((e) => e ? "1" : "0").join();

  Future<void> _saveSchedule() async {
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one slot")),
      );
      return;
    }

    List<VehicleScheduleModel> data = [];
    for (int i = 0; i < slots.length; i++) {
      data.add(VehicleScheduleModel(
        vehReg: widget.vehicleReg,
        slotName: slots[i],
        bits: _convertRowToBits(i),
      ));
    }

    bool success = await VehicleScheduleApiService.saveSchedule(data);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schedule Saved")),
      );
      Navigator.pop(context);
    }
  }

  // ── Day chip ──────────────────────────────────────────────
  Widget _dayChip(int row, int col) {
    final selected = schedule[row][col];
    return GestureDetector(
      onTap: () => _toggleDay(row, col),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff18B6A3) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xff18B6A3) : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          days[col],
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ── Slot card ─────────────────────────────────────────────
  Widget _slotCard(int row) {
    final allSelected = schedule[row].every((v) => v);
    final selectedCount = schedule[row].where((v) => v).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xff18B6A3).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Color(0xff18B6A3)),
                      const SizedBox(width: 5),
                      Text(
                        slots[row],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff18B6A3),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // "All" toggle
                GestureDetector(
                  onTap: () => _toggleAllDays(row),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: allSelected
                          ? const Color(0xff18B6A3).withOpacity(0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: allSelected
                            ? const Color(0xff18B6A3)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      allSelected ? "Clear all" : "All",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: allSelected
                            ? const Color(0xff18B6A3)
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Delete
                GestureDetector(
                  onTap: () => _deleteSlot(row),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 18),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Day chips row ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                days.length,
                    (col) => _dayChip(row, col),
              ),
            ),

            // ── Selection count hint ─────────────────────
            if (selectedCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                "$selectedCount day${selectedCount > 1 ? 's' : ''} selected",
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff18B6A3),
                    fontWeight: FontWeight.w500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Vehicle Schedule"),
        backgroundColor: const Color(0xff18B6A3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Time Slot",
            onPressed: _addSlot,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── INFO BANNER ───────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xff18B6A3).withOpacity(0.35)),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline,
                    size: 16, color: Color(0xff18B6A3)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Tap the day buttons to toggle. Tap + in the toolbar to add a custom slot.",
                    style:
                    TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),

          // ── SLOT CARDS LIST ───────────────────────────
          Expanded(
            child: slots.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule,
                      size: 48, color: Colors.black12),
                  SizedBox(height: 12),
                  Text(
                    "No slots yet.\nTap + to add one.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black38),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: slots.length,
              itemBuilder: (_, row) => _slotCard(row),
            ),
          ),

          // ── SAVE BUTTON ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
        ],
      ),
    );
  }
}