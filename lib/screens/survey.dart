import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:privacy_insight/database/database_helper.dart';

class Survey extends StatefulWidget {
  final int userId;
  const Survey({Key? key, required this.userId}) : super(key: key);

  @override
  _SurveyState createState() => _SurveyState();
}

class _SurveyState extends State<Survey> {
  late List<Map<String, dynamic>> _questions;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, int> _answers = {};

  @override
  void initState() {
    super.initState();
    _loadSurveyQuestions();
  }

  // Loads survey questions and fetches previous responses from the database
  Future<void> _loadSurveyQuestions() async {
    List<Map<String, dynamic>> storedResponses =
    await _dbHelper.getSurveyResponses(widget.userId);
    Map<String, int> previousAnswers = {
      for (var response in storedResponses)
        response['question']: int.parse(response['answer'])
    };

    String jsonString = await DefaultAssetBundle.of(context)
        .loadString("assets/survey_questions.json");
    List<dynamic> jsonData = json.decode(jsonString);

    setState(() {
      _questions = jsonData.map((q) => q as Map<String, dynamic>).toList();
      _answers = previousAnswers;
    });
  }

  // Resets all answers to default (clears selections)
  void _resetAnswers() {
    setState(() {
      _answers.clear();
    });
  }

  // Submits the survey responses and updates the user's privacy score
  Future<void> _submitSurvey() async {
    if (_answers.length != _questions.length) {
      _showWarning();
      return;
    }

    for (var question in _questions) {
      await _dbHelper.insertSurveyResponse({
        'user_id': widget.userId,
        'question': question['id'],
        'answer': _answers[question['id']].toString(),
      });
    }

    double privacyScore = _calculatePrivacyScore();
    await _dbHelper.updateUserPrivacyScore(widget.userId, privacyScore);

    Navigator.pop(context);
  }

  // Calculates the privacy score based on the user's answers
  double _calculatePrivacyScore() {
    int totalScore = _answers.values.fold(0, (sum, value) => sum + value);
    int maxScore = _questions.length * 3;
    return (totalScore / maxScore) * 100;
  }

  // Displays a warning message if not all questions are answered
  void _showWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please answer all questions before submitting."),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Matches Home Page background
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Survey"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _questions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            var question = _questions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question['question'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green, // Matches Home Page
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: question['options'].map<Widget>((option) {
                        return RadioListTile<int>(
                          title: Text(option['text']),
                          value: option['value'],
                          activeColor: Colors.green.shade700,
                          groupValue: _answers[question['id']],
                          onChanged: (int? value) {
                            setState(() {
                              _answers[question['id']] = value!;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _resetAnswers,
              style: TextButton.styleFrom(
                foregroundColor: Colors.green.shade700,
              ),
              child: const Text("Reset"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _answers.length == _questions.length ? _submitSurvey : null,
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
