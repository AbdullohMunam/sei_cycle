import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/firestore_collections.dart';
import '../../../core/utils/firestore_validators.dart';
import '../models/finance_record.dart';

class FinanceService {
  FinanceService({FirebaseFirestore? firestore, Uuid? uuid})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _uuid = uuid ?? const Uuid();

  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  static const _validTypes = {'income', 'expense'};

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestoreCollections.financeTransactions);

  Stream<List<FinanceRecord>> watchRecords() {
    return _collection
        .where('isDeleted', isEqualTo: false)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(FinanceRecord.fromDocument).toList(),
        );
  }

  Future<FinanceSummary> loadCurrentMonthSummary({DateTime? now}) {
    final anchor = now ?? DateTime.now();
    final start = DateTime(anchor.year, anchor.month);
    final end = DateTime(anchor.year, anchor.month + 1);
    return loadSummaryByDateRange(start: start, end: end);
  }

  Future<FinanceSummary> loadSummaryByDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    _validateDateRange(start: start, end: end);
    final snapshot = await _collection
        .where('isDeleted', isEqualTo: false)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .get();
    return cashflowSummary(
      snapshot.docs.map(FinanceRecord.fromDocument),
      start: start,
      end: end,
    );
  }

  FinanceSummary monthlyProfitLossFromRecords(
    Iterable<FinanceRecord> records, {
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    return monthlyProfitLoss(records, month: anchor);
  }

  Future<void> save({
    String? id,
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    required String note,
    String paymentMethod = '',
    String moduleType = '',
    required String userId,
  }) async {
    final normalizedType = type.trim().toLowerCase();
    _validateSave(
      type: normalizedType,
      category: category,
      amount: amount,
      date: date,
      userId: userId,
    );

    final documentId = id ?? _uuid.v4();
    final now = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      'id': documentId,
      'type': normalizedType,
      'category': category.trim(),
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'description': note.trim(),
      'notes': note.trim(),
      'paymentMethod': paymentMethod.trim(),
      'moduleType': moduleType.trim(),
      'updatedBy': userId,
      'updatedAt': now,
      'isDeleted': false,
    };
    if (id == null) {
      data['createdBy'] = userId;
      data['createdAt'] = now;
    }
    await _collection.doc(documentId).set(data, SetOptions(merge: true));
  }

  Future<void> delete(String id, {required String userId}) {
    requireTrimmed(id, 'id');
    requireTrimmed(userId, 'userId');
    return _collection.doc(id).update({
      'isDeleted': true,
      'updatedBy': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _validateSave({
    required String type,
    required String category,
    required double amount,
    required DateTime date,
    required String userId,
  }) {
    requireOneOf(type, _validTypes, 'type');
    requireTrimmed(category, 'category');
    requirePositive(amount, 'amount');
    _requireValidDate(date, 'date');
    requireTrimmed(userId, 'userId');
  }

  static FinanceSummary monthlyProfitLoss(
    Iterable<FinanceRecord> records, {
    required DateTime month,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return cashflowSummary(records, start: start, end: end);
  }

  static FinanceSummary cashflowSummary(
    Iterable<FinanceRecord> records, {
    required DateTime start,
    required DateTime end,
  }) {
    _validateDateRange(start: start, end: end);
    final activeRecords = records.where((record) {
      return !record.isDeleted &&
          !record.date.isBefore(start) &&
          record.date.isBefore(end);
    }).toList();

    final byCategory = <String, FinanceCategorySummary>{};
    var totalIncome = 0.0;
    var totalExpense = 0.0;

    for (final record in activeRecords) {
      if (record.type == 'income') {
        totalIncome += record.amount;
      } else if (record.type == 'expense') {
        totalExpense += record.amount;
      }

      final key = record.category.trim().isEmpty
          ? 'Tanpa kategori'
          : record.category.trim();
      byCategory[key] = (byCategory[key] ?? FinanceCategorySummary.empty(key))
          .add(record);
    }

    return FinanceSummary(
      start: start,
      end: end,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      byCategory: Map.unmodifiable(byCategory),
      transactions: List.unmodifiable(activeRecords),
    );
  }

  static void _validateDateRange({
    required DateTime start,
    required DateTime end,
  }) {
    _requireValidDate(start, 'start');
    _requireValidDate(end, 'end');
    if (!end.isAfter(start)) {
      throw ArgumentError.value(end, 'end', 'end harus setelah start.');
    }
  }

  static void _requireValidDate(DateTime value, String fieldName) {
    if (value.year < 1900 || value.year > 2200) {
      throw ArgumentError.value(value, fieldName, '$fieldName tidak valid.');
    }
  }
}

class FinanceSummary {
  const FinanceSummary({
    required this.start,
    required this.end,
    required this.totalIncome,
    required this.totalExpense,
    required this.byCategory,
    required this.transactions,
  });

  final DateTime start;
  final DateTime end;
  final double totalIncome;
  final double totalExpense;
  final Map<String, FinanceCategorySummary> byCategory;
  final List<FinanceRecord> transactions;

  double get netProfit => totalIncome - totalExpense;
}

class FinanceCategorySummary {
  const FinanceCategorySummary({
    required this.category,
    required this.income,
    required this.expense,
    required this.count,
  });

  factory FinanceCategorySummary.empty(String category) {
    return FinanceCategorySummary(
      category: category,
      income: 0,
      expense: 0,
      count: 0,
    );
  }

  final String category;
  final double income;
  final double expense;
  final int count;

  double get netProfit => income - expense;

  FinanceCategorySummary add(FinanceRecord record) {
    return FinanceCategorySummary(
      category: category,
      income: income + (record.type == 'income' ? record.amount : 0),
      expense: expense + (record.type == 'expense' ? record.amount : 0),
      count: count + 1,
    );
  }
}
