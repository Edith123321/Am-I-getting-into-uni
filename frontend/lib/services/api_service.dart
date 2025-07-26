import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';

class ApiService {
  // Replace with your Render backend URL
  static const String _baseUrl = 'https://am-i-getting-into-uni.onrender.com';

  static Future<Map<String, dynamic>> predictAdmission(Map<String, dynamic> data) async {
  try {
    final body = json.encode({
      'gre_score': int.parse(data['gre_score'] ?? '0'),
      'toefl_score': int.parse(data['toefl_score'] ?? '0'),
      'university_rating': int.parse(data['university_rating'] ?? '0'),
      'sop': double.parse(data['sop'] ?? '0'),
      'lor': double.parse(data['lor'] ?? '0'),
      'cgpa': double.parse(data['cgpa'] ?? '0'),
      'research': int.parse(data['research'] ?? '0'),
    });

    final response = await http
        .post(
          Uri.parse('$_baseUrl/predict'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw HttpException(
        error['error'] ?? 'Server error: ${response.statusCode}',
        uri: Uri.parse('$_baseUrl/predict'),
      );
    }
  } on SocketException {
    throw Exception('No internet connection.');
  } on TimeoutException {
    throw Exception('Request timed out. Try again.');
  } on FormatException {
    throw Exception('Bad response format.');
  } on HttpException catch (e) {
    throw Exception(e.message);
  } catch (e) {
    throw Exception('Prediction failed: $e');
  }
}

}