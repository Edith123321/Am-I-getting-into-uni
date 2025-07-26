import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiService {
  static const String _baseUrl = 'https://am-i-getting-into-uni.onrender.com';

  static Future<Map<String, dynamic>> predictAdmission(Map<String, dynamic> data) async {
    try {
      // Safely parse input values with fallbacks
      final body = json.encode({
        'gre_score': _parseInt(data['gre_score']),
        'toefl_score': _parseInt(data['toefl_score']),
        'university_rating': _parseInt(data['university_rating']),
        'sop': _parseDouble(data['sop']),
        'lor': _parseDouble(data['lor']),
        'cgpa': _parseDouble(data['cgpa']),
        'research': _parseInt(data['research']), // Changed to int since research is 0/1
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        // Ensure prediction is properly typed
        if (result['prediction'] != null) {
          result['prediction'] = (result['prediction'] as num).toDouble();
        }
        return result;
      } else {
        final error = json.decode(response.body);
        throw HttpException(
          error['error']?.toString() ?? 'Server error: ${response.statusCode}',
          uri: Uri.parse('$_baseUrl/predict'),
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on TimeoutException {
      throw Exception('Request timed out. The server might be busy. Please try again.');
    } on FormatException {
      throw Exception('Invalid response format from server.');
    } on HttpException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to get prediction: ${e.toString()}');
    }
  }

  // Helper methods for safe parsing
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is int) return value.toDouble();
    return 0.0;
  }
}