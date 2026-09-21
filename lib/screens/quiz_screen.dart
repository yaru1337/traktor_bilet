import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;
import '../models.dart';
import 'result_screen.dart';
import 'photo_screen.dart';
import '../stats.dart';

class QuizScreen extends StatefulWidget {
  final Ticket ticket;
  const QuizScreen({super.key, required this.ticket});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const int examDurationSeconds = 10 * 60; // 10 минут
  static const int maxMistakes = 2;

  int currentIndex = 0;
  late List<int> answers;

  Timer? _timer;
  int secondsLeft = examDurationSeconds;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    answers = List<int>.filled(widget.ticket.questions.length, -1);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (finished) return;
      setState(() {
        secondsLeft--;
      });
      if (secondsLeft <= 0) {
        _finish('time');
      }
    });
  }

  // ----- геттеры -----

  Question get q => widget.ticket.questions[currentIndex];
  bool get isAnswered => answers[currentIndex] != -1;
  int get selected => answers[currentIndex];
  bool get isLast => currentIndex == widget.ticket.questions.length - 1;
  int get answeredCount => answers.where((a) => a != -1).length;
  bool get allAnswered => answeredCount == widget.ticket.questions.length;

  int get correctCount {
    int count = 0;
    for (int i = 0; i < widget.ticket.questions.length; i++) {
      if (answers[i] == widget.ticket.questions[i].correct) count++;
    }
    return count;
  }

  int get wrongCount {
    int count = 0;
    for (int i = 0; i < widget.ticket.questions.length; i++) {
      if (answers[i] != -1 && answers[i] != widget.ticket.questions[i].correct) {
        count++;
      }
    }
    return count;
  }

  String get _timeLabel {
    final m = (secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timeColor {
    if (secondsLeft <= 30) return Colors.red.shade300;
    if (secondsLeft <= 60) return Colors.orange.shade300;
    return Colors.white;
  }

  // ----- действия -----

  void _answer(int index) {
    if (finished) return;
    if (isAnswered) return; // ответ уже зафиксирован — менять нельзя

    setState(() {
      answers[currentIndex] = index;
    });

    if (wrongCount >= maxMistakes) {
      _finish('mistakes');
    }
  }

  void _goTo(int index) {
    if (finished) return;
    setState(() => currentIndex = index);
  }

  void _next() {
    if (isLast) {
      if (allAnswered) {
        _finish(null);
      } else {
        final firstUnanswered = answers.indexOf(-1);
        if (firstUnanswered != -1) {
          setState(() => currentIndex = firstUnanswered);
        }
      }
    } else {
      setState(() => currentIndex++);
    }
  }

  void _finish(String? reason) {
    if (finished) return;
    finished = true;
    _timer?.cancel();

    // Сохраняем результат в статистику
    final total = widget.ticket.questions.length;
    final cc = correctCount;
    final passed = reason == null && cc >= (total * 0.8).ceil();
    StatsService.saveResult(
      ticketId: widget.ticket.id,
      correct: cc,
      passed: passed,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          ticket: widget.ticket,
          correct: cc,
          failReason: reason,
        ),
      ),
    );
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

  Color _tabColor(int i) {
    if (answers[i] == -1) return Colors.grey.shade300;
    return answers[i] == widget.ticket.questions[i].correct
        ? Colors.green.shade500
        : Colors.red.shade500;
  }

  String get _buttonLabel {
    if (isLast) {
      return allAnswered ? 'Завершить' : 'К неотвеченному';
    }
    return 'Далее';
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Icon(Icons.timer, size: 18, color: _timeColor),
                const SizedBox(width: 4),
                Text(
                  _timeLabel,
                  style: TextStyle(
                    color: _timeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                Icon(
                  Icons.close,
                  size: 16,
                  color: wrongCount == 0
                      ? Colors.white70
                      : Colors.red.shade300,
                ),
                const SizedBox(width: 2),
                Text(
                  '$wrongCount/$maxMistakes',
                  style: TextStyle(
                    color: wrongCount == 0
                        ? Colors.white70
                        : Colors.red.shade300,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Фото билета',
            icon: const Icon(Icons.image),
            onPressed: _openPhoto,
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Панель с номерами ----
          Container(
            color: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(total, (i) {
                  final isCurrent = i == currentIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: InkWell(
                      onTap: () => _goTo(i),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _tabColor(i),
                          shape: BoxShape.circle,
                          border: isCurrent
                              ? Border.all(
                                  color: Colors.green.shade900,
                                  width: 2.5,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: answers[i] == -1
                                ? Colors.black54
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ---- Прогресс ----
          LinearProgressIndicator(
            value: answeredCount / total,
            backgroundColor: Colors.green.shade50,
            valueColor: AlwaysStoppedAnimation(Colors.green.shade600),
          ),

          // ---- Вопрос и варианты ----
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          // Клик работает только пока ответ не дан
                          onTap: isAnswered ? null : () => _answer(i),
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

          // ---- Кнопка ----
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
                  child: Text(
                    _buttonLabel,
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