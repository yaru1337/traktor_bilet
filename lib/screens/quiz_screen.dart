import 'package:flutter/material.dart';
import '../models.dart';
import 'result_screen.dart';
import 'photo_screen.dart';

class QuizScreen extends StatefulWidget {
  final Ticket ticket;
  const QuizScreen({super.key, required this.ticket});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int? selected;
  int correctCount = 0;

  Question get q => widget.ticket.questions[currentIndex];
  bool get isLast => currentIndex == widget.ticket.questions.length - 1;
  bool get isAnswered => selected != null;

  void _answer(int index) {
    if (isAnswered) return;
    setState(() {
      selected = index;
      if (index == q.correct) correctCount++;
    });
  }

  void _next() {
    if (isLast) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(ticket: widget.ticket, correct: correctCount),
        ),
      );
    } else {
      setState(() {
        currentIndex++;
        selected = null;
      });
    }
  }

  void _openPhoto() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoScreen(
          imagePath: widget.ticket.imagePath,
          title: widget.ticket.title,
        ),
      ),
    );
  }

  Color? _optionColor(int i) {
    if (!isAnswered) return null;
    if (i == q.correct) return Colors.green.shade100;
    if (i == selected) return Colors.red.shade100;
    return null;
  }

  Color? _optionBorder(int i) {
    if (!isAnswered) return null;
    if (i == q.correct) return Colors.green;
    if (i == selected) return Colors.red;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.ticket.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.ticket.title} • ${currentIndex + 1}/$total'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Фото билета',
            icon: const Icon(Icons.image),
            onPressed: _openPhoto,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentIndex + 1) / total,
            backgroundColor: Colors.green.shade50,
            valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.text,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  ...List.generate(q.options.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: _optionColor(i) ?? Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: isAnswered ? null : () => _answer(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _optionBorder(i) ?? Colors.grey.shade300,
                                width: _optionBorder(i) != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.green.shade100,
                                  child: Text('${i + 1}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(q.options[i],
                                    style: const TextStyle(fontSize: 15))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isAnswered ? _next : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(isLast ? 'Завершить' : 'Далее',
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}