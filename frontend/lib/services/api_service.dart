import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiService {
  // Replace with your Render backend URL
  static const String _baseUrl = 'https://uni-admission-predictor.onrender.com';

  static Future<Map<String, dynamic>> predictAdmission(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/predict'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',  // Added for better compatibility
            },
            body: json.encode({
              ...data,
              // Ensure numeric values are parsed correctly
              'gre_score': int.tryParse(data['gre_score']?.toString() ?? '0'),
              'toefl_score': int.tryParse(data['toefl_score']?.toString() ?? '0'),
              'university_rating': int.tryParse(data['university_rating']?.toString() ?? '0'),
              'sop': double.tryParse(data['sop']?.toString() ?? '0'),
              'lor': double.tryParse(data['lor']?.toString() ?? '0'),
              'cgpa': double.tryParse(data['cgpa']?.toString() ?? '0'),
              'research': int.tryParse(data['research']?.toString() ?? '0'),
            }),
          )
          .timeout(const Duration(seconds: 15));  // Increased timeout for Render

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);
        return result;
      } else {
        // Handle different error status codes
        final errorResponse = json.decode(response.body);
        throw HttpException(
          errorResponse['error'] ?? 'Server error: ${response.statusCode}',
          uri: Uri.parse('$_baseUrl/predict'),
        );
      }
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } on TimeoutException {
      throw Exception('Request timed out. The server might be starting up. Try again in 30 seconds.');
    } on FormatException {
      throw Exception('Invalid response format from the server.');
    } on HttpException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to get prediction: ${e.toString()}');
    }
  }
}