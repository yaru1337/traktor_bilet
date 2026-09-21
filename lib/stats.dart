import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TicketStat {
  final int attempts;
  final int bestCorrect;
  final int lastCorrect;
  final DateTime lastDate;
  final bool passed;

  TicketStat({
    required this.attempts,
    required this.bestCorrect,
    required this.lastCorrect,
    required this.lastDate,
    required this.passed,
  });

  factory TicketStat.fromJson(Map<String, dynamic> j) => TicketStat(
        attempts: j['attempts'] ?? 0,
        bestCorrect: j['bestCorrect'] ?? 0,
        lastCorrect: j['lastCorrect'] ?? 0,
        lastDate: DateTime.tryParse(j['lastDate'] ?? '') ?? DateTime.now(),
        passed: j['passed'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'attempts': attempts,
        'bestCorrect': bestCorrect,
        'lastCorrect': lastCorrect,
        'lastDate': lastDate.toIso8601String(),
        'passed': passed,
      };
}

class StatsService {
  static const _key = 'ticket_stats';

  static Future<Map<int, TicketStat>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
      return data.map((k, v) =>
          MapEntry(int.parse(k), TicketStat.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveResult({
    required int ticketId,
    required int correct,
    required bool passed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await load();
    final prev = all[ticketId];

    all[ticketId] = TicketStat(
      attempts: (prev?.attempts ?? 0) + 1,
      bestCorrect: prev == null
          ? correct
          : (correct > prev.bestCorrect ? correct : prev.bestCorrect),
      lastCorrect: correct,
      lastDate: DateTime.now(),
      passed: (prev?.passed ?? false) || passed,
    );

    final jsonMap = all.map((k, v) => MapEntry(k.toString(), v.toJson()));
    await prefs.setString(_key, json.encode(jsonMap));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}