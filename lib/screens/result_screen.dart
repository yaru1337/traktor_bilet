import 'package:flutter/material.dart';
import '../models.dart';

class ResultScreen extends StatelessWidget {
  final Ticket ticket;
  final int correct;

  const ResultScreen({super.key, required this.ticket, required this.correct});

  @override
  Widget build(BuildContext context) {
    final total = ticket.questions.length;
    final mistakes = total - correct;
    final passed = mistakes <= 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.title),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    size: 96,
                    color: passed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$correct из $total',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    passed ? 'Сдано' : 'Не сдано',
                    style: TextStyle(
                      fontSize: 20,
                      color: passed ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('К списку билетов', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Пройти ещё раз'),
                  ),
                ],
              ),
            ),
          ),
          // Пасхалка в правом нижнем углу
          Positioned(
            right: 8,
            bottom: 6,
            child: Text(
              '163 #1',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.withOpacity(0.4),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }