import 'package:cloud_firestore/cloud_firestore.dart';

Object? fieldValue(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    if (data.containsKey(key) && data[key] != null) return data[key];
  }
  return null;
}

String stringField(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  final value = fieldValue(data, keys);
  return value is String ? value : fallback;
}

bool boolField(
  Map<String, dynamic> data,
  List<String> keys, {
  bool fallback = false,
}) {
  final value = fieldValue(data, keys);
  return value is bool ? value : fallback;
}

double doubleField(
  Map<String, dynamic> data,
  List<String> keys, {
  double fallback = 0,
}) {
  final value = fieldValue(data, keys);
  return value is num ? value.toDouble() : fallback;
}

DateTime dateTimeField(
  Map<String, dynamic> data,
  List<String> keys, {
  DateTime? fallback,
}) {
  final value = fieldValue(data, keys);
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0);
}
