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
    required this.studentIds,
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