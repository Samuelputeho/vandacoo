import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class Support extends StatelessWidget {
  const Support({super.key});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        );
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("We're here to help!", style: titleStyle),
            const SizedBox(height: 12),
            Text(
              "If you need assistance or have questions, feel free to reach out using the contact options below:",
              style: bodyStyle,
            ),
            const SizedBox(height: 24),
            _buildContactItem(
              number: "1.",
              email: "info@vandacoo.com",
              description: "General inquiries & customer support.",
            ),
            const SizedBox(height: 16),
            _buildContactItem(
              number: "2.",
              email: "support@vandacoo.com",
              description: "User assistance & troubleshooting.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required String number,
    required String email,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                WidgetSpan(
                  child: GestureDetector(
                    onTap: () => _launchEmail(email),
                    child: Text(
                      email,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextSpan(text: " – $description"),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
