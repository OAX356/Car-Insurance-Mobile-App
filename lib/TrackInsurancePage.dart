import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Assuming used elsewhere, not directly in this snippet for the issue
import 'dart:async';

import 'package:itcs444project/InsuranceStatus.dart'; // Ensure this enum is correctly defined
import 'package:itcs444project/InsuranceSelectionPage.dart';

class TrackInsurancePage extends StatefulWidget {
  final String requestId;

  const TrackInsurancePage({super.key, required this.requestId});

  @override
  State<TrackInsurancePage> createState() => _TrackInsurancePageState();
}

class _TrackInsurancePageState extends State<TrackInsurancePage> {
  final StreamController<DocumentSnapshot> _requestController =
      StreamController<DocumentSnapshot>.broadcast();
  String? _status;
  String? _progress; // This variable is set but not explicitly used in the provided build logic for UI.
  double? _insuranceAmount;
  bool _isPaying = false;
  Timestamp? _expirationDate;

  @override
  void initState() {
    super.initState();
    _setupRequestStream();
    // Consider calling _verifyIndexes() here if it's important for setup,
    // though ensure it uses the correct collection name.
  }

  void _setupRequestStream() {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('insuranceRequests') // CORRECTED (was already correct here)
          .doc(widget.requestId);

      // Initial check (optional, as stream will handle non-existence)
      docRef.get().then((doc) {
        if (!doc.exists) {
          print('Initial check: Request document ${widget.requestId} not found.');
          // Stream will also reflect this, no need to throw if stream handles it.
        }
      }).catchError((error) {
        print('Error during initial document check: $error');
      });

      // Set up the stream
      final stream = docRef.snapshots();
      stream.listen(
        (documentSnapshot) { // Renamed from snapshot to documentSnapshot for clarity
          if (!_requestController.isClosed) {
            _requestController.add(documentSnapshot); // MODIFIED: Add snapshot regardless of existence
            if (documentSnapshot.exists && mounted) {
              final data = documentSnapshot.data() as Map<String, dynamic>?;
              setState(() {
                _status = data?['status'];
                _progress = data?['progress'];
                _insuranceAmount = data?['insuranceAmount']?.toDouble();
                _expirationDate = data?['expirationDate'];
              });
            } else if (!documentSnapshot.exists && mounted) {
              // Optionally clear state if document no longer exists
              setState(() {
                _status = null;
                _progress = null;
                _insuranceAmount = null;
                _expirationDate = null;
              });
            }
          }
        },
        onError: (error) {
          print('Stream error: $error');
          if (!_requestController.isClosed) {
            _requestController.addError(error); // MODIFIED: Propagate error to StreamBuilder
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading request details: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('Setup error: $e');
       if (mounted && !_requestController.isClosed) {
        _requestController.addError(e); // Ensure setup errors also go to stream if possible
      }
    }
  }

  Future<void> _simulatePayment() async {
    // This function was not directly tied to the main problem, but corrected for consistency
    try {
      setState(() => _isPaying = true);
      
      await Future.delayed(const Duration(seconds: 2));
      
      final batch = FirebaseFirestore.instance.batch();
      // CORRECTED: collection name to 'insuranceRequests'
      final requestRef = FirebaseFirestore.instance.collection('insuranceRequests').doc(widget.requestId);
      final requestDoc = await requestRef.get();
      
      if (!requestDoc.exists) {
        throw 'Request not found';
      }

      final vehicleId = requestDoc.data()?['vehicleId'];
      if (vehicleId == null) {
        throw 'Vehicle ID not found in request';
      }
      final vehicleRef = FirebaseFirestore.instance.collection('vehicles').doc(vehicleId);

      batch.update(requestRef, {
        'status': 'Payment Pending Approval', // Consider using InsuranceStatus enum here
        'progress': 'Waiting for Admin Approval of Payment',
        'paymentTimestamp': FieldValue.serverTimestamp(),
      });

      batch.update(vehicleRef, {
        'insuranceStatus': 'Payment Pending Approval' // Consider using InsuranceStatus enum here
      });

      await batch.commit();

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment submitted successfully (simulated)')),
        );
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    } finally {
      if(mounted){
        setState(() => _isPaying = false);
      }
    }
  }

  Future<void> _submitPayment() async {
    setState(() => _isPaying = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final requestRef = FirebaseFirestore.instance
          .collection('insuranceRequests') // Already correct
          .doc(widget.requestId);
      
      final request = await requestRef.get();
      if (!request.exists) {
        throw Exception("Request document not found.");
      }
      final vehicleId = request.data()?['vehicleId'];
      if (vehicleId == null) {
        throw Exception("Vehicle ID not found in request.");
      }

      batch.update(requestRef, {
        'status': InsuranceStatus.paymentSubmitted.name,
        'progress': InsuranceStatus.paymentSubmitted.progressMessage,
        'paymentDate': FieldValue.serverTimestamp(),
      });

      batch.update(
        FirebaseFirestore.instance.collection('vehicles').doc(vehicleId),
        {'insuranceStatus': InsuranceStatus.paymentSubmitted.name},
      );

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Payment submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPaying = false);
      }
    }
  }

  @override
  void dispose() {
    _requestController.close();
    super.dispose();
  }

  Widget _buildActionButton() {
    if (_isPaying) { // Moved this check to the top for clarity
      return const Center(child: CircularProgressIndicator());
    }

    if (_status == null) {
      // If status is null (e.g., document exists but no status field, or document doesn't exist),
      // _buildActionButton might be called before StreamBuilder determined non-existence.
      // Or, if StreamBuilder shows "not found", this part might not be reached.
      // For safety, handle null _status.
      return const SizedBox.shrink(); 
    }

    InsuranceStatus currentStatusEnum;
    try {
      currentStatusEnum = InsuranceStatus.values.byName(_status!);
    } catch (e) {
      print("Error parsing status in _buildActionButton: $_status. Error: $e");
      return Text("Error: Invalid status value ('$_status')"); // Show an error if status is invalid
    }

    switch (currentStatusEnum) {
      case InsuranceStatus.offerGenerated:
        return ElevatedButton(
          onPressed: _navigateToOffers,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('View Insurance Offers'),
        );
      
      case InsuranceStatus.pendingPayment:
        return ElevatedButton(
          onPressed: _submitPayment,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Submit Payment'),
        );
      
      case InsuranceStatus.active:
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Policy Value: ${_insuranceAmount?.toStringAsFixed(2) ?? 'N/A'}'),
                const SizedBox(height: 8),
                Text('Expires: ${_formatDate(_expirationDate)}'),
              ],
            ),
          ),
        );
      
      default:
        // This handles any other statuses defined in your enum that don't have specific actions here.
        return const SizedBox.shrink();
    }
  }

  void _navigateToOffers() async {
    final requestRef = FirebaseFirestore.instance
        .collection('insuranceRequests') // Already correct
        .doc(widget.requestId);
    final requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request details not found.')),
        );
      }
      return;
    }
    final vehicleId = requestDoc.data()?['vehicleId'];

    if (vehicleId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle ID not found for this request.')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InsuranceSelectionPage(
            vehicleId: vehicleId,
            requestId: widget.requestId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Insurance Request'),
        backgroundColor: Colors.red,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _requestController.stream,
        builder: (context, snapshot) {
          // MODIFIED: More robust loading, error, and data existence checks
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("StreamBuilder error: ${snapshot.error}");
            // You might want to check for specific errors here, like the index error.
            if (snapshot.error.toString().contains('indexes?create_composite=')) {
                // Call showIndexError or display a specific message.
                // For simplicity here, just a text message.
                // Ensure showIndexError is callable or its logic is integrated here.
                // WidgetsBinding.instance.addPostFrameCallback((_) => showIndexError(snapshot.error.toString()));
                return const Center(child: Text('A database index is required. Please check logs or contact support.'));
            }
            return Center(child: Text('Error loading insurance details: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Insurance request not found.'));
          }
          
          // At this point, snapshot.hasData is true and snapshot.data.exists is true
          final documentData = snapshot.data!.data() as Map<String, dynamic>;
          
          // Validate and parse status from the current snapshot's data
          final statusString = documentData['status'] as String?;
          if (statusString == null) {
            return const Center(child: Text('Request data is incomplete (missing status).'));
          }

          InsuranceStatus currentStatusEnum;
          try {
            currentStatusEnum = InsuranceStatus.values.byName(statusString);
          } catch (e) {
            print("Error parsing status in StreamBuilder: $statusString. Error: $e");
            return Center(child: Text("Error: Invalid status value ('$statusString') received from database."));
          }
          
          // The listener's setState already updated _insuranceAmount and _expirationDate.
          // If _buildStatusTimeline or ListTile used these directly, they would be up-to-date.

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: Icon(Icons.circle,
                        color: currentStatusEnum.statusColor), // Use parsed enum
                    title: Text(currentStatusEnum.displayName), // Use parsed enum
                    subtitle: Text(documentData['progress'] as String? ?? currentStatusEnum.progressMessage), // Use progress from data or enum
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusTimeline(documentData),
                const SizedBox(height: 24),
                _buildActionButton(), // This relies on _status being set by the listener's setState
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusTimeline(Map<String, dynamic> data) {
    // Ensure data is not null and fields are checked before use.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request Timeline',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                if (data['requestDate'] != null)
                  _timelineItem('Request Submitted', data['requestDate'] as Timestamp),
                if (data['offeredAt'] != null)
                  _timelineItem('Offers Generated', data['offeredAt'] as Timestamp),
                if (data['offerAcceptedAt'] != null)
                  _timelineItem('Offer Selected', data['offerAcceptedAt'] as Timestamp),
                if (data['approvalDate'] != null)
                  _timelineItem('Offer Approved', data['approvalDate'] as Timestamp),
                if (data['paymentDate'] != null)
                  _timelineItem('Payment Submitted', data['paymentDate'] as Timestamp),
                if (data['activationDate'] != null)
                  _timelineItem('Policy Activated', data['activationDate'] as Timestamp),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(String title, Timestamp timestamp) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          Text(_formatDate(timestamp)),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A'; // Handle null timestamp
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  // Kept showIndexError and _verifyIndexes, but ensure _verifyIndexes uses correct collection name
  void showIndexError(String error) {
    if (mounted && error.contains('indexes?create_composite=')) {
      // Extracting URL logic needs to be robust
      // final indexUrl = error.substring(error.indexOf('http'), error.indexOf('") '));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This query requires a Firestore index.'),
              SizedBox(height: 4),
              Text('Please visit the Firebase Console to create it.',
                  // style: TextStyle(color: Colors.blue[200]), // Consider if theming needed
                  ),
            ],
          ),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Dismiss',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  Future<void> _verifyIndexes() async {
    // This function is for debugging/setup; ensure it's used appropriately.
    try {
      await FirebaseFirestore.instance
          .collection('insuranceRequests') // CORRECTED: collection name
          .where('status', isEqualTo: 'Pending') // Example query
          .orderBy('timestamp', descending: true) // Example field, ensure 'timestamp' exists for this query
          .limit(1)
          .get();
      print("Index verification query successful.");
    } catch (e) {
      if (e.toString().contains('indexes?create_composite=')) {
        print('Index creation needed. Error: ${e.toString()}');
        if (mounted) {
          showIndexError(e.toString());
        }
      } else {
        print("Error during index verification: $e");
      }
    }
  }
}

// Dummy InsuranceStatus enum for compilation if not provided.
// Replace with your actual enum definition.
/*
enum InsuranceStatus {
  offerGenerated('Offer Generated', 'Waiting for user selection', Colors.orange),
  pendingPayment('Pending Payment', 'Waiting for user to submit payment', Colors.blue),
  paymentSubmitted('Payment Submitted', 'Payment is being processed', Colors.purple),
  active('Active', 'Insurance policy is active', Colors.green),
  // Add other statuses as needed
  unknown('Unknown', 'Status is unknown', Colors.grey);


  const InsuranceStatus(this.displayName, this.progressMessage, this.statusColor);
  final String displayName;
  final String progressMessage;
  final Color statusColor;

  // Add a 'name' getter if you are not using Dart 2.15+ enhanced enums
  // String get name => toString().split('.').last;
}
*/