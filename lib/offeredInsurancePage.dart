import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsuranceOffer {
  final String id;
  final String vehicleId;
  final double baseAmount;
  final double coverage;
  final List<String> features;
  final String description;
  final String type; // Basic, Standard, Premium
  final bool isActive;

  InsuranceOffer({
    required this.id,
    required this.vehicleId,
    required this.baseAmount,
    required this.coverage,
    required this.features,
    required this.description,
    required this.type,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'baseAmount': baseAmount,
      'coverage': coverage,
      'features': features,
      'description': description,
      'type': type,
      'isActive': isActive,
    };
  }
}

class OfferedInsurancePage extends StatefulWidget {
  final String vehicleId;
  final double carValue;

  const OfferedInsurancePage({
    Key? key,
    required this.vehicleId,
    required this.carValue,
  }) : super(key: key);

  @override
  State<OfferedInsurancePage> createState() => _OfferedInsurancePageState();
}

class _OfferedInsurancePageState extends State<OfferedInsurancePage> {
  bool _isLoading = false;
  List<InsurancePackage> _packages = [];
  InsurancePackage? _selectedPackage;

  @override
  void initState() {
    super.initState();
    _generatePackages();
  }

  void _generatePackages() {
    _packages = [
      InsurancePackage(
        type: 'Basic',
        coverage: widget.carValue * 0.7,
        baseAmount: widget.carValue * 0.05,
        features: [
          'Third-party liability',
          'Basic accident coverage',
          'Emergency roadside assistance',
        ],
        description: 'Essential coverage for basic protection',
      ),
      InsurancePackage(
        type: 'Standard',
        coverage: widget.carValue * 0.85,
        baseAmount: widget.carValue * 0.07,
        features: [
          'All Basic package features',
          'Comprehensive accident coverage',
          'Natural disaster protection',
          'Personal accident coverage',
        ],
        description: 'Balanced protection for most drivers',
      ),
      InsurancePackage(
        type: 'Premium',
        coverage: widget.carValue,
        baseAmount: widget.carValue * 0.09,
        features: [
          'All Standard package features',
          'Full comprehensive coverage',
          'Zero depreciation',
          'Engine protection',
          'Key replacement',
          'Personal belongings coverage',
        ],
        description: 'Maximum protection with exclusive benefits',
      ),
    ];
  }

  Future<void> _saveOffers() async {
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Deactivate existing offers
      final existingOffers = await FirebaseFirestore.instance
          .collection('insuranceOffers')
          .where('vehicleId', isEqualTo: widget.vehicleId)
          .where('isActive', isEqualTo: true)
          .get();

      for (var doc in existingOffers.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      // Create new offers
      for (var package in _packages) {
        final docRef = FirebaseFirestore.instance.collection('insuranceOffers').doc();
        batch.set(docRef, {
          'vehicleId': widget.vehicleId,
          'type': package.type,
          'coverage': package.coverage,
          'baseAmount': package.baseAmount,
          'features': package.features,
          'description': package.description,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insurance offers generated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating offers: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance Packages'),
        backgroundColor: Colors.red,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Car Value: \$${widget.carValue.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  ..._packages.map((package) => _buildPackageCard(package)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _saveOffers,
                      child: const Text('Generate Insurance Offers'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPackageCard(InsurancePackage package) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  package.type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${package.baseAmount.toStringAsFixed(2)}/year',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Coverage: \$${package.coverage.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text(package.description),
            const Divider(),
            const Text(
              'Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...package.features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InsurancePackage {
  final String type;
  final double coverage;
  final double baseAmount;
  final List<String> features;
  final String description;

  InsurancePackage({
    required this.type,
    required this.coverage,
    required this.baseAmount,
    required this.features,
    required this.description,
  });
}

// Add this method in the _administratorPageState class
Future<void> _createInsuranceOffers(String vehicleId, double carValue) async {
  final offers = [
    {
      'type': 'Basic',
      'coverage': carValue * 0.7,
      'baseAmount': carValue * 0.05,
      'features': [
        'Third-party liability',
        'Basic accident coverage',
        'Emergency roadside assistance'
      ],
      'description': 'Essential coverage for basic protection'
    },
    {
      'type': 'Standard',
      'coverage': carValue * 0.85,
      'baseAmount': carValue * 0.07,
      'features': [
        'All Basic package features',
        'Comprehensive accident coverage',
        'Natural disaster protection',
        'Personal accident coverage'
      ],
      'description': 'Balanced protection for most drivers'
    },
    {
      'type': 'Premium',
      'coverage': carValue,
      'baseAmount': carValue * 0.09,
      'features': [
        'All Standard package features',
        'Full comprehensive coverage',
        'Zero depreciation',
        'Engine protection',
        'Key replacement',
        'Personal belongings coverage'
      ],
      'description': 'Maximum protection with exclusive benefits'
    }
  ];

  final batch = FirebaseFirestore.instance.batch();

  // Delete existing active offers for this vehicle
  final existingOffers = await FirebaseFirestore.instance
      .collection('insuranceOffers')
      .where('vehicleId', isEqualTo: vehicleId)
      .where('isActive', isEqualTo: true)
      .get();

  for (var doc in existingOffers.docs) {
    batch.update(doc.reference, {'isActive': false});
  }

  // Create new offers
  for (var offer in offers) {
    final docRef = FirebaseFirestore.instance.collection('insuranceOffers').doc();
    batch.set(docRef, {
      ...offer,
      'vehicleId': vehicleId,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}

// Add this method to handle insurance request reviews
Widget _buildInsuranceRequestCard(DocumentSnapshot request) {
  return Card(
    margin: const EdgeInsets.all(8.0),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vehicle ID: ${request['vehicleId']}'),
          const SizedBox(height: 8),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('vehicles')
                .doc(request['vehicleId'])
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final vehicle = snapshot.data!;
              final data = vehicle.data() as Map<String, dynamic>?;
              
              if (data == null) {
                return const Text('Vehicle data not found');
              }

              final carValue = data['carPriceWhenNew'] as num?;
              
              if (carValue == null) {
                return const Text('Vehicle price information not available');
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Car Value: \$${carValue.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _createInsuranceOffers(
                      request['vehicleId'],
                      carValue.toDouble(),
                    ),
                    child: const Text('Generate Insurance Offers'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}