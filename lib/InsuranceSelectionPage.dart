import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:itcs444project/TrackInsurancePage.dart';
import 'package:itcs444project/InsuranceStatus.dart';

class InsuranceSelectionPage extends StatefulWidget {
  final String vehicleId;
  final String? requestId; // Add requestId parameter

  const InsuranceSelectionPage({
    super.key, 
    required this.vehicleId,
    this.requestId, // Make it optional
  });

  @override
  State<InsuranceSelectionPage> createState() => _InsuranceSelectionPageState();
}

class _InsuranceSelectionPageState extends State<InsuranceSelectionPage> {
  double? carPrice;
  int? manufacturingYear;
  bool? hasAccident;
  bool? wasInsuredBefore;
  double? lastInsuranceValue;
  DateTime? lastInsuranceDate;
  bool _isLoading = true;
  String? _selectedOfferId;
  List<Map<String, dynamic>>? _availableOffers;

  @override
  void initState() {
    super.initState();
    _fetchVehicleAndOffers();
  }

  Future<void> _fetchVehicleAndOffers() async {
    try {
      setState(() => _isLoading = true);

      // First get vehicle details
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(widget.vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        throw 'Vehicle not found';
      }

      final vehicleData = vehicleDoc.data()!;
      
      // Get available offers for this request
      final offersSnapshot = await FirebaseFirestore.instance
          .collection('insuranceOffers')
          .where('requestId', isEqualTo: widget.requestId)
          .where('isActive', isEqualTo: true)
          .get();

      final offers = offersSnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (mounted) {
        setState(() {
          carPrice = vehicleData['originalPrice']?.toDouble();
          manufacturingYear = vehicleData['manufacturingYear'];
          hasAccident = vehicleData['hasAccident'] ?? false;
          _availableOffers = offers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading offers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading offers: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptOffer(Map<String, dynamic> selectedOffer) async {
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();

      // Update request status
      batch.update(
        FirebaseFirestore.instance
            .collection('insuranceRequests')
            .doc(widget.requestId),
        {
          'status': InsuranceStatus.offerAccepted.name,
          'progress': 'Offer Selected - Waiting for Admin Approval',
          'selectedOfferId': selectedOffer['id'],
          'selectedPackage': selectedOffer['type'],
          'coverage': selectedOffer['coverage'],
          'premium': selectedOffer['premium'],
          'offerAcceptedAt': FieldValue.serverTimestamp(),
        },
      );

      // Update vehicle status
      batch.update(
        FirebaseFirestore.instance
            .collection('vehicles')
            .doc(widget.vehicleId),
        {
          'insuranceStatus': InsuranceStatus.offerAccepted.name,
          'currentInsuranceRequest': widget.requestId,
        },
      );

      await batch.commit();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to tracking page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TrackInsurancePage(
            requestId: widget.requestId!,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting offer: $e')),
      );
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
        title: Text(wasInsuredBefore == true ? 'Renew Insurance' : 'New Insurance'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVehicleInfoCard(),
            const SizedBox(height: 24),
            if (_availableOffers == null || _availableOffers!.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No insurance offers available yet. Please wait for admin review.',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Insurance Packages',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  ..._availableOffers!.map((offer) => _buildOfferCard(offer)),
                ],
              ),
            if (_selectedOfferId != null && widget.requestId != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _acceptOffer(
                    _availableOffers!.firstWhere(
                      (offer) => offer['id'] == _selectedOfferId,
                    ),
                  ),
                  child: const Text('Accept Selected Offer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vehicle Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Original Price: \$${carPrice?.toStringAsFixed(2) ?? 'N/A'}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              'Manufacturing Year: $manufacturingYear',
              style: const TextStyle(fontSize: 16),
            ),
            if (wasInsuredBefore == true) ...[
              const SizedBox(height: 8),
              Text(
                'Previous Insurance: \$${lastInsuranceValue?.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Accident History: ${hasAccident == true ? 'Yes' : 'No'}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: RadioListTile<String>(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              offer['type'] ?? 'Unknown Package',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${(offer['premium'] as num).toStringAsFixed(2)}/year',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Coverage: \$${(offer['coverage'] as num).toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Text(offer['description'] ?? ''),
            const SizedBox(height: 8),
            ...List<Widget>.from(
              (offer['features'] as List?)?.map(
                    (feature) => Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Expanded(child: Text(feature.toString())),
                      ],
                    ),
                  ) ??
                  [],
            ),
          ],
        ),
        value: offer['id'],
        groupValue: _selectedOfferId,
        onChanged: (value) {
          setState(() => _selectedOfferId = value);
        },
      ),
    );
  }
}