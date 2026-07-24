import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:itcs444project/InsuranceStatus.dart';

class RequestDetailsPage extends StatefulWidget {
  final String requestId;

  const RequestDetailsPage({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  bool _isLoading = false;

  Future<void> _processRequest(String action, DocumentSnapshot request) async {
    setState(() => _isLoading = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      
      switch (action) {
        case 'approve_offer':
          batch.update(request.reference, {
            'status': 'pendingPayment',
            'progress': 'Offer Approved - Awaiting Payment',
            'approvalDate': FieldValue.serverTimestamp(),
          });

          batch.update(
            FirebaseFirestore.instance
                .collection('vehicles')
                .doc(request['vehicleId']),
            {'insuranceStatus': InsuranceStatus.pendingPayment.name},
          );
          break;

        case 'approve_payment':
          final expirationDate = DateTime.now().add(const Duration(days: 365));
          
          batch.update(request.reference, {
            'status': 'Active',
            'progress': 'Insurance Active',
            'activationDate': FieldValue.serverTimestamp(),
            'expirationDate': Timestamp.fromDate(expirationDate),
          });

          batch.update(
            FirebaseFirestore.instance
                .collection('vehicles')
                .doc(request['vehicleId']),
            {
              'insuranceStatus': InsuranceStatus.active.name,
              'policyExpirationDate': Timestamp.fromDate(expirationDate),
            },
          );
          break;

        case 'reject':
          batch.update(request.reference, {
            'status': 'Rejected',
            'progress': 'Request Rejected',
            'rejectionDate': FieldValue.serverTimestamp(),
          });

          batch.update(
            FirebaseFirestore.instance
                .collection('vehicles')
                .doc(request['vehicleId']),
            {'insuranceStatus': InsuranceStatus.notInsured.name},
          );
          break;
      }

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request processed successfully')),
      );
      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('insuranceRequests')
                  .doc(widget.requestId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final request = snapshot.data!;
                final data = request.data() as Map<String, dynamic>;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVehicleDetails(data['vehicleId']),
                      const SizedBox(height: 16),
                      _buildInfoCard('Request Details', [
                        'Status: ${data['status']}',
                        'Progress: ${data['progress']}',
                        'Type: ${data['requestType']}',
                        'Submitted: ${DateFormat('MMM dd, yyyy').format((data['timestamp'] as Timestamp).toDate())}',
                        'Has Accident: ${data['hasAccident'] ? 'Yes' : 'No'}',
                        if (data['approvalDate'] != null)
                          'Approved: ${DateFormat('MMM dd, yyyy').format((data['approvalDate'] as Timestamp).toDate())}',
                      ]),
                      const SizedBox(height: 16),
                      _buildInfoCard('Financial Details', [
                        'Original Price: \$${data['originalPrice']}',
                        'Estimated Value: \$${data['estimatedValue']}',
                        if (data['selectedPackage'] != null) ...[
                          'Selected Package: ${data['selectedPackage']}',
                          'Coverage Amount: \$${data['coverage']}',
                          'Premium: \$${data['premium']}',
                        ],
                      ]),
                      const SizedBox(height: 24),
                      _buildActionButtons(request),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildVehicleDetails(String vehicleId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final vehicle = snapshot.data!.data() as Map<String, dynamic>;

        // Use null-safe access and handle missing fields
        final originalPrice = vehicle['originalPrice']?.toString() ?? 'N/A';
        final manufacturingYear = vehicle['manufacturingYear']?.toString() ?? 'N/A';

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
                Text('Registration: ${vehicle['registrationNumber'] ?? 'N/A'}'),
                Text('Original Price: \$$originalPrice'),
                Text('Manufacturing Year: $manufacturingYear'),
                Text('Has Accident: ${vehicle['hasAccident'] == true ? 'Yes' : 'No'}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<String> details) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...details.map((detail) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(detail),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(DocumentSnapshot request) {
    final status = request['status'];
    
    if (status == 'Pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: () => _processRequest('reject', request),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () => _processRequest('approve_offer', request),
            child: const Text('Approve & Request Payment'),
          ),
        ],
      );
    }
    
    if (status == 'PaymentSubmitted') {
      return Center(
        child: ElevatedButton(
          onPressed: () => _processRequest('approve_payment', request),
          child: const Text('Approve Payment & Activate Policy'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}