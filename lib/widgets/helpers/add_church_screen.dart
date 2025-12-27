import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../UI/app_linear_progress_bar.dart';

class AddChurchScreen extends StatefulWidget {
  const AddChurchScreen({super.key});

  @override
  State<AddChurchScreen> createState() => _AddChurchScreenState();
}

class _AddChurchScreenState extends State<AddChurchScreen> {
  final _nameController = TextEditingController();
  final _parishController = TextEditingController();
  final _pastorController = TextEditingController();
  final _adminController = TextEditingController();
  final _locationController = TextEditingController();
  final _countryController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createChurch() async {
    final churchName = _nameController.text.trim();
    final parishName = _parishController.text.trim();
    final pastorName = _pastorController.text.trim();
    final churchAdminEmail = _adminController.text.trim();
    final address = _locationController.text.trim();
    final country = _countryController.text.trim();

    if (churchName.isEmpty || parishName.isEmpty || pastorName.isEmpty || churchAdminEmail.isEmpty || country.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw "You must be signed in";
      }

      final churchId = "${churchName.toLowerCase().replaceAll(' ', '_')}_${parishName.toLowerCase().replaceAll(' ', '_')}";

      // Call secure backend
      // THIS IS THE NEW PART — WRITE TO church_requests COLLECTION
      await FirebaseFirestore.instance.collection('church_requests').add({
        'fullChurchName': "$churchName - $parishName",
        'churchId': churchId,
        'churchName': churchName,
        'parishName': parishName,
        'address': address.isEmpty ? "Not provided" : address,
        'country': country,
        'churchAdminEmail': churchAdminEmail,
        'pastorName': pastorName,
        'pastorUid': user.uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      // SUCCESS — Show beautiful confirmation
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text("Request Sent!", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Thank you, ${user.displayName ?? 'Pastor'}!"),
              const SizedBox(height: 12),
              Text(
                "Your request to create:\n\n"
                "🏛️ $churchName\n"
                "📍 $parishName\n"
                "🌍 $country\n\n"
                "has been sent.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "You will receive a notification within 24 hours when approved.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();     // close dialog
                  Navigator.of(context).pop();  // go back to main screen
                },
                child: const Text("Got it!", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      );

    } catch (e) {
      // FAILURE — show error dialog
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text("Could not send request"),
            ],
          ),
          content: Text(e.toString().contains("already-exists")
              ? "A church with this name already exists. Please contact support."
              : "Error: ${e.toString()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _parishController.dispose();
    _pastorController.dispose();
    _adminController.dispose();
    _locationController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create Your Church"),
        backgroundColor: const Color(0xFF5D8668),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Church Information", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Church Name *",
                hintText: "e.g. RCCG, Winners Chapel, Deeper Life",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _parishController,
              decoration: const InputDecoration(
                labelText: "Parish / Branch Name *",
                hintText: "e.g. Grace Lagos, Jesus House Abuja",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _pastorController,
              decoration: const InputDecoration(
                labelText: "Pastor's Name *",
                hintText: "e.g. Pastor John Doe",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _adminController,
              decoration: const InputDecoration(
                labelText: "Admin Email *",
                hintText: "e.g. admin@grace-lagos.org",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: "Address (optional)",
                hintText: "123 Faith Street, Lagos",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: "Country *",
                hintText: "e.g. Nigeria, USA, UK",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createChurch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  child: _isLoading
                      ? const LinearProgressBar()
                      : const Text("Submit Request", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}