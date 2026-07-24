import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsuranceReportPage extends StatefulWidget {
  final String vehicleId;

  const InsuranceReportPage({super.key, required this.vehicleId});

  @override
  State<InsuranceReportPage> createState() => _InsuranceHistoryPageState();
}

class _InsuranceHistoryPageState extends State<InsuranceReportPage> {
  final _searchYearController = TextEditingController();
  final _searchRegNumberController = TextEditingController();
  List<QueryDocumentSnapshot>? _searchResults;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchInsurancePolicies(); // Load initial data
  }

  Future<void> _searchInsurancePolicies() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance
          .collection('insuranceRequests')
          .where('vehicleId', isEqualTo: widget.vehicleId);

      // Add simple ordering without complex where clauses
      query = query.orderBy('timestamp', descending: true);

      final result = await query.get();
      
      setState(() {
        _searchResults = result.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Search error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return '#4CAF50'; // Green
      case 'expired':
        return '#F44336'; // Red
      case 'pending':
        return '#FFC107'; // Amber
      default:
        return '#9E9E9E'; // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insurance History'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search Filters',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchYearController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchRegNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Registration Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.car_rental),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _searchInsurancePolicies,
                        icon: const Icon(Icons.search),
                        label: const Text('Search'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults == null
                      ? const Center(child: Text('No results yet'))
                      : _searchResults!.isEmpty
                          ? const Center(child: Text('No matching policies found'))
                          : ListView.builder(
                              itemCount: _searchResults!.length,
                              itemBuilder: (context, index) {
                                final policy = _searchResults![index].data() as Map<String, dynamic>;
                                
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ExpansionTile(
                                    title: Text(
                                      'Insurance Package: ${policy['packageType']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Status: ${policy['status']}',
                                      style: TextStyle(
                                        color: Color(
                                          int.parse(
                                            _getStatusColor(policy['status']).replaceAll('#', '0xFF'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Coverage: \$${policy['coverage'].toStringAsFixed(2)}'),
                                            Text('Premium: \$${policy['premium'].toStringAsFixed(2)}'),
                                            Text('Request Type: ${policy['requestType']}'),
                                            Text('Date: ${(policy['timestamp'] as Timestamp).toDate().toString().split(' ')[0]}'),
                                            if (policy['features'] != null) ...[
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Features:',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              ...List<Widget>.from(
                                                (policy['features'] as List).map(
                                                  (feature) => Row(
                                                    children: [
                                                      const Icon(Icons.check, size: 16, color: Colors.green),
                                                      const SizedBox(width: 4),
                                                      Expanded(child: Text(feature)),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchYearController.dispose();
    _searchRegNumberController.dispose();
    super.dispose();
  }
}