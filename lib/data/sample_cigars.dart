import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/cigar.dart';

Future<List<Cigar>> loadCigars() async {
  final jsonString = await rootBundle.loadString('assets/data/prices.json');
  final List<dynamic> jsonList = json.decode(jsonString);

  return jsonList.map((item) => Cigar.fromMap(item)).toList();
}