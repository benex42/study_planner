import 'package:flutter/material.dart';

import 'floating_tab_bar.dart';
import 'study_hub_app_bar.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key, this.onThemeToggle, this.embedded = false});

  final VoidCallback? onThemeToggle;
  final bool embedded;

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();
  final Set<String> _completed = {'Lab Report: Distillation'};
  final List<_TaskGroupData> _taskGroups = [
    _TaskGroupData(
      title: 'Advanced Mathematics',
      accent: const Color(0xFF066ABB),
      total: 4,
      tasks: [
        const _TaskData(
          'Complete Fourier Series',
          'Oct 24, 2023   •   15:00',
          'HIGH',
        ),
        const _TaskData('Matrix Calculus Problems', 'Oct 26, 2023', 'MEDIUM'),
      ],
    ),
    _TaskGroupData(
      title: 'Organic Chemistry',
      accent: const Color(0xFF2F718E),
      total: 2,
      tasks: [
        const _TaskData('Lab Report: Distillation', 'Completed', 'LOW'),
        const _TaskData('Mechanism Exercise', 'Today', 'HIGH'),
      ],
    ),
    _TaskGroupData(
      title: 'Modern Philosophy',
      accent: const Color(0xFF50616C),
      total: 1,
      tasks: [
        const _TaskData(
          "Essay: Kant's Categorical Imperative",
          'Oct 30, 2023',
          'MEDIUM',
        ),
      ],
    ),
  ];
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addTask() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _AddTaskDialog(
        onSaved: (task) {
          _saveTask(task);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${task.subject} added.')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final body = Column(
      children: [
        if (!widget.embedded) const StudyHubAppBar(),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              24,
              16,
              // The dashboard navigation overlays this content when embedded,
              // allowing its pill-shaped edge to cross the task cards.
              widget.embedded ? 16 : 28,
            ),
            children: [
              _TaskSearchField(
                controller: _searchController,
                isDark: isDark,
                onChanged: (value) =>
                    setState(() => _query = value.toLowerCase()),
              ),
              const SizedBox(height: 23),
              const _TaskSummaryCards(),
              const SizedBox(height: 22),
              ..._taskGroups.map(
                (group) => _SubjectGroup(
                  title: group.title,
                  accent: group.accent,
                  total: group.total,
                  tasks: group.tasks,
                  query: _query,
                  completed: _completed,
                  isDark: isDark,
                  onChanged: _setTaskCompletion,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final addButton = DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x66033E6B),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _addTask,
        backgroundColor: const Color(0xFF0569BC),
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 2,
        tooltip: 'Add task',
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 31),
      ),
    );
    if (widget.embedded) {
      return Stack(
        children: [
          body,
          Positioned(right: 22, bottom: 100, child: addButton),
        ],
      );
    }
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF11161D)
          : const Color(0xFFF9FAFC),
      body: SafeArea(child: body),
      floatingActionButton: addButton,
    );
  }

  void _setTaskCompletion(String title, bool selected) {
    setState(() {
      if (selected) {
        _completed.add(title);
      } else {
        _completed.remove(title);
      }
    });
  }

  void _saveTask(_NewTaskInput task) {
    const accents = [
      Color(0xFF066ABB),
      Color(0xFF2F718E),
      Color(0xFF50616C),
      Color(0xFF8057A9),
    ];
    setState(() {
      final groupIndex = _taskGroups.indexWhere(
        (group) => group.title.toLowerCase() == task.course.toLowerCase(),
      );
      final taskData = _TaskData(task.subject, task.detail, task.importance);
      if (groupIndex >= 0) {
        _taskGroups[groupIndex].tasks.add(taskData);
        _taskGroups[groupIndex].total++;
      } else {
        _taskGroups.add(
          _TaskGroupData(
            title: task.course,
            accent: accents[_taskGroups.length % accents.length],
            total: 1,
            tasks: [taskData],
          ),
        );
      }
    });
  }
}

class _AddTaskDialog extends StatefulWidget {
  const _AddTaskDialog({required this.onSaved});

  final ValueChanged<_NewTaskInput> onSaved;

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  final _subjectController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;
  String _importance = 'Medium';

  @override
  void dispose() {
    _courseController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _date ?? DateTime.now(),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add task',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF22262C),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _courseController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Course',
                    border: border,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Course is required.'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subjectController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    border: border,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Subject is required.'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _PickerField(
                        label: 'Date',
                        value: _date == null
                            ? null
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_date!),
                        icon: Icons.calendar_today_outlined,
                        onTap: _selectDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerField(
                        label: 'Time',
                        value: _time == null
                            ? null
                            : MaterialLocalizations.of(
                                context,
                              ).formatTimeOfDay(_time!),
                        icon: Icons.access_time_rounded,
                        onTap: _selectTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _importance,
                  decoration: InputDecoration(
                    labelText: 'Importance level',
                    border: border,
                  ),
                  items: const ['Low', 'Medium', 'High']
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _importance = value!),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {
                        if (!_formKey.currentState!.validate()) return;
                        final date = _date == null
                            ? null
                            : MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(_date!);
                        final time = _time == null
                            ? null
                            : MaterialLocalizations.of(
                                context,
                              ).formatTimeOfDay(_time!);
                        final detail = [
                          date,
                          time,
                        ].whereType<String>().join('   •   ');
                        Navigator.of(context).pop();
                        widget.onSaved(
                          _NewTaskInput(
                            course: _courseController.text.trim(),
                            subject: _subjectController.text.trim(),
                            detail: detail.isEmpty ? 'No due date' : detail,
                            importance: _importance.toUpperCase(),
                          ),
                        );
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: Icon(icon, size: 19),
      ),
      child: Text(value ?? 'Select', overflow: TextOverflow.ellipsis),
    ),
  );
}

class _TaskSearchField extends StatelessWidget {
  const _TaskSearchField({
    required this.controller,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 16),
    decoration: InputDecoration(
      hintText: 'Search tasks, subjects, or deadlines...',
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF9BA9BA) : const Color(0xFF7D8797),
      ),
      prefixIcon: const Icon(Icons.search_rounded),
      filled: true,
      fillColor: isDark ? const Color(0xFF1C2530) : const Color(0xFFF8F9FC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      border: _outline(isDark),
      enabledBorder: _outline(isDark),
      focusedBorder: _outline(isDark, const Color(0xFF0569BC)),
    ),
  );

  OutlineInputBorder _outline(bool isDark, [Color? color]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color:
              color ??
              (isDark ? const Color(0xFF3B4757) : const Color(0xFFC9D1DD)),
        ),
      );
}

class _TaskSummaryCards extends StatelessWidget {
  const _TaskSummaryCards();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        _SummaryCard(
          title: 'Total Tasks',
          icon: Icons.assignment_outlined,
          isDark: isDark,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '24',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                '+4 from yesterday',
                style: TextStyle(color: Color(0xFF788292), fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: 'Due Today',
          icon: Icons.event_busy_outlined,
          urgent: true,
          isDark: isDark,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '03',
                style: TextStyle(
                  color: Color(0xFFD31D28),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Submit by 11:59 PM',
                style: TextStyle(color: Color(0xFFBD2930), fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SummaryCard(
          title: 'Completion Rate',
          icon: Icons.analytics_outlined,
          isDark: isDark,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '78%',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  value: .78,
                  minHeight: 7,
                  color: Color(0xFF0569BC),
                  backgroundColor: Color(0xFFBCE1FC),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.isDark,
    this.urgent = false,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final bool isDark;
  final bool urgent;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF1C2530) : Colors.white,
      borderRadius: appSurfaceBorderRadius,
      border: Border.all(
        color: urgent
            ? const Color(0xFFFFD5D5)
            : (isDark ? const Color(0xFF3B4757) : const Color(0xFFCBD3DE)),
        width: .5,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x08000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2A3340),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (urgent) const _UrgentPill(),
            Icon(
              icon,
              color: urgent ? const Color(0xFFD31D28) : const Color(0xFF126A96),
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 13),
        child,
      ],
    ),
  );
}

class _UrgentPill extends StatelessWidget {
  const _UrgentPill();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFFFD8D8),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Action required',
      style: TextStyle(
        color: Color(0xFFB51F28),
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _TaskData {
  const _TaskData(this.title, this.detail, this.priority);
  final String title;
  final String detail;
  final String priority;
}

class _TaskGroupData {
  _TaskGroupData({
    required this.title,
    required this.accent,
    required this.total,
    required this.tasks,
  });

  final String title;
  final Color accent;
  int total;
  final List<_TaskData> tasks;
}

class _NewTaskInput {
  const _NewTaskInput({
    required this.course,
    required this.subject,
    required this.detail,
    required this.importance,
  });

  final String course;
  final String subject;
  final String detail;
  final String importance;
}

class _SubjectGroup extends StatelessWidget {
  const _SubjectGroup({
    required this.title,
    required this.accent,
    required this.total,
    required this.tasks,
    required this.query,
    required this.completed,
    required this.isDark,
    required this.onChanged,
  });
  final String title;
  final Color accent;
  final int total;
  final List<_TaskData> tasks;
  final String query;
  final Set<String> completed;
  final bool isDark;
  final void Function(String, bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = tasks
        .where(
          (task) =>
              query.isEmpty ||
              task.title.toLowerCase().contains(query) ||
              title.toLowerCase().contains(query),
        )
        .toList();
    if (filtered.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 23),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 23,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF22262C),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$total ${total == 1 ? 'Task' : 'Tasks'}',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFB7C2D0)
                      : const Color(0xFF778191),
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...filtered.map(
            (task) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TaskTile(
                task: task,
                complete: completed.contains(task.title),
                isDark: isDark,
                onChanged: (value) => onChanged(task.title, value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.complete,
    required this.isDark,
    required this.onChanged,
  });
  final _TaskData task;
  final bool complete;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? const Color(0xFFB8C2D0) : const Color(0xFF7E8998);
    final priorityColor = switch (task.priority) {
      'HIGH' => const Color(0xFFFFD3D3),
      'MEDIUM' => const Color(0xFFC7E7FC),
      _ => const Color(0xFFE9ECF1),
    };
    final priorityText = switch (task.priority) {
      'HIGH' => const Color(0xFFC92A31),
      'MEDIUM' => const Color(0xFF39728F),
      _ => const Color(0xFF737D8D),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2530) : Colors.white,
        borderRadius: appSurfaceBorderRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF3B4757) : const Color(0xFFCBD3DE),
          width: .5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: complete,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: const Color(0xFF0569BC),
            side: BorderSide(
              color: isDark ? const Color(0xFF8794A5) : const Color(0xFFC3CCD8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          color: complete
                              ? muted
                              : (isDark
                                    ? Colors.white
                                    : const Color(0xFF25282D)),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          decoration: complete
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        task.priority,
                        style: TextStyle(
                          color: priorityText,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Icon(
                      complete
                          ? Icons.check_circle_outline
                          : Icons.calendar_today_outlined,
                      color: complete ? const Color(0xFF1976D2) : muted,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        task.detail,
                        style: TextStyle(
                          color: complete ? const Color(0xFF2876C7) : muted,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
