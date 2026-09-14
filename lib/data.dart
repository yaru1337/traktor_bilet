import 'dart:convert';
import 'package:flutter/services.dart';
import 'models.dart';

Future<List<Ticket>> loadTickets() async {
  final jsonStr = await rootBundle.loadString('assets/tickets.json');
  final Map<String, dynamic> data = json.decode(jsonStr) as Map<String, dynamic>;
  final tickets = data.values
      .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
      .toList();
  tickets.sort((a, b) => a.id.compareTo(b.id));
  return tickets;
}