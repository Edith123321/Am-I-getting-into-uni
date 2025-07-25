import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionScreen extends StatefulWidget {
  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'gre_score': '',
    'toefl_score': '',
    'university_rating': '',
    'sop': '',
    'lor': '',
    'cgpa': '',
    'research': '0',
  };
  bool _isLoading = false;
  double? _prediction;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.predictAdmission(_formData);
      setState(() => _prediction = result['prediction']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admission Predictor')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('GRE Score', 'gre_score', TextInputType.number),
              _buildTextField('TOEFL Score', 'toefl_score', TextInputType.number),
              _buildTextField('University Rating (1-5)', 'university_rating', TextInputType.number),
              _buildTextField('SOP (1-5)', 'sop', TextInputType.number),
              _buildTextField('LOR (1-5)', 'lor', TextInputType.number),
              _buildTextField('CGPA (out of 10)', 'cgpa', TextInputType.number),
              SwitchListTile(
                title: Text('Research Experience'),
                value: _formData['research'] == '1',
                onChanged: (v) => setState(() => _formData['research'] = v ? '1' : '0'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? CircularProgressIndicator() : Text('Predict'),
              ),
              if (_prediction != null)
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    'Admission Chance: ${(_prediction! * 100).toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String field, TextInputType type) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: type,
      validator: (v) => v!.isEmpty ? 'Required' : null,
      onSaved: (v) => _formData[field] = v!,
    );
  }
}