import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:itcs444project/InsuranceStatus.dart';
import 'package:itcs444project/TrackInsurancePage.dart';


class SubmitInsuranceRequestPage extends StatefulWidget {
  final String vehicleId;

  const SubmitInsuranceRequestPage({
    Key? key,
    required this.vehicleId,
  }) : super(key: key);

  @override
  State<SubmitInsuranceRequestPage> createState() => _SubmitInsuranceRequestPageState();
}

class _SubmitInsuranceRequestPageState extends State<SubmitInsuranceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _estimatedValueController = TextEditingController();
  bool _isLoading = true;
  bool _hasAccident = false;
  bool _wasInsuredBefore = false;
  double _originalPrice = 0;
  int _manufacturingYear = 0;
  double _calculatedValue = 0;
  String _registrationNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVehicleDetails();
  }

  double _calculateDepreciation(double originalPrice, int year) {
    final currentYear = DateTime.now().year;
    final age = currentYear - year;
    double depreciated = originalPrice;
    
    for (int i = 0; i < age; i++) {
      depreciated *= 0.9; // 10% depreciation per year
    }
    
    return double.parse(depreciated.toStringAsFixed(2));
  }

  Future<void> _loadVehicleDetails() async {
    try {
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        throw 'Vehicle not found';
      }

      final data = vehicleDoc.data() as Map<String, dynamic>;
      
      setState(() {
        // Use the correct field name
        _originalPrice = data['originalPrice']?.toDouble() ?? 0.0;
        _manufacturingYear = data['manufacturingYear'] ?? 0;
        _hasAccident = data['hasAccident'] ?? false;
        _registrationNumber = data['registrationNumber'] ?? '';
        
        _calculatedValue = _calculateDepreciation(_originalPrice, _manufacturingYear);
        _estimatedValueController.text = _calculatedValue.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicle details: $e')),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final estimatedValue = double.parse(_estimatedValueController.text);
      
      // Create initial insurance request
      final requestDoc = await FirebaseFirestore.instance
          .collection('insuranceRequests')
          .add({
        'vehicleId': widget.vehicleId,
        'customerId': FirebaseAuth.instance.currentUser!.uid,
        'registrationNumber': _registrationNumber,
        'requestType': _wasInsuredBefore ? 'Renewal' : 'New',
        'originalPrice': _originalPrice,
        'manufacturingYear': _manufacturingYear,
        'calculatedValue': _calculatedValue,
        'estimatedValue': estimatedValue,
        'hasAccident': _hasAccident,
        'status': InsuranceStatus.requestSubmitted.name,
        'progress': InsuranceStatus.requestSubmitted.progressMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update vehicle status with correct enum value
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .update({
        'insuranceStatus': InsuranceStatus.requestSubmitted.name,
        'currentInsuranceRequest': requestDoc.id,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrackInsurancePage(requestId: requestDoc.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_wasInsuredBefore ? 'Renew Insurance' : 'New Insurance Request'),
        backgroundColor: Colors.red,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Details',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text('Registration: $_registrationNumber'),
                      Text('Original Price: \$${_originalPrice.toStringAsFixed(2)}'),
                      Text('Manufacturing Year: $_manufacturingYear'),
                      Text('Accident History: ${_hasAccident ? 'Yes' : 'No'}'),
                      Text('Insurance Type: ${_wasInsuredBefore ? 'Renewal' : 'New'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculated Value',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Auto-calculated value: \$${_calculatedValue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _estimatedValueController,
                        decoration: const InputDecoration(
                          labelText: 'Estimated Current Value',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an estimated value';
                          }
                          final estimated = double.tryParse(value);
                          if (estimated == null) {
                            return 'Please enter a valid number';
                          }
                          final minValue = _calculatedValue * 0.8;
                          final maxValue = _calculatedValue * 1.2;
                          if (estimated < minValue || estimated > maxValue) {
                            return 'Value must be within ±20% of calculated value';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Allowed range: \$${(_calculatedValue * 0.8).toStringAsFixed(2)} - \$${(_calculatedValue * 1.2).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Submit Insurance Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _estimatedValueController.dispose();
    super.dispose();
  }
}