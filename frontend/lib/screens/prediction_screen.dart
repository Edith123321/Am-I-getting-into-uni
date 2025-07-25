import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter/animation.dart';

class PredictionScreen extends StatefulWidget {
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
      duration: const Duration(milliseconds: 800),
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
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.deepPurple,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.light(
          primary: Colors.deepPurple,
          secondary: Colors.amber,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            elevation: 4,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.deepPurple),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.amber),
          ),
          labelStyle: TextStyle(color: Colors.deepPurple),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'What Are My Chances of Getting Into Grad School?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.deepPurple.shade50],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAnimatedInput('GRE Score (290-340)', 'gre_score', TextInputType.number),
                    SizedBox(height: 12),
                    _buildAnimatedInput('TOEFL Score (92-120)', 'toefl_score', TextInputType.number),
                    SizedBox(height: 12),
                    _buildAnimatedInput('University Rating (1-5)', 'university_rating', TextInputType.number),
                    SizedBox(height: 12),
                    _buildAnimatedInput('Statement of Purpose (1-5)', 'sop', TextInputType.number),
                    SizedBox(height: 12),
                    _buildAnimatedInput('Letter of Recommendation (1-5)', 'lor', TextInputType.number),
                    SizedBox(height: 12),
                    _buildAnimatedInput('Cumulative GPA (out of 10)', 'cgpa', TextInputType.number),
                    SizedBox(height: 16),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: Text(
                          'Research Experience',
                          style: TextStyle(
                            color: Colors.deepPurple,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: _formData['research'] == '1',
                        onChanged: (v) => setState(() => _formData['research'] = v ? '1' : '0'),
                        activeColor: Colors.amber,
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
                            : Text(
                                'PREDICT MY CHANCES',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),
                    if (_showResult && _prediction != null)
                      ScaleTransition(
                        scale: _animation,
                        child: _buildResultCard(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInput(String label, String field, TextInputType type) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.school, color: Colors.deepPurple),
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
      resultColor = Colors.green;
    } else if (_prediction! >= 0.4) {
      resultColor = Colors.orange;
    } else {
      resultColor = Colors.red;
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade50,
            ],
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
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resultColor.withOpacity(0.2),
                border: Border.all(
                  color: resultColor,
                  width: 4,
                ),
              ),
              child: Text(
                '${(_prediction! * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              _getResultMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.deepPurple.shade800,
              ),
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
      return 'Needs improvement. Consider these recommendations:';
    }
  }
}