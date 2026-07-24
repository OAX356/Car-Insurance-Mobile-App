import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:itcs444project/InsuranceStatus.dart';
import 'package:itcs444project/RequestDetailsPage.dart';

class AdminRequestPage extends StatefulWidget {
  const AdminRequestPage({super.key});

  @override
  State<AdminRequestPage> createState() => _AdminRequestPageState();
}

class _AdminRequestPageState extends State<AdminRequestPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Requests'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('insuranceRequests')
            .where('status', isEqualTo: InsuranceStatus.requestSubmitted.name)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: \${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final request = requests[index].data() as Map<String, dynamic>;
              final requestId = requests[index].id;

              return FadeTransition(
                opacity: _animation,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Registration: ${request['registrationNumber']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Estimated Value: \$${request['estimatedValue']}'),
                        Text('Manufacturing Year: ${request['manufacturingYear']}'),
                        Text('Has Accident: ${request['hasAccident'] ? 'Yes' : 'No'}'),
                        Text('Request Type: ${request['requestType']}'),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => _calculateAndOfferInsurance(context, requestId),
                              child: const Text('Review Details'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _calculateAndOfferInsurance(BuildContext context, String requestId) async {
    try {
      final request = await FirebaseFirestore.instance
          .collection('insuranceRequests')
          .doc(requestId)
          .get();

      if (!request.exists) {
        throw 'Request not found';
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RequestDetailsPage(requestId: requestId),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$e')),
      );
    }
  }
}
