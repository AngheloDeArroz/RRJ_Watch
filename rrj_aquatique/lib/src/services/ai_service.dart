import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  static const String _apiKey = 'AIzaSyCGQ38SpZneoDwPPcAppzyATmIICe_NgWs';
  static const String _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

  static Future<String> generateInsightsFromLogs(
    List<Map<String, dynamic>> logs,
  ) async {
    final prompt =
        '''
You are an assistant for an IoT fish aquarium monitoring system.

Given the last 7 days of logs (structured in JSON), extract only important insights in bullet points:
- Summarize unusual trends in water temperature, pH, or turbidity.
- Mention any missed or irregular feedings.
- Estimate how many days are left for food and pH solutions based on start and end levels.

Format response as clean bullet points, without technical terms or raw data. Keep it under 100 words.

Logs (JSON):
${jsonEncode(logs)}
''';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawText =
          data['candidates'][0]['content']['parts'][0]['text'] ?? '';

      // ✅ Post-process: Keep only clean bullet points (optional)
      final cleaned = rawText
          .trim()
          .split('\n')
          .where(
            (line) =>
                line.trim().startsWith('•') || line.trim().startsWith('-'),
          )
          .take(6)
          .join('\n');

      return cleaned.isNotEmpty ? cleaned : rawText.trim();
    } else {
      print('[AI SERVICE] Error: ${response.body}');
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }
}
