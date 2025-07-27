import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';

class ApiService {
  static const String _baseUrl = 'https://am-i-getting-into-uni.onrender.com';
  static const String _predictEndpoint = '/predict';
  static const Duration _timeout = Duration(seconds: 15);

  static Future<Map<String, dynamic>> predictAdmission(Map<String, dynamic> data) async {
    try {
      final cleaned = _sanitizeInput(data);

      final response = await http.post(
        Uri.parse('$_baseUrl$_predictEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(cleaned),
      ).timeout(_timeout);

      return _handleResponse(response);

    } on SocketException {
      throw const NetworkException('No internet connection.');
    } on TimeoutException {
      throw const NetworkException('Server timeout.');
    } on FormatException {
      throw const DataException('Invalid response format.');
    } on http.ClientException catch (e) {
      throw NetworkException('Client error: ${e.message}');
    } catch (e) {
      throw ApiException('Unexpected error: ${e.toString()}');
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
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'success': true,
        'prediction': (data['prediction'] as num).toDouble(),
        'recommendations': List<String>.from(data['recommendations'] ?? []),
      };
    } else {
      throw ApiException(data['error'] ?? 'Prediction failed.', statusCode: response.statusCode);
    }
  }

  static int _parseInt(dynamic value) {
    if (value == null) throw const DataException('Missing required integer field.');
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? (throw DataException('Invalid integer: $value'));
    throw DataException('Invalid type for int: ${value.runtimeType}');
  }

  static double _parseDouble(dynamic value) {
    if (value == null) throw const DataException('Missing required number field.');
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? (throw DataException('Invalid number: $value'));
    throw DataException('Invalid type for number: ${value.runtimeType}');
  }
}

// ===== Custom Exceptions =====
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  const NetworkException(String msg, {int? statusCode}) : super(msg, statusCode: statusCode);
}

class DataException extends ApiException {
  const DataException(String msg, {int? statusCode}) : super(msg, statusCode: statusCode);
}
