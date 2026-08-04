import 'package:flutter/material.dart';

import 'floating_tab_bar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, this.onThemeToggle, this.embedded = false});

  final VoidCallback? onThemeToggle;
  final bool embedded;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _weekStart = _startOfCalendarWeek(DateTime.now());
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  Future<void> _pickScheduleDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) _selectScheduleDate(selected);
  }

  void _selectScheduleDate(DateTime date) {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _weekStart = _startOfCalendarWeek(_selectedDate);
    });
  }

  void _showAddSessionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddSessionDialog(
        onAdd: () {
          ScaffoldMessenger.of(
            this.context,
          ).showSnackBar(const SnackBar(content: Text('Study session added.')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageColor = isDark
        ? const Color(0xFF11161D)
        : const Color(0xFFF9FAFC);

    final content = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, 18, 16, widget.embedded ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: _ScheduleContent(
                  weekStart: _weekStart,
                  selectedDate: _selectedDate,
                  isDark: isDark,
                  onDateSelected: _selectScheduleDate,
                  onCalendarTap: _pickScheduleDate,
                  onClose: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final pageBody = widget.embedded ? content : SafeArea(child: content);

    final addButton = FloatingActionButton(
      onPressed: _showAddSessionDialog,
      backgroundColor: const Color(0xFF0769BA),
      foregroundColor: Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      tooltip: 'Add study session',
      child: const Icon(Icons.add_rounded, size: 32),
    );

    if (widget.embedded) {
      return Stack(
        children: [
          pageBody,
          Positioned(right: 20, bottom: 100, child: addButton),
        ],
      );
    }

    return Scaffold(
      backgroundColor: pageColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 112),
              child: pageBody,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _ScheduleNavigation(
              isDark: isDark,
              onDestinationSelected: (index) {
                if (index == 0) {
                  Navigator.of(context).pop();
                  return;
                }
                if (index != 1) {
                  const labels = ['Dashboard', 'Schedule', 'Focus', 'Tasks'];
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${labels[index]} selected.')),
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: addButton,
      ),
    );
  }
}

class _AddSessionDialog extends StatefulWidget {
  const _AddSessionDialog({required this.onAdd});

  final VoidCallback onAdd;

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;

  @override
  void dispose() {
    _courseController.dispose();
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

  void _addSession() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop();
    widget.onAdd();
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
                  'Add study session',
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
                Row(
                  children: [
                    Expanded(
                      child: _SessionPickerField(
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
                      child: _SessionPickerField(
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
                      onPressed: _addSession,
                      child: const Text('Add session'),
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

class _SessionPickerField extends StatelessWidget {
  const _SessionPickerField({
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

DateTime _startOfCalendarWeek(DateTime date) {
  final calendarDay = DateUtils.dateOnly(date);
  return calendarDay.subtract(Duration(days: calendarDay.weekday - 1));
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({
    required this.weekStart,
    required this.selectedDate,
    required this.isDark,
    required this.onDateSelected,
    required this.onCalendarTap,
    required this.onClose,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final bool isDark;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onCalendarTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? Colors.white : const Color(0xFF202328);
    final week = List.generate(
      7,
      (index) => weekStart
          .subtract(const Duration(days: 1))
          .add(Duration(days: index)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScheduleTopBar(
          date: selectedDate,
          isDark: isDark,
          onClose: onClose,
          onCalendarTap: onCalendarTap,
        ),
        const SizedBox(height: 27),
        Text(
          'Schedule in your\ncalendar 🗓️',
          style: TextStyle(
            color: primary,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            height: 1.04,
          ),
        ),
        const SizedBox(height: 24),
        _WeekDateStrip(
          dates: week,
          selectedDate: selectedDate,
          isDark: isDark,
          onSelected: onDateSelected,
        ),
        const SizedBox(height: 23),
        _AgendaList(isDark: isDark),
      ],
    );
  }
}

class _ScheduleTopBar extends StatelessWidget {
  const _ScheduleTopBar({
    required this.date,
    required this.isDark,
    required this.onClose,
    required this.onCalendarTap,
  });

  final DateTime date;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onCalendarTap;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1B2632) : Colors.white;
    final iconColor = isDark
        ? const Color(0xFFD8E5F0)
        : const Color(0xFF26323D);
    return Row(
      children: [
        _TopAction(
          icon: Icons.close_rounded,
          tooltip: 'Close schedule',
          color: iconColor,
          surface: surface,
          onTap: onClose,
        ),
        const Spacer(),
        InkWell(
          onTap: onCalendarTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _monthName(date.month),
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined, color: iconColor, size: 17),
              ],
            ),
          ),
        ),
        const Spacer(),
        _TopAction(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          color: iconColor,
          surface: surface,
          onTap: () {},
        ),
      ],
    );
  }
}

class _TopAction extends StatelessWidget {
  const _TopAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.surface,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Material(
      color: surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    ),
  );
}

class _WeekDateStrip extends StatelessWidget {
  const _WeekDateStrip({
    required this.dates,
    required this.selectedDate,
    required this.isDark,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime selectedDate;
  final bool isDark;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final secondary = isDark
        ? const Color(0xFFAEB9C8)
        : const Color(0xFF8C97A4);
    return Row(
      children: [
        for (final date in dates)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(date),
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  children: [
                    Text(
                      _shortWeekday(date.weekday),
                      style: TextStyle(
                        color: secondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DateUtils.isSameDay(date, selectedDate)
                            ? const Color(0xFF0769BA)
                            : isDark
                            ? const Color(0xFF202B37)
                            : const Color(0xFFF2F4F7),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: DateUtils.isSameDay(date, selectedDate)
                              ? Colors.white
                              : isDark
                              ? const Color(0xFFE3EAF1)
                              : const Color(0xFF55606D),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AgendaList extends StatelessWidget {
  const _AgendaList({required this.isDark});

  final bool isDark;

  static const sessions = [
    _AgendaSession(
      time: '8:00 AM',
      title: 'Mathematics',
      detail: 'Today 8:00 AM · Calculus II',
      icon: Icons.functions_rounded,
      color: Color(0xFF0769BA),
      lightBackground: Color(0xFFE5F2FD),
      darkBackground: Color(0xFF193C59),
    ),
    _AgendaSession(
      time: '9:30 AM',
      title: 'Comp Sci',
      detail: 'Today 9:30 AM · Algorithms',
      icon: Icons.mail_outline_rounded,
      color: Color(0xFF8E58D8),
      lightBackground: Color(0xFFF0E8FF),
      darkBackground: Color(0xFF3A2B50),
    ),
    _AgendaSession(
      time: '10:00 AM',
      title: 'Biology',
      detail: 'Today 10:00 AM · Lab report',
      icon: Icons.biotech_outlined,
      color: Color(0xFF25875C),
      lightBackground: Color(0xFFE3F6EC),
      darkBackground: Color(0xFF1F4237),
    ),
    _AgendaSession(
      time: '1:00 PM',
      title: 'Study Group',
      detail: 'Today 1:00 PM · Library Hall',
      icon: Icons.groups_rounded,
      color: Color(0xFF5E7187),
      lightBackground: Color(0xFFEDF1F5),
      darkBackground: Color(0xFF2C3A47),
    ),
    _AgendaSession(
      time: '2:00 PM',
      title: 'Physics',
      detail: 'Today 2:00 PM · Quantum Intro',
      icon: Icons.science_outlined,
      color: Color(0xFFD94D65),
      lightBackground: Color(0xFFFFE9ED),
      darkBackground: Color(0xFF4A2931),
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final session in sessions) ...[
        _AgendaRow(session: session, isDark: isDark),
        if (session != sessions.last) const SizedBox(height: 18),
      ],
    ],
  );
}

class _AgendaSession {
  const _AgendaSession({
    required this.time,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
    required this.lightBackground,
    required this.darkBackground,
  });

  final String time;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;
  final Color lightBackground;
  final Color darkBackground;
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({required this.session, required this.isDark});

  final _AgendaSession session;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 65,
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            session.time,
            style: TextStyle(
              color: isDark ? const Color(0xFFAEB9C8) : const Color(0xFF8A95A3),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      Expanded(
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? session.darkBackground : session.lightBackground,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: session.color,
                  shape: BoxShape.circle,
                ),
                child: Icon(session.icon, color: Colors.white, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      session.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF24303D),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      session.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFD3DFEA)
                            : const Color(0xFF657181),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

String _monthName(int month) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[month - 1];
}

String _shortWeekday(int weekday) {
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[weekday - 1];
}

class _ScheduleNavigation extends StatelessWidget {
  const _ScheduleNavigation({
    required this.isDark,
    required this.onDestinationSelected,
  });

  final bool isDark;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return FloatingTabBar(
      selectedIndex: 1,
      onDestinationSelected: onDestinationSelected,
      items: const [
        FloatingTabItem(
          label: 'Dashboard',
          icon: Icons.space_dashboard_outlined,
          selectedIcon: Icons.space_dashboard_rounded,
        ),
        FloatingTabItem(
          label: 'Schedule',
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month_rounded,
        ),
        FloatingTabItem(
          label: 'Focus',
          icon: Icons.timer_outlined,
          selectedIcon: Icons.timer_rounded,
        ),
        FloatingTabItem(
          label: 'Tasks',
          icon: Icons.checklist_outlined,
          selectedIcon: Icons.checklist_rounded,
        ),
      ],
    );
  }
}
