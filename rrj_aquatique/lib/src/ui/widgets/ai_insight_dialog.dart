import 'package:flutter/material.dart';

class AiInsightDialog {
  static Future<void> show(BuildContext context, String insightText) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'AI Insights',
          style: TextStyle(
            fontFamily: 'Lexend',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            insightText,
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 16,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(
                fontFamily: 'Lexend',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
