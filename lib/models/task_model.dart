/// Task model - used by both SQLite and Firestore.
class TaskModel {
  final String id;
  final String uid;
  String title;
  String description;
  bool isDone;
  final int createdAt;
  int updatedAt;
  bool isSynced; // local only: pushed to Firestore or not
  bool isDeleted; // local only: pending remote deletion

  TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    this.isDone = false,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  /// Convert to SQLite row.
  Map<String, dynamic> toMap() => {
        'id': id,
        'uid': uid,
        'title': title,
        'description': description,
        'isDone': isDone ? 1 : 0,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isSynced': isSynced ? 1 : 0,
        'isDeleted': isDeleted ? 1 : 0,
      };

  /// Create from SQLite row.
  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: map['id'] as String,
        uid: map['uid'] as String,
        title: map['title'] as String,
        description: map['description'] as String? ?? '',
        isDone: (map['isDone'] as int) == 1,
        createdAt: map['createdAt'] as int,
        updatedAt: map['updatedAt'] as int,
        isSynced: (map['isSynced'] as int) == 1,
        isDeleted: (map['isDeleted'] as int) == 1,
      );

  /// Convert to Firestore document (sync flags are local only).
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'isDone': isDone,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  /// Create from Firestore document.
  factory TaskModel.fromFirestore(
          String id, String uid, Map<String, dynamic> data) =>
      TaskModel(
        id: id,
        uid: uid,
        title: data['title'] as String? ?? '',
        description: data['description'] as String? ?? '',
        isDone: data['isDone'] as bool? ?? false,
        createdAt: data['createdAt'] as int? ?? 0,
        updatedAt: data['updatedAt'] as int? ?? 0,
        isSynced: true,
      );
}
