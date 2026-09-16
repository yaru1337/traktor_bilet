import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';

import '../models.dart';
import 'photo_screen.dart';
import 'result_screen.dart';

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
  int mistakes = 0;

  static const int maxMistakes = 1;
  static const int secondsPerQuestion = 60;
  late int secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    secondsLeft = secondsPerQuestion * widget.ticket.questions.length;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        secondsLeft--;
        if (secondsLeft <= 0) {
          _timer?.cancel();
          _finish();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          ticket: widget.ticket,
          correct: correctCount,
        ),
      ),
    );
  }

  Question get q => widget.ticket.questions[currentIndex];
  bool get isLast => currentIndex == widget.ticket.questions.length - 1;
  bool get isAnswered => selected != null;

  void _answer(int index) {
    if (isAnswered) return;

    final isCorrect = index == q.correct;

    setState(() {
      selected = index;
      if (isCorrect) {
        correctCount++;
      } else {
        mistakes++;
      }
    });

    // Вторая ошибка — сразу завершаем билет
    if (mistakes > maxMistakes) {
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _finish();
      });
    }
  }

  void _next() {
    if (isLast) {
      _timer?.cancel();
      _finish();
    } else {
      setState(() {
        currentIndex++;
        selected = null;
      });
    }
  }

  void _openTicketPhoto() {
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

  String get _timeLabel {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Color get _timeColor {
    if (secondsLeft <= 60) return Colors.red.shade400;
    if (secondsLeft <= 180) return Colors.orange.shade400;
    return Colors.white;
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
    final blocked = mistakes > maxMistakes;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.ticket.title} • ${currentIndex + 1}/$total'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 20, color: _timeColor),
                  const SizedBox(width: 4),
                  Text(
                    _timeLabel,
                    style: TextStyle(
                      color: _timeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Фото билета',
            icon: const Icon(Icons.image),
            onPressed: _openTicketPhoto,
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
                  if (q.image != null && q.image!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PhotoScreen(
                              imagePath: q.image!,
                              title: 'Иллюстрация',
                            ),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            q.image!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  Text(
                    q.text,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(q.options.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: _optionColor(i) ?? Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: (isAnswered || blocked) ? null : () => _answer(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
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
                                  child: Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade900,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q.options[i],
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
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
                  onPressed: (isAnswered && !blocked) ? _next : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isLast ? 'Завершить' : 'Далее',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}