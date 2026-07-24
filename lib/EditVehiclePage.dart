import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';

class EditVehiclePage extends StatefulWidget {
  final String docId;
  const EditVehiclePage({super.key, required this.docId});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _carModel = TextEditingController();
  final TextEditingController _chassisNumber = TextEditingController();
  final TextEditingController _registrationNumber = TextEditingController();
  final TextEditingController _manufacturingYear = TextEditingController();
  final TextEditingController _passengers = TextEditingController();
  final TextEditingController _driverAge = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _estimatedValue = TextEditingController();
  String _selectedInsuranceType = 'New Insurance';
  bool _hasAccident = false;
  String? _base64Image;
  bool _loading = true;
  String? _chassisNumberError;
  String? _registrationNumberError;

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('vehicles').doc(widget.docId).get();
      final data = doc.data();
      if (data != null) {
        _customerName.text = data['customerName'];
        _carModel.text = data['model'];
        _chassisNumber.text = data['chassisNumber'];
        _registrationNumber.text = data['registrationNumber'];
        _manufacturingYear.text = data['manufacturingYear'].toString();
        _passengers.text = data['passengers'].toString();
        _driverAge.text = data['driverAge'].toString();
        _price.text = data['carPriceWhenNew'].toString();
        _estimatedValue.text = data['estimatedCarValue'].toString();
        _hasAccident = data['hasAccident'];
        _base64Image = data['carImageBase64'];
        _selectedInsuranceType = data['insuranceType'] ?? 'New Insurance';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error fetching vehicle data: $e"), backgroundColor: Colors.red));
    }
    setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final allowedExtensions = ['jpg', 'jpeg', 'png'];
      final extension = picked.name.split('.').last.toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid image type. Only JPG, JPEG, PNG allowed.'), backgroundColor: Colors.red),
        );
        return;
      }
      final bytes = await picked.readAsBytes();
      setState(() => _base64Image = base64Encode(bytes));
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _chassisNumberError = null;
      _registrationNumberError = null;
    });

    if (_formKey.currentState!.validate()) {
      final chassisNumber = _chassisNumber.text.trim();
      final registrationNumber = _registrationNumber.text.trim();

      final chassisQuery = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('chassisNumber', isEqualTo: chassisNumber)
          .get();

      final regQuery = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('registrationNumber', isEqualTo: registrationNumber)
          .get();

      final isChassisDuplicate = chassisQuery.docs.any((doc) => doc.id != widget.docId);
      final isRegDuplicate = regQuery.docs.any((doc) => doc.id != widget.docId);

      bool hasError = false;

      if (isChassisDuplicate) {
        setState(() => _chassisNumberError = "This chassis number already exists.");
        hasError = true;
      }
      if (isRegDuplicate) {
        setState(() => _registrationNumberError = "This registration number already exists.");
        hasError = true;
      }
      if (hasError) return;

      try {
        await FirebaseFirestore.instance.collection('vehicles').doc(widget.docId).update({
          'customerName': _customerName.text.trim(),
          'model': _carModel.text.trim(),
          'chassisNumber': chassisNumber,
          'registrationNumber': registrationNumber,
          'manufacturingYear': int.tryParse(_manufacturingYear.text),
          'passengers': int.tryParse(_passengers.text),
          'driverAge': int.tryParse(_driverAge.text),
          'carPriceWhenNew': double.tryParse(_price.text),
          'estimatedCarValue': double.tryParse(_estimatedValue.text),
          'insuranceType': _selectedInsuranceType,
          'hasAccident': _hasAccident,
          'carImageBase64': _base64Image,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vehicle info updated successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating vehicle: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Vehicle"), backgroundColor: Colors.amber),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(controller: _customerName, decoration: const InputDecoration(icon: Icon(Icons.person), border: OutlineInputBorder(), labelText: "Customer Name"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _carModel, decoration: const InputDecoration(icon: Icon(Icons.directions_car), border: OutlineInputBorder(), labelText: "Car Model"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _chassisNumber, decoration: InputDecoration(icon: const Icon(Icons.confirmation_number), border: const OutlineInputBorder(), labelText: "Chassis Number", errorText: _chassisNumberError), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _registrationNumber, decoration: InputDecoration(icon: const Icon(Icons.assignment), border: const OutlineInputBorder(), labelText: "Registration Number", errorText: _registrationNumberError), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _manufacturingYear, keyboardType: TextInputType.number, decoration: const InputDecoration(icon: Icon(Icons.calendar_today), border: OutlineInputBorder(), labelText: "Manufacturing Year"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _passengers, keyboardType: TextInputType.number, decoration: const InputDecoration(icon: Icon(Icons.group), border: OutlineInputBorder(), labelText: "Number of Passengers"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _driverAge, keyboardType: TextInputType.number, decoration: const InputDecoration(icon: Icon(Icons.person_outline), border: OutlineInputBorder(), labelText: "Driver's Age"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(icon: Icon(Icons.attach_money), border: OutlineInputBorder(), labelText: "Car Price When New"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    TextFormField(controller: _estimatedValue, keyboardType: TextInputType.number, decoration: const InputDecoration(icon: Icon(Icons.money), border: OutlineInputBorder(), labelText: "Estimated Value"), validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedInsuranceType,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: "Insurance Type"),
                      items: ['New Insurance', 'Renewal'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (val) => setState(() => _selectedInsuranceType = val!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(title: const Text("Has the car had an accident?"), value: _hasAccident, onChanged: (val) => setState(() => _hasAccident = val)),
                    const SizedBox(height: 20),
                    _base64Image == null ? const Text("No image selected") : Image.memory(base64Decode(_base64Image!), height: 200),
                    TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text("Select Vehicle Image")),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _submitForm, child: const Text('Submit')),
                  ],
                ),
              ),
            ),
    );
  }
}
