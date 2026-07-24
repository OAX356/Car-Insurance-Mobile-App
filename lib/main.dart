import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

// Pages imports
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "",
      authDomain: "",
      projectId: "",
      storageBucket: "p",
      messagingSenderId: "",
      appId: "",
      measurementId: ""
    ),
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Insurance Management',
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: Colors.grey[100], // Light background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2, // Subtle elevation
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.red.shade700, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.red.shade700),
        ),
        chipTheme: ChipThemeData(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        )
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final role = userSnapshot.data?['role'];
                if (role == 'administrator') {
                  return const AdministratorPage();
                } else {
                  return const CustomerPage();
                }
              },
            );
          }
          
          return const LoginPage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Rename classes to follow Dart naming conventions
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Insurance Login'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();

      if (!mounted) return;

      final role = userDoc.data()?['role'];

      if (role == 'administrator') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AdministratorPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CustomerPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// page for signup
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                  'Join Us!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                ),
            SizedBox(height: 20,),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
            ),
            SizedBox(height: 20,),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  final userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  );
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userCredential.user?.uid)
                      .set({
                    'email': _emailController.text,
                    'role': 'customer',
                  });
                  // message to inform user about successful signup
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign Up successful')),
                  );
                  // Navigate to home page after successful signup
                  Navigator.pop(context);
                } catch (e) {
                  // Handle error
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign Up failed : must write valid email and at least 6 password characters')),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}

// page for customer
class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Home'),
        backgroundColor: Colors.red,
        actions: [
          
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Navigate to login page after logout
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false, // Remove all routes until none are left
              );
            },
          ),
          
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Model or Reg.. number',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registered Vehicles',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterVehiclePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    elevation: 5,
                  ),
                  child: const Text('Register Vehicle'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicles')
                  .where('ownerId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading vehicles'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final vehicles = snapshot.data!.docs.where((doc) {
                  final model = doc['model'].toString().toLowerCase();
                  final reg =
                      doc['registrationNumber'].toString().toLowerCase();
                  return model.contains(_searchQuery) ||
                      reg.contains(_searchQuery);
                }).toList();

                if (vehicles.isEmpty) {
                  return const Center(child: Text('No vehicles found'));
                }

                return _isGridView
                    ? GridView.builder(
                        itemCount: vehicles.length,
                        padding: const EdgeInsets.all(10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
                          final base64Image = vehicle['carImageBase64'];

                          return Card(
                            elevation: 3,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehicleDetailsPage(vehicleId: vehicle.id),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Vehicle Image
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: MemoryImage(base64Decode(base64Image)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Vehicle Info
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                vehicle['model'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                "Reg #: ${vehicle['registrationNumber']}",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          _buildStatusChip(vehicle['insuranceStatus']),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount: vehicles.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
                          final base64Image = vehicle['carImageBase64'];

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VehicleDetailsPage(vehicleId: vehicle.id),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    // Vehicle Image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        base64Decode(base64Image),
                                        fit: BoxFit.cover,
                                        width: 80,
                                        height: 80,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Vehicle Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vehicle['model'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Reg #: ${vehicle['registrationNumber']}",
                                            style: TextStyle(color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildStatusChip(vehicle['insuranceStatus']),
                                        ],
                                      ),
                                    ),
                                    // Action Buttons
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (vehicle['insuranceStatus'] == InsuranceStatus.notInsured.name)
                                          ElevatedButton(
                                            onPressed: () => _submitInsuranceRequest(vehicle.id),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              minimumSize: const Size(0, 36),
                                            ),
                                            child: const Text(
                                              'Request Insurance',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          )
                                        else
                                          IconButton(
                                            icon: const Icon(Icons.security),
                                            onPressed: () => _viewInsuranceDetails(vehicle.id),
                                            tooltip: 'View Insurance Status',
                                          ),
                                        PopupMenuButton(
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              child: const Text('Edit'),
                                              onTap: () => _navigateToEdit(vehicle.id),
                                            ),
                                            PopupMenuItem(
                                              child: const Text('Report Accident'),
                                              onTap: () => _navigateToAccident(vehicle.id),
                                            ),
                                            PopupMenuItem(
                                              child: const Text('Insurance History'),
                                              onTap: () => _navigateToReport(vehicle.id),
                                            ),
                                          ],
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
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(String vehicleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(docId: vehicleId),
      ),
    );
  }

  void _navigateToAccident(String vehicleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubmitAccidentPage(vehicleId: vehicleId),
      ),
    );
  }

  void _navigateToReport(String vehicleId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsuranceReportPage(vehicleId: vehicleId),
      ),
    );
  }

  Future<void> _submitInsuranceRequest(String vehicleId) async {
    try {
      // First check if vehicle exists and get its details
      final vehicleDoc = await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .get();

      if (!vehicleDoc.exists) {
        throw 'Vehicle not found';
      }

      if (!mounted) return;

      // Navigate to the SubmitInsuranceRequestPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmitInsuranceRequestPage(
            vehicleId: vehicleId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _viewInsuranceDetails(String vehicleId) async {
    final vehicleDoc = await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(vehicleId)
        .get();
        
    if (!mounted) return;

    final request = vehicleDoc.data()?['currentInsuranceRequest'];
    if (request != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TrackInsurancePage(requestId: request),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active insurance request found')),
      );
    }
  }

 
  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'notInsured':
        color = Colors.grey;
        label = 'Not Insured';
        break;
      case 'requestSubmitted':
        color = Colors.orange;
        label = 'Request Submitted';
        break;
      case 'offerGenerated':
        color = Colors.blue;
        label = 'Offer Generated';
        break;
      case 'offerAccepted':
        color = Colors.purple;
        label = 'Offer Accepted';
        break;
      case 'pendingPayment':
        color = Colors.amber;
        label = 'Pending Payment';
        break;
      case 'active':
        color = Colors.green;
        label = 'Active';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}

// page for administrator
class AdministratorPage extends StatefulWidget {
  const AdministratorPage({super.key});

  @override
  State<AdministratorPage> createState() => _AdministratorPageState();
}

class _AdministratorPageState extends State<AdministratorPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrator Dashboard'),
        backgroundColor: Colors.orange,
        actions: [
          _buildNotificationBadge(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPendingRequestsSection(),
              const Divider(height: 32),
              _buildInsuranceRequestsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('insuranceRequests')
          .where('status', isEqualTo: InsuranceStatus.requestSubmitted.name) // Changed from 'Pending'
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        return Badge(
          label: Text('${snapshot.data!.docs.length}'),
          child: IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => _showPendingRequests(),
          ),
        );
      },
    );
  }

  Widget _buildPendingRequestsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('insuranceRequests')
          .where('status', isEqualTo: InsuranceStatus.requestSubmitted.name) // Changed from 'Pending'
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error loading requests');
        }

        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final requests = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Insurance Requests (${requests.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) => _buildRequestCard(requests[index]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestCard(DocumentSnapshot request) {
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
                _buildRequestHeader(request),
                Chip(
                  label: Text(request['status']),
                  backgroundColor: _getStatusColor(request['status']),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildRequestDetails(request),
            const SizedBox(height: 16),
            _buildActionButtons(request),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'requestSubmitted':
        return Colors.orange.shade100;
      case 'offerAccepted':
        return Colors.blue.shade100;
      case 'paymentSubmitted':
        return Colors.purple.shade100;
      case 'active':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Widget _buildRequestHeader(DocumentSnapshot request) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('vehicles')
          .doc(request['vehicleId'])
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final vehicle = snapshot.data!.data() as Map<String, dynamic>;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vehicle: ${vehicle['model']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Reg #: ${vehicle['registrationNumber']}'),
              ],
            ),
            Chip(
              label: Text(request['requestType']),
              backgroundColor: request['requestType'] == 'New' 
                  ? Colors.blue.shade100 
                  : Colors.green.shade100,
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestDetails(DocumentSnapshot request) {
    final timestamp = (request['timestamp'] as Timestamp).toDate();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Submitted: ${DateFormat('MMM dd, yyyy').format(timestamp)}'),
        Text('Original Price: ${_formatCurrency(request['originalPrice'])}'),
        Text('Estimated Value: ${_formatCurrency(request['estimatedValue'])}'),
        Text('Has Accident: ${request['hasAccident'] ? 'Yes' : 'No'}'),
      ],
    );
  }

  Widget _buildActionButtons(DocumentSnapshot request) {
    final status = request['status'];
    
    switch (status) {
      case 'requestSubmitted':  // Changed from 'Pending'
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => _calculateAndOfferInsurance(request),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
              child: const Text('Calculate & Send Offer'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _reviewRequest(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Review Details'),
            ),
          ],
        );
        
      case 'offerGenerated':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Waiting for customer response',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        );
        
      case 'offerAccepted':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _approveOffer(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Approve & Request Payment'),
            ),
          ],
        );
        
      case 'paymentSubmitted':
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => _approvePayment(request),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Verify Payment & Activate'),
            ),
          ],
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  void _reviewRequest(DocumentSnapshot request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailsPage(requestId: request.id),
      ),
    );
  }

  void _showPendingRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminRequestPage()),
    );
  }

  Widget _buildInsuranceRequestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insurance Requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        _buildRequestList('New Requests', 'Pending'),
        const SizedBox(height: 24),
        _buildRequestList('Pending Approvals', 'OfferAccepted'),
        const SizedBox(height: 24),
        _buildRequestList('Payment Verification', 'PaymentSubmitted'),
      ],
    );
  }

  Widget _buildRequestList(String title, String status) {
    // Map display titles to actual status values
    final String queryStatus = switch (title) {
      'New Requests' => InsuranceStatus.requestSubmitted.name,
      'Offers Generated' => InsuranceStatus.offerGenerated.name,
      'Pending Approvals' => InsuranceStatus.offerAccepted.name,
      'Payment Verification' => InsuranceStatus.paymentSubmitted.name,
      _ => status,
    };

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('insuranceRequests')
          .where('status', isEqualTo: queryStatus)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;
        if (requests.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('No $title'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) => _buildRequestCard(requests[index]),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approveOffer(DocumentSnapshot request) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Update request status using enum
      batch.update(request.reference, {
        'status': InsuranceStatus.pendingPayment.name,
        'progress': InsuranceStatus.pendingPayment.progressMessage,
        'approvalDate': FieldValue.serverTimestamp(),
      });

      // Update vehicle status using same enum
      batch.update(
        FirebaseFirestore.instance
            .collection('vehicles')
            .doc(request['vehicleId']),
        {'insuranceStatus': InsuranceStatus.pendingPayment.name},
      );

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approvePayment(DocumentSnapshot request) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final expirationDate = DateTime.now().add(const Duration(days: 365));
      
      // Update request status using enum
      batch.update(request.reference, {
        'status': InsuranceStatus.active.name,  // Changed from 'Active'
        'progress': InsuranceStatus.active.progressMessage,  // Use enum's message
        'activationDate': FieldValue.serverTimestamp(),
        'expirationDate': Timestamp.fromDate(expirationDate),
      });

      // Update vehicle status using same enum
      batch.update(
        FirebaseFirestore.instance
            .collection('vehicles')
            .doc(request['vehicleId']),
        {
          'insuranceStatus': InsuranceStatus.active.name,  // Already correct
          'policyExpirationDate': Timestamp.fromDate(expirationDate),
        },
      );

      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment approved and insurance activated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _calculateAndOfferInsurance(DocumentSnapshot request) async {
    try {
      final carValue = request['estimatedValue'] as num;
      final hasAccident = request['hasAccident'] as bool;
      final manufacturingYear = request['manufacturingYear'] as int;
      
      // Calculate rates and depreciation
      final baseRate = hasAccident ? 0.06 : 0.05;
      final age = DateTime.now().year - manufacturingYear;
      final depreciationRate = (age * 0.1).clamp(0.0, 0.7);
      final adjustedValue = carValue * (1 - depreciationRate);

      // Create three different insurance packages
      final offers = [
        {
          'type': 'Basic',
          'coverage': adjustedValue * 0.7,
          'premium': adjustedValue * baseRate * 0.8,
          'features': [
            'Third-party liability',
            'Basic accident coverage',
            'Emergency roadside assistance'
          ],
          'description': 'Essential coverage with basic protection',
        },
        {
          'type': 'Standard',
          'coverage': adjustedValue * 0.85,
          'premium': adjustedValue * baseRate,
          'features': [
            'Third-party liability',
            'Comprehensive accident coverage',
            'Emergency roadside assistance',
            'Natural disaster protection',
            'Theft protection'
          ],
          'description': 'Balanced coverage with additional benefits',
        },
        {
          'type': 'Premium',
          'coverage': adjustedValue,
          'premium': adjustedValue * baseRate * 1.2,
          'features': [
            'Third-party liability',
            'Full comprehensive coverage',
            'Priority emergency assistance',
            'Natural disaster protection',
            'Theft protection',
            'Personal accident cover',
            'Replacement car service'
          ],
          'description': 'Maximum protection with premium benefits',
        }
      ];

      final batch = FirebaseFirestore.instance.batch();

      // Create insurance offers
      for (var offer in offers) {
        final offerRef = FirebaseFirestore.instance.collection('insuranceOffers').doc();
        batch.set(offerRef, {
          ...offer,
          'requestId': request.id,
          'vehicleId': request['vehicleId'],
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update request status
      batch.update(request.reference, {
        'status': InsuranceStatus.offerGenerated.name,
        'progress': InsuranceStatus.offerGenerated.progressMessage,
        'offeredAt': FieldValue.serverTimestamp(),
        'calculatedValue': adjustedValue,
        'baseRate': baseRate,
        'depreciationRate': depreciationRate,
      });

      // Update vehicle status
      batch.update(
        FirebaseFirestore.instance
            .collection('vehicles')
            .doc(request['vehicleId']),
        {'insuranceStatus': InsuranceStatus.offerGenerated.name},
      );

      await batch.commit();

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insurance offers generated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error generating offers: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating offers: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }
}

String _formatCurrency(num value) {
  return '\$${NumberFormat('#,##0.00').format(value)}';
}
