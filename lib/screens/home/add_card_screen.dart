import 'package:flutter/material.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  _AddCardScreenState createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();

  String cardNumber = '';
  String cardholderName = '';
  String expirationDate = '';
  String cvv = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Process the card details here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Processing Card')),
      );
      // You can add further logic to save the card information
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Credit Card'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'XXXX XXXX XXXX XXXX',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  // Add additional validation for card number format
                  return null;
                },
                onChanged: (value) {
                  cardNumber = value;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
                onChanged: (value) {
                  cardholderName = value;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 60, // Set a fixed height for alignment
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Expiration Date (MM/YY)',
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.datetime,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter expiration date';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          expirationDate = value;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 60, // Set a fixed height for alignment
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter CVV';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          cvv = value;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Center(child: Text('Add Card')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
