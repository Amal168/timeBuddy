import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timebuddy/model.dart';
import 'package:timebuddy/screens/login.dart';

class InternDashboard extends StatefulWidget {
  const InternDashboard({super.key});

  @override
  State<InternDashboard> createState() => _InternDashboardState();
}

class _InternDashboardState extends State<InternDashboard> {
  int _currentIndex = 0;
  String _selectedCourse = 'Flutter';

  final List<String> _enrolledCourses = [
    'Flutter',
    'UI/UX',
    'Backend Development'
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [_schedulePage(), _tasksPage()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intern Dashboard'),
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
              icon: Icon(Icons.schedule_outlined), label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
        ],
      ),
    );
  }

  /* ---------- Schedule ---------- */
  Widget _schedulePage() {
    // NOTE: in real apps, use current UID. For demo, we filter by a placeholder "1".
    final studentId = FirebaseAuth.instance.currentUser?.uid ?? '1';
    return StreamBuilder<List<Schedule>>(
      stream: fireRepo.schedulesStream(
          course: _selectedCourse, studentId: studentId),
      builder: (context, snap) {
        final courseSchedules = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x11000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Course',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCourse,
                      items: _enrolledCourses
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCourse = v!),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Schedules for $_selectedCourse',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (courseSchedules.isEmpty)
                Container(
                  width: double.infinity,
                  decoration: _cardDeco(),
                  padding: const EdgeInsets.all(24),
                  child: const Center(
                    child: Text('No schedules found for this course',
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                ...courseSchedules.map(_scheduleCard),
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleCard(Schedule s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.courseName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(s.formattedTime,
                  style: TextStyle(color: Colors.grey.shade600)),
            ]),
            Chip(
              label: Text(s.statusText),
              backgroundColor: switch (s.status) {
                ScheduleStatus.scheduled => Colors.green.shade100,
                ScheduleStatus.cancelled => Colors.red.shade100,
                ScheduleStatus.rescheduled => Colors.orange.shade100,
              },
            ),
          ]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: const Text('Reschedule'),
                  onPressed: () => _showRescheduleDialog(s),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  onPressed: () => _showCancelDialog(s),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ---------- Tasks ---------- */
  Widget _tasksPage() {
    final assignedTo =
        FirebaseAuth.instance.currentUser?.email ?? 'user@example.com';
    return StreamBuilder<List<Task>>(
      stream: fireRepo.tasksStream(assignedTo: assignedTo),
      builder: (context, snap) {
        final tasks = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemBuilder: (_, i) => _taskCard(tasks[i]),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: tasks.length,
          ),
        );
      },
    );
  }

  Widget _taskCard(Task t) {
    return Container(
      decoration: _cardDeco(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Course: ${t.courseName}', style: _muted),
              const SizedBox(height: 4),
              Text('Deadline: ${DateFormat('MMM dd, yyyy').format(t.deadline)}',
                  style: t.isOverdue
                      ? const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.w700)
                      : _muted),
            ]),
          ),
          Column(children: [
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
          ]),
        ]),
        const SizedBox(height: 12),
        if (t.status != TaskStatus.completed)
          Row(children: [
            if (t.status == TaskStatus.pending)
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Task'),
                  onPressed: () =>
                      _updateTaskStatus(t.id, TaskStatus.inProgress),
                ),
              ),
            if (t.status == TaskStatus.inProgress) ...[
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Mark Complete'),
                  onPressed: () =>
                      _updateTaskStatus(t.id, TaskStatus.completed),
                ),
              ),
            ],
          ]),
      ]),
    );
  }

  /* ---------- Intern Actions (Firestore updates) ---------- */

  void _showRescheduleDialog(Schedule s) {
    DateTime? when;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reschedule Session'),
        content: StatefulBuilder(
          builder: (ctx, setS) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  when == null
                      ? 'Pick Date & Time'
                      : DateFormat('EEE, MMM d • h:mm a').format(when!),
                ),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final date = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null) return;
                  final time = await showTimePicker(
                    context: ctx,
                    initialTime: TimeOfDay.fromDateTime(s.scheduledTime),
                  );
                  if (time == null) return;
                  setS(() => when = DateTime(
                      date.year, date.month, date.day, time.hour, time.minute));
                },
              ),
              const SizedBox(height: 8),
              const Text('Admin will be notified on changes.',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (when == null) return;
              await fireRepo.updateSchedule(s.id, {
                'scheduledTime': Timestamp.fromDate(when!),
                'status': ScheduleStatus.rescheduled.name,
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Session rescheduled. Admin notified.')));
              Navigator.pop(context);
            },
            child: const Text('Reschedule'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(Schedule s) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason (optional):'),
            const SizedBox(height: 8),
            TextField(
              controller: reason,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Reason for cancellation',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No, Keep')),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.cancel),
            label: const Text('Yes, Cancel'),
            onPressed: () async {
              await fireRepo.updateSchedule(s.id, {
                'status': ScheduleStatus.cancelled.name,
                'cancelReason': reason.text.trim(),
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Session cancelled${reason.text.isNotEmpty ? ' • ${reason.text}' : ''}. Admin notified.'),
                backgroundColor: Colors.orange,
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskStatus(String id, TaskStatus status) async {
    await fireRepo.updateTask(id, {'status': status.name});
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Task status: ${status.name}')));
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
