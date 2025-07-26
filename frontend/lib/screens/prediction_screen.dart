import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/animation.dart';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  _PredictionScreenState createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> with SingleTickerProviderStateMixin {
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
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _showResult = false;
    });

    try {
      final result = await ApiService.predictAdmission(_formData);
      setState(() {
        _prediction = result['prediction'];
        _isLoading = false;
      });
      _controller.reset();
      _controller.forward();
      setState(() => _showResult = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
            textStyle: TextStyle(fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.teal),
          ),
          labelStyle: TextStyle(color: Colors.teal.shade800),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Grad School Admission Prediction'),
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
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildAnimatedInput('GRE Score (290-340)', 'gre_score', TextInputType.number),
                  SizedBox(height: 14),
                  _buildAnimatedInput('TOEFL Score (92-120)', 'toefl_score', TextInputType.number),
                  SizedBox(height: 14),
                  _buildAnimatedInput('University Rating (1-5)', 'university_rating', TextInputType.number),
                  SizedBox(height: 14),
                  _buildAnimatedInput('Statement of Purpose (1-5)', 'sop', TextInputType.number),
                  SizedBox(height: 14),
                  _buildAnimatedInput('Letter of Recommendation (1-5)', 'lor', TextInputType.number),
                  SizedBox(height: 14),
                  _buildAnimatedInput('Cumulative GPA (out of 10)', 'cgpa', TextInputType.number),
                  SizedBox(height: 16),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: SwitchListTile(
                      title: Text('Research Experience',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.teal.shade700)),
                      value: _formData['research'] == '1',
                      onChanged: (v) => setState(() => _formData['research'] = v ? '1' : '0'),
                      activeColor: Colors.teal,
                    ),
                  ),
                  SizedBox(height: 24),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _isLoading ? 60 : double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('PREDICT MY CHANCES'),
                    ),
                  ),
                  SizedBox(height: 30),
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
      duration: Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.school, color: Colors.teal),
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
        padding: EdgeInsets.all(24),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(20),
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
            SizedBox(height: 16),
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
      return 'Excellent chances! Your profile is very competitive.';
    } else if (_prediction! >= 0.6) {
      return 'Good chances! Consider strengthening 1-2 areas.';
    } else if (_prediction! >= 0.4) {
      return 'Moderate chances. Focus on improving your weak areas.';
    } else {
      return 'Needs improvement. Consider enhancing your GRE/TOEFL or research experience.';
    }
  }
}
