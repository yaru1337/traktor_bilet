class Question {
  final String text;
  final List<String> options;
  final int correct;

  Question({required this.text, required this.options, required this.correct});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
        text: json['text'] as String,
        options: List<String>.from(json['options'] as List),
        correct: json['correct'] as int,
      );
}

class Ticket {
  final int id;
  final String title;
  final List<Question> questions;

  Ticket({required this.id, required this.title, required this.questions});

  String get imagePath => 'assets/tickets/$id.jpg';

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'] as int,
        title: json['title'] as String,
        questions: (json['questions'] as List)
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}