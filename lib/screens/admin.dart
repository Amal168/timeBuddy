import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timebuddy/model.dart';
import 'package:timebuddy/screens/login.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildMentorsStudentsTab(),
      _buildScheduleTab(),
      _buildTasksTab(),
      _buildNotificationsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginPage()));
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Mentors',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showCreateScheduleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            )
          : _currentIndex == 2
              ? FloatingActionButton.extended(
                  onPressed: _showCreateTaskDialog,
                  icon: const Icon(Icons.add_task),
                  label: const Text('Assign'),
                )
              : null,
    );
  }

  Widget _buildMentorsStudentsTab() {
    return StreamBuilder<List<Mentor>>(
      stream: fireRepo.mentorsStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final mentors = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            itemCount: mentors.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2.4,
            ),
            itemBuilder: (_, i) => _mentorCard(mentors[i]),
          ),
        );
      },
    );
  }

  Widget _mentorCard(Mentor mentor) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            child: Text(mentor.name
                .split(' ')
                .where((e) => e.isNotEmpty)
                .map((e) => e[0])
                .take(2)
                .join()),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mentor.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16)),
                Text(mentor.email, style: _muted),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: -4,
                  children: mentor.teachingCourses
                      .map((c) => Chip(
                            label: Text(c),
                            backgroundColor: Colors.blue.shade50,
                          ))
                      .toList(),
                ),
                const Spacer(),
                Text('${mentor.studentIds.length} students assigned',
                    style: _muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* ---------- Schedule ---------- */
  Widget _buildScheduleTab() {
    return StreamBuilder<List<Schedule>>(
      stream: fireRepo.schedulesStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final schedules = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemBuilder: (_, i) => _scheduleTile(schedules[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: schedules.length,
          ),
        );
      },
    );
  }

  Widget _scheduleTile(Schedule s) {
    return Container(
      decoration: _cardDeco(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(s.courseName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(s.formattedTime, style: _muted),
        ),
        trailing: Chip(
          label: Text(s.statusText),
          backgroundColor: switch (s.status) {
            ScheduleStatus.scheduled => Colors.green.shade100,
            ScheduleStatus.cancelled => Colors.red.shade100,
            ScheduleStatus.rescheduled => Colors.orange.shade100,
          },
        ),
      ),
    );
  }

  /* ---------- Tasks ---------- */
  Widget _buildTasksTab() {
    return StreamBuilder<List<Task>>(
      stream: fireRepo.tasksStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final tasks = snap.data ?? [];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemBuilder: (_, i) => _taskTile(tasks[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: tasks.length,
          ),
        );
      },
    );
  }

  Widget _taskTile(Task t) {
    return Container(
      decoration: _cardDeco(),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(t.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Course: ${t.courseName}', style: _muted),
              Text('Assigned to: ${t.assignedTo}', style: _muted),
              Text(
                'Deadline: ${DateFormat('MMM dd, yyyy').format(t.deadline)}',
                style: t.isOverdue
                    ? const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.w700)
                    : _muted,
              ),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Chip(
              label: Text(t.statusText),
              backgroundColor: switch (t.status) {
                TaskStatus.pending => Colors.orange.shade100,
                TaskStatus.inProgress => Colors.blue.shade100,
                TaskStatus.completed => Colors.green.shade100,
              },
            ),
            if (t.isOverdue)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('OVERDUE',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  /* ---------- Notifications ---------- */
  Widget _buildNotificationsTab() {
    return StreamBuilder<List<AppNotification>>(
      stream: fireRepo.notificationsStream(userRole: 'admin'),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final notifications = snap.data ?? [];
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (_, i) {
            final n = notifications[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: _cardDeco(),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: switch (n.type) {
                    NotificationType.scheduleCancelled => Colors.red,
                    NotificationType.scheduleRescheduled => Colors.orange,
                    NotificationType.taskAssigned => Colors.blue,
                  },
                  child: Icon(
                    switch (n.type) {
                      NotificationType.scheduleCancelled => Icons.cancel,
                      NotificationType.scheduleRescheduled => Icons.schedule,
                      NotificationType.taskAssigned => Icons.assignment,
                    },
                    color: Colors.white,
                  ),
                ),
                title: Text(n.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.message),
                    const SizedBox(height: 4),
                    Text(n.timeAgo, style: _muted),
                  ],
                ),
                trailing: n.isRead
                    ? null
                    : const Icon(Icons.fiber_manual_record,
                        color: Colors.red, size: 12),
                onTap: () {
                  FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(n.id)
                      .update({'isRead': true});
                },
              ),
            );
          },
        );
      },
    );
  }

  /* ---------- Dialogs (write to Firestore) ---------- */

  void _showCreateScheduleDialog() {
    final courseCtrl = TextEditingController();
    final studentCtrl = TextEditingController();
    DateTime? when;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Schedule'),
        content: StatefulBuilder(
          builder: (ctx, setS) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: courseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Course (e.g., Flutter)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: studentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Student Name or Id',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    when == null
                        ? 'Pick Date & Time'
                        : DateFormat('EEE, MMM d • h:mm a').format(when!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date == null) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 10, minute: 0),
                    );
                    if (time == null) return;
                    setS(() => when = DateTime(date.year, date.month, date.day,
                        time.hour, time.minute));
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (courseCtrl.text.isEmpty ||
                  studentCtrl.text.isEmpty ||
                  when == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill all fields')));
                return;
              }
              await fireRepo.createSchedule(
                Schedule(
                  id: 'tmp',
                  courseName: courseCtrl.text.trim(),
                  mentorId: '1',
                  studentId: studentCtrl.text.trim(), // or uid mapping
                  scheduledTime: when!,
                ),
              );
              await fireRepo.addNotification(
                AppNotification(
                  id: 'tmp',
                  title: 'New Schedule',
                  message:
                      '${studentCtrl.text.trim()} scheduled ${courseCtrl.text.trim()}',
                  type: NotificationType.taskAssigned,
                  timestamp: DateTime.now(),
                ),
              );
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showCreateTaskDialog() {
    final name = TextEditingController();
    final course = TextEditingController();
    final assignedTo = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Assign Task'),
        content: StatefulBuilder(
          builder: (ctx, setS) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Task name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: course,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: assignedTo,
                  decoration: const InputDecoration(
                    labelText: 'Assign to (student)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    deadline == null
                        ? 'Pick Deadline'
                        : DateFormat('MMM dd, yyyy').format(deadline!),
                  ),
                  trailing: const Icon(Icons.event),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                    );
                    if (date != null) setS(() => deadline = date);
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (name.text.isEmpty ||
                  course.text.isEmpty ||
                  assignedTo.text.isEmpty ||
                  deadline == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fill all fields')));
                return;
              }
              await fireRepo.addTask(
                Task(
                  id: 'tmp',
                  name: name.text.trim(),
                  courseName: course.text.trim(),
                  assignedTo: assignedTo.text.trim(),
                  deadline: deadline!,
                ),
              );
              await fireRepo.addNotification(
                AppNotification(
                  id: 'tmp',
                  title: 'Task Assigned',
                  message:
                      '${assignedTo.text.trim()} → ${name.text.trim()} (${course.text.trim()})',
                  type: NotificationType.taskAssigned,
                  timestamp: DateTime.now(),
                ),
              );
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      );

  TextStyle get _muted => TextStyle(color: Colors.grey.shade600, fontSize: 13);
}
