import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Mentor {
  final String id;
  final String name;
  final String email;
  final List<String> teachingCourses;
  final List<String> studentIds;

  Mentor({
    required this.id,
    required this.name,
    required this.email,
    required this.teachingCourses,
    required this.studentIds, required String availableTime,
  });
}

enum ScheduleStatus { scheduled, cancelled, rescheduled }

class Schedule {
  final String id;
  final String courseName;
  final String mentorId;
  final String studentId;
  DateTime scheduledTime;
  ScheduleStatus status;

  Schedule({
    required this.id,
    required this.courseName,
    required this.mentorId,
    required this.studentId,
    required this.scheduledTime,
    this.status = ScheduleStatus.scheduled,
  });

  String get formattedTime =>
      DateFormat('EEE, MMM d • h:mm a').format(scheduledTime);
  String get statusText => switch (status) {
        ScheduleStatus.scheduled => 'Scheduled',
        ScheduleStatus.cancelled => 'Cancelled',
        ScheduleStatus.rescheduled => 'Rescheduled',
      };
}

enum TaskStatus { pending, inProgress, completed }

class Task {
  final String id;
  final String name;
  final String courseName;
  final String assignedTo; // display name or email
  final DateTime deadline;
  final String? description;
  TaskStatus status;

  Task({
    required this.id,
    required this.name,
    required this.courseName,
    required this.assignedTo,
    required this.deadline,
    this.status = TaskStatus.pending,
    this.description,
  });

  String get statusText => switch (status) {
        TaskStatus.pending => 'Pending',
        TaskStatus.inProgress => 'In Progress',
        TaskStatus.completed => 'Completed',
      };

  bool get isOverdue =>
      status != TaskStatus.completed &&
      DateTime.now()
          .isAfter(deadline.add(const Duration(hours: 23, minutes: 59)));
}

enum NotificationType { scheduleCancelled, scheduleRescheduled, taskAssigned }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

/* ========================= MODEL MAPPERS (FIRESTORE) ========================= */

extension MentorX on Mentor {
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'teachingCourses': teachingCourses,
        'studentIds': studentIds,
      };

  static Mentor fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Mentor(
      id: doc.id,
      name: d['name'] ?? '',
      email: d['email'] ?? '',
      teachingCourses: List<String>.from(d['teachingCourses'] ?? []),
      studentIds: List<String>.from(d['studentIds'] ?? []), availableTime: '',
    );
  }
}

extension ScheduleX on Schedule {
  Map<String, dynamic> toMap() => {
        'courseName': courseName,
        'mentorId': mentorId,
        'studentId': studentId,
        'scheduledTime': Timestamp.fromDate(scheduledTime),
        'status': status.name,
      };

  static Schedule fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      courseName: d['courseName'] ?? '',
      mentorId: d['mentorId'] ?? '',
      studentId: d['studentId'] ?? '',
      scheduledTime: (d['scheduledTime'] as Timestamp).toDate(),
      status: ScheduleStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'scheduled'),
        orElse: () => ScheduleStatus.scheduled,
      ),
    );
  }
}

extension TaskX on Task {
  Map<String, dynamic> toMap() => {
        'name': name,
        'courseName': courseName,
        'assignedTo': assignedTo,
        'deadline': Timestamp.fromDate(deadline),
        'status': status.name,
        'description': description,
      };

  static Task fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return Task(
      id: doc.id,
      name: d['name'] ?? '',
      courseName: d['courseName'] ?? '',
      assignedTo: d['assignedTo'] ?? '',
      deadline: (d['deadline'] as Timestamp).toDate(),
      status: TaskStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pending'),
        orElse: () => TaskStatus.pending,
      ),
      description: d['description'],
    );
  }
}

extension AppNotificationX on AppNotification {
  Map<String, dynamic> toMap() => {
        'title': title,
        'message': message,
        'type': type.name,
        'timestamp': Timestamp.fromDate(timestamp),
        'isRead': isRead,
        // optional targeting fields:
        // 'userRole': 'admin' | 'intern',
        // 'userId': 'uid',
      };

  static AppNotification fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (d['type'] ?? 'taskAssigned'),
        orElse: () => NotificationType.taskAssigned,
      ),
      timestamp: (d['timestamp'] as Timestamp).toDate(),
      isRead: d['isRead'] ?? false,
    );
  }
}

/* ========================= REPOSITORY ========================= */

class FireRepo {
  final _db = FirebaseFirestore.instance;

  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?);
  }

  // Mentors
  Stream<List<Mentor>> mentorsStream() => _db
      .collection('mentors')
      .snapshots()
      .map((s) => s.docs.map(MentorX.fromDoc).toList());

  // Schedules
  Stream<List<Schedule>> schedulesStream({String? course, String? studentId}) {
    Query q = _db.collection('schedules');
    if (course != null) q = q.where('courseName', isEqualTo: course);
    if (studentId != null) q = q.where('studentId', isEqualTo: studentId);
    return q.orderBy('scheduledTime').snapshots().map(
          (s) => s.docs.map(ScheduleX.fromDoc).toList(),
        );
  }

  Future<void> createSchedule(Schedule s) async {
    await _db.collection('schedules').add(s.toMap());
  }

  Future<void> updateSchedule(String id, Map<String, dynamic> data) async {
    await _db.collection('schedules').doc(id).update(data);
  }

  // Tasks
  Stream<List<Task>> tasksStream({String? assignedTo}) {
    Query q = _db.collection('tasks');
    if (assignedTo != null) q = q.where('assignedTo', isEqualTo: assignedTo);
    return q.orderBy('deadline').snapshots().map(
          (s) => s.docs.map(TaskX.fromDoc).toList(),
        );
  }

  Future<void> addTask(Task t) async {
    await _db.collection('tasks').add(t.toMap());
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    await _db.collection('tasks').doc(id).update(data);
  }

  // Notifications
  Stream<List<AppNotification>> notificationsStream(
      {String? userRole, String? userId}) {
    Query q =
        _db.collection('notifications').orderBy('timestamp', descending: true);
    if (userRole != null) q = q.where('userRole', isEqualTo: userRole);
    if (userId != null) q = q.where('userId', isEqualTo: userId);
    return q.snapshots().map(
          (s) => s.docs.map(AppNotificationX.fromDoc).toList(),
        );
  }

  Future<void> addNotification(AppNotification n) async {
    await _db.collection('notifications').add(n.toMap());
  }
}

final fireRepo = FireRepo();

/* ========================= LOGIN ========================= */

enum UserRole { admin, intern }

