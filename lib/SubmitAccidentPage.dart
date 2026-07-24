import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class SubmitAccidentPage extends StatefulWidget {
  final String vehicleId;

  const SubmitAccidentPage({super.key, required this.vehicleId});

  @override
  State<SubmitAccidentPage> createState() => _SubmitAccidentPageState();
}

class _SubmitAccidentPageState extends State<SubmitAccidentPage> {
  final _damagedPartsController = TextEditingController();
  final _repairCostController = TextEditingController(); // Controller for repair cost
  DateTime? _accidentDate;
  bool _isSubmitting = false;

  Future<void> _submitAccident() async {
    if (_accidentDate == null ||
        _damagedPartsController.text.isEmpty ||
        _repairCostController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Parse and validate repair cost
    num? repairCost;
    try {
      // First try to parse the value
      repairCost = num.tryParse(_repairCostController.text.trim());
      
      // Check if parsing was successful and value is valid
      if (repairCost == null || repairCost <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid repair cost greater than 0')),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      // Fetch the vehicle details
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle not found')),
        );
        return;
      }

      // Safely get carValue with null check and type casting
      final data = vehicleDoc.data();
      final carValue = (data != null && data['estimatedCarValue'] != null) 
          ? num.parse(data['estimatedCarValue'].toString()) 
          : 0;
      
      final escalatedRate = repairCost > (0.4 * carValue);

      // Save accident details to Firestore
      await FirebaseFirestore.instance.collection('accidents').add({
        'vehicleId': widget.vehicleId,
        'accidentDate': _accidentDate,
        'damagedParts': _damagedPartsController.text,
        'repairCost': repairCost,
        'escalatedRate': escalatedRate,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the vehicle's depreciation rate if escalated
      if (escalatedRate) {
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId)
            .update({
          'depreciationRate': 0.15,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accident submitted successfully')),
      );
      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Accident'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Accident Date:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final selectedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (selectedDate != null) {
                  setState(() {
                    _accidentDate = selectedDate;
                  });
                }
              },
              child: Text(
                _accidentDate == null
                    ? 'Select Date'
                    : _accidentDate!.toLocal().toString().split(' ')[0],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Damaged Parts:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _damagedPartsController,
              decoration: const InputDecoration(
                hintText: 'Enter damaged parts (comma-separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Repair Cost:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _repairCostController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')), // Allow only numbers and a single decimal point
              ],
              decoration: const InputDecoration(
                hintText: 'Enter repair cost',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitAccident,
                    child: const Text('Submit Accident'),
                  ),
          ],
        ),
      ),
    );
  }
}