import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async'; // ✅ Add this for TimeoutException

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:5000';

  static Future<Map<String, dynamic>> predictAdmission(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        if (result['success'] == true) {
          return result;
        } else {
          throw Exception(result['error'] ?? 'Prediction failed with unknown error');
        }
      } else {
        throw HttpException(
          'Server responded with status code ${response.statusCode}',
          uri: Uri.parse('$_baseUrl/predict'),
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on TimeoutException {
      throw Exception('Request timed out. Please try again later.');
    } on FormatException {
      throw Exception('Invalid response format from the server.');
    } catch (e) {
      throw Exception('Unexpected error occurred: $e');
    }
  }
}
