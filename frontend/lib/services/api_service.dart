import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiService {
  static const String _baseUrl = 'https://am-i-getting-into-uni.onrender.com';
  static const String _predictEndpoint = '/predict';
  static const Duration _timeoutDuration = Duration(seconds: 15);

  static Future<Map<String, dynamic>> predictAdmission(
      Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_predictEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(_sanitizeInput(data)),
      ).timeout(_timeoutDuration);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection');
    } on TimeoutException {
      throw Exception('Request timed out');
    } on FormatException {
      throw Exception('Invalid server response');
    } on http.ClientException catch (e) {
      throw Exception('Connection failed: ${e.message}');
    } catch (e) {
      throw Exception('Prediction failed: ${e.toString()}');
    }
  }

  static Map<String, dynamic> _sanitizeInput(Map<String, dynamic> data) {
    return {
      'gre_score': _parseInt(data['gre_score']),
      'toefl_score': _parseInt(data['toefl_score']),
      'university_rating': _parseInt(data['university_rating']),
      'sop': _parseDouble(data['sop']),
      'lor': _parseDouble(data['lor']),
      'cgpa': _parseDouble(data['cgpa']),
      'research': _parseInt(data['research']),
    };
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = json.decode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'prediction': (responseData['prediction'] as num).toDouble(),
        'recommendations': responseData['recommendations'] ?? [],
      };
    } else {
      throw Exception(
        responseData['error']?.toString() ?? 
        'Request failed with status ${response.statusCode}',
      );
    }
  }

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