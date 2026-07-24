import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itcs444project/InsuranceStatus.dart';
import 'package:itcs444project/AdminRequestPage.dart';
import 'package:itcs444project/RegisterVehiclePage.dart';
import 'package:itcs444project/EditVehiclePage.dart';
import 'package:itcs444project/VehicleDetailsPage.dart';
import 'package:itcs444project/SubmitAccidentPage.dart';
import 'package:itcs444project/InsuranceSelectionPage.dart';
import 'package:itcs444project/InsuranceReportPage.dart';
import 'package:itcs444project/TrackInsurancePage.dart';
import 'package:itcs444project/OfferedInsurancePage.dart';
import 'package:itcs444project/SubmitInsuranceRequestPage.dart';
import 'package:itcs444project/InsuranceStatus.dart';
import 'package:itcs444project/RequestDetailsPage.dart';


class VehicleDetailsPage extends StatefulWidget {
  final String vehicleId;
  const VehicleDetailsPage({super.key, required this.vehicleId});

  @override
  _VehicleDetailsPageState createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {
  late Map<String, dynamic> vehicleData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(widget.vehicleId).get();
      if (doc.exists) {
        setState(() {
          vehicleData = doc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vehicle not found')));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(vehicleData['model'] ?? 'Vehicle Details'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (vehicleData['carImageBase64'] != null)
              Image.memory(
                base64Decode(vehicleData['carImageBase64']),
                height: 200,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection('Vehicle Information', [
                    _buildInfoRow('Model', vehicleData['model']),
                    _buildInfoRow('Registration', vehicleData['registrationNumber']),
                    _buildInfoRow('Chassis Number', vehicleData['chassisNumber']),
                    _buildInfoRow('Manufacturing Year', vehicleData['manufacturingYear'].toString()),
                    _buildInfoRow('Passengers', vehicleData['passengers'].toString()),
                    _buildInfoRow('Original Price', '\$${vehicleData['originalPrice']}'),
                  ]),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final insuranceStatus = vehicleData['insuranceStatus'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,  // Changed from stretch
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(  // Added Container for proper constraints
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.start,  // Added alignment
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(  // Wrap each button in SizedBox for consistent width
                width: MediaQuery.of(context).size.width > 600 
                    ? 180  // Wider on larger screens
                    : (MediaQuery.of(context).size.width - 40) / 2,  // 2 buttons per row on smaller screens
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToEdit(),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Vehicle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(0, 44),  // Changed width to 0 to allow flexible width
                    iconColor: Colors.white,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width > 600 
                    ? 180 
                    : (MediaQuery.of(context).size.width - 40) / 2,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAccident(),
                  icon: const Icon(Icons.report_problem),
                  label: const Text('Report Accident'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(0, 44),
                    iconColor: Colors.white,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width > 600 
                    ? 180 
                    : (MediaQuery.of(context).size.width - 40) / 2,
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToReport(),
                  icon: const Icon(Icons.assessment),
                  label: const Text('Insurance History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 176, 39, 64),
                    minimumSize: const Size(0, 44),
                    iconColor: Colors.white,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              if (insuranceStatus == InsuranceStatus.notInsured.name)
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600 
                      ? 180 
                      : (MediaQuery.of(context).size.width - 40) / 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _requestInsurance(),
                    icon: const Icon(Icons.security),
                    label: const Text('Request Insurance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(0, 44),
                      iconColor: Colors.white,
                      foregroundColor: Colors.white,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: MediaQuery.of(context).size.width > 600 
                      ? 180 
                      : (MediaQuery.of(context).size.width - 40) / 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _viewInsurance(),
                    icon: const Icon(Icons.policy),
                    label: const Text('View Insurance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(0, 44),
                      iconColor: Colors.white,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToAccident() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitAccidentPage(vehicleId: widget.vehicleId),
      ),
    );
  }
  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(docId: widget.vehicleId),
      ),
    );
  }
  void _navigateToReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsuranceReportPage(vehicleId: widget.vehicleId),
      ),
    );
  }
  void _requestInsurance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitInsuranceRequestPage(vehicleId: widget.vehicleId),
      ),
    );
  }
  void _viewInsurance() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrackInsurancePage(
          requestId: widget.vehicleId
        ),
      ),
    );
  }
}
