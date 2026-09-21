import 'package:flutter/material.dart';
import '../data.dart';
import '../models.dart';
import '../stats.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<_StatsView> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StatsView> _load() async {
    final tickets = await loadTickets();
    final stats = await StatsService.load();
    return _StatsView(tickets: tickets, stats: stats);
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Сбросить статистику?'),
        content: const Text('Все результаты будут удалены. Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await StatsService.clear();
      setState(() => _future = _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Сбросить',
            onPressed: _reset,
          ),
        ],
      ),
      body: FutureBuilder<_StatsView>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final v = snap.data!;
          if (v.stats.isEmpty) return _empty();
          return _content(v);
        },
      ),
    );
  }

  Widget _empty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Пока нет пройденных билетов.\nПройдите хотя бы один — статистика появится здесь.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ),
      );

  Widget _content(_StatsView v) {
    final total = v.tickets.length;
    final attempted = v.stats.length;
    final passedCount = v.stats.values.where((s) => s.passed).length;
    final attemptsTotal =
        v.stats.values.fold<int>(0, (a, s) => a + s.attempts);
    final bestAvg = v.stats.isEmpty
        ? 0.0
        : v.stats.values.map((s) => s.bestCorrect).reduce((a, b) => a + b) /
            v.stats.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          _card('Пройдено', '$attempted из $total', Icons.checklist, Colors.blue),
          const SizedBox(width: 10),
          _card('Сдано', '$passedCount', Icons.emoji_events, Colors.green),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _card('Средний лучший', bestAvg.toStringAsFixed(1),
              Icons.trending_up, Colors.orange),
          const SizedBox(width: 10),
          _card('Всего попыток', '$attemptsTotal', Icons.repeat, Colors.purple),
        ]),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('По билетам',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        ...v.tickets.map((t) => _ticketRow(t, v.stats[t.id])),
      ],
    );
  }

  Widget _card(String label, String value, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.shade50,
          border: Border.all(color: color.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.shade700, size: 22),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color.shade900)),
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _ticketRow(Ticket t, TicketStat? s) {
    Color barColor;
    String right;
    IconData? trailingIcon;
    Color? trailingColor;

    if (s == null) {
      barColor = Colors.grey.shade300;
      right = 'не пройден';
      trailingIcon = null;
      trailingColor = null;
    } else if (s.passed) {
      barColor = Colors.green.shade400;
      right = '${s.bestCorrect}/${t.questions.length}';
      trailingIcon = Icons.check_circle;
      trailingColor = Colors.green;
    } else {
      barColor = Colors.red.shade400;
      right = '${s.bestCorrect}/${t.questions.length}';
      trailingIcon = Icons.cancel;
      trailingColor = Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 32,
            color: barColor,
            margin: const EdgeInsets.only(right: 10),
          ),
          SizedBox(
            width: 32,
            child: Text('${t.id}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Попыток: ${s?.attempts ?? 0}',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                if (s != null)
                  Text('Последний: ${_fmt(s.lastDate)}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(right,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
          if (trailingIcon != null) ...[
            const SizedBox(width: 6),
            Icon(trailingIcon, color: trailingColor, size: 20),
          ],
        ],
      ),
    );
  }

  String _fmt(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _StatsView {
  final List<Ticket> tickets;
  final Map<int, TicketStat> stats;
  _StatsView({required this.tickets, required this.stats});
}