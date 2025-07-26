import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {
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
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Convert form values to proper types
    final Map<String, dynamic> apiData = {
      'gre_score': int.tryParse(_formData['gre_score'] ?? '0') ?? 0,
      'toefl_score': int.tryParse(_formData['toefl_score'] ?? '0') ?? 0,
      'university_rating': int.tryParse(_formData['university_rating'] ?? '0') ?? 0,
      'sop': double.tryParse(_formData['sop'] ?? '0') ?? 0.0,
      'lor': double.tryParse(_formData['lor'] ?? '0') ?? 0.0,
      'cgpa': double.tryParse(_formData['cgpa'] ?? '0') ?? 0.0,
      'research': int.tryParse(_formData['research'] ?? '0') ?? 0,
    };

    setState(() {
      _isLoading = true;
      _showResult = false;
    });

    try {
      final result = await ApiService.predictAdmission(apiData);
      _controller.reset();
      _controller.forward();

      setState(() {
        _prediction = (result['prediction'] as num).toDouble();
        _isLoading = false;
        _showResult = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey.shade50,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade600,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.teal),
          ),
          labelStyle: TextStyle(color: Colors.teal.shade800),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Grad School Admission Prediction'),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal.shade500, Colors.indigo.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.teal.shade50],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAnimatedInput('GRE Score (290-340)', 'gre_score', TextInputType.number),
                  const SizedBox(height: 14),
                  _buildAnimatedInput('TOEFL Score (92-120)', 'toefl_score', TextInputType.number),
                  const SizedBox(height: 14),
                  _buildAnimatedInput(
                    'University Rating (1-5)',
                    'university_rating',
                    TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildAnimatedInput('Statement of Purpose (1-5)', 'sop', TextInputType.number),
                  const SizedBox(height: 14),
                  _buildAnimatedInput(
                    'Letter of Recommendation (1-5)',
                    'lor',
                    TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _buildAnimatedInput('Cumulative GPA (out of 10)', 'cgpa', TextInputType.number),
                  const SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: SwitchListTile(
                      title: Text(
                        'Research Experience',
                        style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade700),
                      ),
                      value: _formData['research'] == '1',
                      onChanged: (v) => setState(() => _formData['research'] = v ? '1' : '0'),
                      activeColor: Colors.teal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isLoading ? 60 : null,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: 16.0,
                          ), // inside the button
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('PREDICT MY CHANCES'),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  if (_showResult && _prediction != null)
                    ScaleTransition(scale: _animation, child: _buildResultCard()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInput(String label, String field, TextInputType type) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.school, color: Colors.teal),
        ),
        keyboardType: type,
        validator: (v) => v!.isEmpty ? 'Required' : null,
        onSaved: (v) => _formData[field] = v!,
      ),
    );
  }

  Widget _buildResultCard() {
    Color resultColor;
    if (_prediction! >= 0.7) {
      resultColor = Colors.green.shade600;
    } else if (_prediction! >= 0.4) {
      resultColor = Colors.orange.shade700;
    } else {
      resultColor = Colors.red.shade600;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              'ADMISSION PREDICTION',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20.0), // outside the circle
              child: Container(
                padding: const EdgeInsets.all(30), // inside the circle
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: resultColor.withOpacity(0.15),
                  border: Border.all(color: resultColor, width: 4),
                ),
                child: Text(
                  '${(_prediction! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: resultColor),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              _getResultMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.teal.shade800),
            ),
          ],
        ),
      ),
    );
  }

 String _getResultMessage() {
  if (_prediction! >= 0.8) {
    return 'Excellent chances of admission! Your academic profile and research experience are very strong. Keep up the great work, and consider applying to top-tier universities.';
  } else if (_prediction! >= 0.6) {
    return 'Good chances of getting admitted! Your profile is solid, but you could benefit from enhancing one or two areas, such as your SOP, LORs, or research background.';
  } else if (_prediction! >= 0.4) {
    return 'Fair chances of admission. While some areas of your profile are promising, improving your GRE/TOEFL scores, GPA, or gaining research experience could make a significant difference.';
  } else {
    return 'Currently low chances of admission. Focus on boosting your GRE/TOEFL scores, GPA, and research involvement. A stronger SOP and compelling LORs can also help increase your competitiveness.';
  }
}

}
