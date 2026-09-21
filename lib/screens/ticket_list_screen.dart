import 'dart:math';
import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import 'quiz_screen.dart';
import 'stats_screen.dart';

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  late Future<List<Ticket>> _future;
  final Random _random = Random();
  int? _lastRandomId; // чтобы случайный не повторялся дважды подряд

  @override
  void initState() {
    super.initState();
    _future = loadTickets();
  }

  void _openTicket(BuildContext context, Ticket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(ticket: ticket)),
    );
  }

  void _openRandom(List<Ticket> tickets) {
    if (tickets.isEmpty) return;

    // Если билетов больше одного — исключаем предыдущий случайный
    Ticket chosen;
    if (tickets.length == 1) {
      chosen = tickets.first;
    } else {
      final pool = tickets.where((t) => t.id != _lastRandomId).toList();
      chosen = pool[_random.nextInt(pool.length)];
    }
    _lastRandomId = chosen.id;
    _openTicket(context, chosen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Тракторные билеты'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Статистика',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StatsScreen()),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Ошибка: ${snapshot.error}'));
          }
          final tickets = snapshot.data ?? [];
          if (tickets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Нет билетов.\nПроверьте assets/tickets.json',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              // ---- Сетка билетов ----
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1,
                  ),
                  itemCount: tickets.length,
                  itemBuilder: (context, i) {
                    final t = tickets[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openTicket(context, t),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${t.id}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                            Text(
                              '${t.questions.length} вопр.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ---- Кнопка «Случайный билет» ----
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openRandom(tickets),
                      icon: const Icon(Icons.shuffle),
                      label: const Text(
                        'Случайный билет',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}