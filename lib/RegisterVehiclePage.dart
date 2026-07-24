import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:itcs444project/insuranceStatus.dart';

class RegisterVehiclePage extends StatefulWidget {
  const RegisterVehiclePage({super.key});

  @override
  State<RegisterVehiclePage> createState() => _RegisterVehiclePageState();
}

class _RegisterVehiclePageState extends State<RegisterVehiclePage> {
  final TextEditingController _customerName = TextEditingController();
  final TextEditingController _carModel = TextEditingController();
  final TextEditingController _chassisNumber = TextEditingController();
  final TextEditingController _registrationNumber = TextEditingController();
  final TextEditingController _manufacturingYear = TextEditingController();
  final TextEditingController _passengers = TextEditingController();
  final TextEditingController _driverAge = TextEditingController();
  final TextEditingController _price = TextEditingController();
  bool _hasAccident = false;

  String _savedCustomerName = '';
  String _savedCarModel = '';
  String _savedChassisNumber = '';
  String _savedRegistrationNumber = '';
  int _savedManufacturingYear = 0;
  int _savedPassengers = 0;
  int _savedDriverAge = 0;
  double _savedCarPrice = 0.0;

  String? _chassisNumberError;
  String? _registrationNumberError;

  String? _base64Image;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  double calculateDepreciatedValue(double price, int year) {
    int age = DateTime.now().year - year;
    for (int i = 0; i < age; i++) {
      price *= 0.9;
    }
    return double.parse(price.toStringAsFixed(2));
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final allowedExtensions = ['jpg', 'jpeg', 'png'];
      final extension = pickedFile.name.split('.').last.toLowerCase();

      if (!allowedExtensions.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid image type. Only JPG, JPEG, PNG allowed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _base64Image = base64Encode(bytes);
      });
    }
  }

  String _generateVehicleId(String registrationNumber, String chassisNumber) {
    final chassisLast4 = chassisNumber.substring(math.max(0, chassisNumber.length - 4));
    return '${registrationNumber.replaceAll(" ", "")}_$chassisLast4';
  }

  void _submitRegisterVehicleForm() async {
    _chassisNumberError = null;
    _registrationNumberError = null;

    final chassisCheck = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('chassisNumber', isEqualTo: _chassisNumber.text.trim())
        .get();

    if (chassisCheck.docs.isNotEmpty) {
      setState(() {
        _chassisNumberError = 'Chassis number already exists';
      });
    }

    final regCheck = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('registrationNumber', isEqualTo: _registrationNumber.text.trim())
        .get();

    if (regCheck.docs.isNotEmpty) {
      setState(() {
        _registrationNumberError = 'Registration number already exists';
      });
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_chassisNumberError != null || _registrationNumberError != null) {
        return;
      }

      if (_base64Image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a vehicle image'), backgroundColor: Colors.red),
        );
        return;
      }

      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        
        // Generate vehicle ID
        final vehicleId = _generateVehicleId(_savedRegistrationNumber, _savedChassisNumber);

        // Check if vehicleId already exists
        final vehicleCheck = await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(vehicleId)
            .get();

        if (vehicleCheck.exists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vehicle ID already exists'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Use the generated ID as the document ID
        await FirebaseFirestore.instance.collection('vehicles').doc(vehicleId).set({
          'vehicleId': vehicleId,
          'ownerId': userId,
          'customerName': _savedCustomerName,
          'model': _savedCarModel,
          'chassisNumber': _savedChassisNumber,
          'registrationNumber': _savedRegistrationNumber,
          'manufacturingYear': _savedManufacturingYear,
          'passengers': _savedPassengers,
          'driverAge': _savedDriverAge,
          'originalPrice': _savedCarPrice,
          'hasAccident': _hasAccident,
          'carImageBase64': _base64Image,
          'insuranceStatus': InsuranceStatus.notInsured.name,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle Registered Successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Vehicle'), backgroundColor: Colors.amber),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _customerName,
                decoration: const InputDecoration(icon: Icon(Icons.person), border: OutlineInputBorder(), labelText: "Customer Name"),
                validator: (value) => value == null || value.trim().isEmpty ? 'Customer name is required' : null,
                onSaved: (value) => _savedCustomerName = value!.trim(),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _carModel,
                decoration: const InputDecoration(icon: Icon(Icons.directions_car), border: OutlineInputBorder(), labelText: "Car Model"),
                validator: (value) => value == null || value.trim().isEmpty ? 'Car model is required' : null,
                onSaved: (value) => _savedCarModel = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chassisNumber,
                decoration: InputDecoration(icon: Icon(Icons.confirmation_number), border: OutlineInputBorder(), labelText: "Chassis Number", errorText: _chassisNumberError),
                validator: (value) => value == null || value.trim().isEmpty ? 'Chassis number is required' : null,
                onSaved: (value) => _savedChassisNumber = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _registrationNumber,
                decoration: InputDecoration(icon: Icon(Icons.assignment), border: OutlineInputBorder(), labelText: "Registration Number", errorText: _registrationNumberError),
                validator: (value) => value == null || value.trim().isEmpty ? 'Registration number is required' : null,
                onSaved: (value) => _savedRegistrationNumber = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturingYear,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(icon: Icon(Icons.calendar_today), border: OutlineInputBorder(), labelText: "Manufacturing Year"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Manufacturing year is required';
                  final year = int.tryParse(value);
                  if (year == null || year < 1900 || year > DateTime.now().year) return 'Enter a valid year';
                  final price = double.tryParse(_price.text);
                  return null;
                },
                onSaved: (value) => _savedManufacturingYear = int.tryParse(value!)!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passengers,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(icon: Icon(Icons.group), border: OutlineInputBorder(), labelText: "Number of Passengers"),
                validator: (value) {
                  final v = int.tryParse(value ?? '');
                  return (v == null || v < 1 || v > 20) ? 'Enter a valid number of passengers (1-20)' : null;
                },
                onSaved: (value) => _savedPassengers = int.tryParse(value!)!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _driverAge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(icon: Icon(Icons.person_outline), border: OutlineInputBorder(), labelText: "Driver's Age"),
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  return (age == null || age < 18 || age > 120) ? 'Must be 18 or older and less than 120' : null;
                },
                onSaved: (value) => _savedDriverAge = int.tryParse(value!)!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(icon: Icon(Icons.attach_money), border: OutlineInputBorder(), labelText: "Car Price When New"),
                validator: (value) {
                  final price = double.tryParse(value ?? '');
                  return (price == null || price < 100) ? 'Enter a price of at least 100' : null;
                },
                onSaved: (value) => _savedCarPrice = double.tryParse(value!)!,
              ),
              const SizedBox(height: 12),
            
              SwitchListTile(
                title: const Text("Has the car had an accident?"),
                value: _hasAccident,
                onChanged: (val) => setState(() => _hasAccident = val),
              ),
              const SizedBox(height: 20),
              _base64Image == null ? const Text("No image selected") : Image.memory(base64Decode(_base64Image!), height: 200),
              TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.photo), label: const Text("Select Vehicle Image")),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitRegisterVehicleForm, child: const Text('Submit')),
            ],
          ),
        ),
      ),
    );
  }
}
