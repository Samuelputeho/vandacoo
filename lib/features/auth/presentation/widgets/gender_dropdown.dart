import 'package:flutter/material.dart';

class GenderDropDown extends StatelessWidget {
  final String? selectedGender;
  final Function(String?) onGenderChanged;
  final List<String> genderOptions;

  const GenderDropDown({
    super.key,
    required this.selectedGender,
    required this.onGenderChanged,
    this.genderOptions = const ['Male', 'Female', 'Prefer not to say'],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedGender,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            hint: const Text('Select Gender'),
            items: genderOptions.map((String gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(gender),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select your gender';
              }
              return null;
            },
            onChanged: onGenderChanged,
          ),
        ],
      ),
    );
  }
}
