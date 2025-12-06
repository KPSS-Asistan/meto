import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore batch operations service
/// Toplu işlemleri optimize eder
class BatchService {
  static final BatchService _instance = BatchService._internal();
  factory BatchService() => _instance;
  BatchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Batch write (max 500 operation)
  Future<void> batchWrite(
    List<BatchOperation> operations, {
    int chunkSize = 500,
  }) async {
    if (operations.isEmpty) return;

    // 500'lük chunk'lara böl
    for (var i = 0; i < operations.length; i += chunkSize) {
      final chunk = operations.skip(i).take(chunkSize).toList();
      final batch = _firestore.batch();

      for (final op in chunk) {
        switch (op.type) {
          case BatchOperationType.set:
            batch.set(op.ref, op.data!, SetOptions(merge: op.merge));
            break;
          case BatchOperationType.update:
            batch.update(op.ref, op.data!);
            break;
          case BatchOperationType.delete:
            batch.delete(op.ref);
            break;
        }
      }

      await batch.commit();
    }
  }

  /// Batch read (paralel okuma)
  Future<List<DocumentSnapshot>> batchRead(
    List<DocumentReference> refs, {
    int parallelLimit = 10,
  }) async {
    if (refs.isEmpty) return [];

    final results = <DocumentSnapshot>[];
    
    // Paralel okuma (10'lu gruplar)
    for (var i = 0; i < refs.length; i += parallelLimit) {
      final chunk = refs.skip(i).take(parallelLimit).toList();
      final futures = chunk.map((ref) => ref.get()).toList();
      final chunkResults = await Future.wait(futures);
      results.addAll(chunkResults);
    }

    return results;
  }

  /// Bulk update (aynı collection'da toplu güncelleme)
  Future<void> bulkUpdate(
    String collectionPath,
    Map<String, Map<String, dynamic>> updates, {
    int chunkSize = 500,
  }) async {
    if (updates.isEmpty) return;

    final operations = updates.entries.map((entry) {
      final ref = _firestore.collection(collectionPath).doc(entry.key);
      return BatchOperation.update(ref, entry.value);
    }).toList();

    await batchWrite(operations, chunkSize: chunkSize);
  }

  /// Bulk delete (toplu silme)
  Future<void> bulkDelete(
    String collectionPath,
    List<String> docIds, {
    int chunkSize = 500,
  }) async {
    if (docIds.isEmpty) return;

    final operations = docIds.map((id) {
      final ref = _firestore.collection(collectionPath).doc(id);
      return BatchOperation.delete(ref);
    }).toList();

    await batchWrite(operations, chunkSize: chunkSize);
  }

  /// Transaction wrapper (retry logic ile)
  Future<T> runTransaction<T>(
    Future<T> Function(Transaction) transactionHandler, {
    int maxAttempts = 5,
  }) async {
    return await _firestore.runTransaction(
      transactionHandler,
      maxAttempts: maxAttempts,
    );
  }
}

/// Batch operation types
enum BatchOperationType { set, update, delete }

/// Batch operation model
class BatchOperation {
  final BatchOperationType type;
  final DocumentReference ref;
  final Map<String, dynamic>? data;
  final bool merge;

  BatchOperation._({
    required this.type,
    required this.ref,
    this.data,
    this.merge = false,
  });

  factory BatchOperation.set(
    DocumentReference ref,
    Map<String, dynamic> data, {
    bool merge = false,
  }) {
    return BatchOperation._(
      type: BatchOperationType.set,
      ref: ref,
      data: data,
      merge: merge,
    );
  }

  factory BatchOperation.update(
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    return BatchOperation._(
      type: BatchOperationType.update,
      ref: ref,
      data: data,
    );
  }

  factory BatchOperation.delete(DocumentReference ref) {
    return BatchOperation._(
      type: BatchOperationType.delete,
      ref: ref,
    );
  }
}
