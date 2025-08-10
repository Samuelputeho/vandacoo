import 'package:flutter/material.dart';
import 'package:vandacoo/core/common/entities/user_entity.dart';

class PaymentPage extends StatefulWidget {
  final UserEntity user;

  const PaymentPage({
    super.key,
    required this.user,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _selectedDays = 1; // Default to 1 day

  void _handleContinue() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;

    // Navigate directly to upload screen with selected duration
    final result = await Navigator.pushNamed(
      context,
      '/upload-feeds',
      arguments: {
        'duration': _selectedDays,
        'selectedDays': _selectedDays, // Add redundant key for safety
        'user': widget.user,
      },
    );

    // Reset loading state when returning from upload screen
    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      // If upload was successful, return to previous screen
      if (result == true) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Advertisement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInfoCard(),
              const SizedBox(height: 20),
              _buildDaysSelection(),
              const SizedBox(height: 40),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Free Advertisement',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
          ),
          const SizedBox(height: 8),
          Text('Account Type: ${widget.user.accountType}'),
          const Text('Duration: 1-3 days free posting'),
        ],
      ),
    );
  }

  Widget _buildDaysSelection() {
    return Row(
      children: [
        const Text('Number of Days:', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _selectedDays,
            items: const [1, 2, 3].map((days) {
              return DropdownMenuItem(
                value: days,
                child: Text('$days ${days == 1 ? 'day' : 'days'}'),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDays = value;
                });
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
            validator: (value) {
              if (value == null) {
                return 'Please select number of days';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isLoading
              ? Colors.grey
              : (Theme.of(context).brightness == Brightness.dark
                  ? Colors.orange.shade600
                  : Theme.of(context).primaryColor),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Continue to Post Ad',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
