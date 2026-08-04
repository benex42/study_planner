import 'package:flutter/material.dart';

import 'floating_tab_bar.dart';
import 'study_hub_app_bar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, this.onThemeToggle, this.embedded = false});

  final VoidCallback? onThemeToggle;
  final bool embedded;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  DateTime _weekStart = _startOfCalendarWeek(DateTime.now());

  void _changeWeek(int offset) {
    setState(() => _weekStart = _weekStart.add(Duration(days: offset * 7)));
  }

  String get _weekLabel {
    const months = <String>[
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
    final end = _weekStart.add(const Duration(days: 6));
    if (_weekStart.year == end.year && _weekStart.month == end.month) {
      return '${months[_weekStart.month - 1]} ${_weekStart.day}–${end.day}, '
          '${end.year}';
    }
    if (_weekStart.year == end.year) {
      return '${months[_weekStart.month - 1]} ${_weekStart.day} – '
          '${months[end.month - 1]} ${end.day}, ${end.year}';
    }
    return '${months[_weekStart.month - 1]} ${_weekStart.day}, '
        '${_weekStart.year} – ${months[end.month - 1]} ${end.day}, ${end.year}';
  }

  void _showAddSessionSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add study session',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 18),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Session title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Study session added.')),
                  );
                },
                child: const Text('Add session'),
              ),
            ),
          ],
        ),
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
        if (!widget.embedded) const StudyHubAppBar(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                28,
                16,
                // The dashboard's floating navigation intentionally overlays
                // embedded page cards instead of leaving an empty bottom gutter.
                widget.embedded ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: _ScheduleContent(
                    weekLabel: _weekLabel,
                    weekStart: _weekStart,
                    isCurrentWeek: DateUtils.isSameDay(
                      _weekStart,
                      _startOfCalendarWeek(DateTime.now()),
                    ),
                    isDark: isDark,
                    calendarHeight: constraints.maxHeight < 760 ? 740 : 860,
                    onPreviousWeek: () => _changeWeek(-1),
                    onNextWeek: () => _changeWeek(1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final pageBody = widget.embedded ? content : SafeArea(child: content);

    final addButton = FloatingActionButton(
      onPressed: _showAddSessionSheet,
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

DateTime _startOfCalendarWeek(DateTime date) {
  final calendarDay = DateUtils.dateOnly(date);
  return calendarDay.subtract(Duration(days: calendarDay.weekday - 1));
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({
    required this.weekLabel,
    required this.weekStart,
    required this.isCurrentWeek,
    required this.isDark,
    required this.calendarHeight,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final String weekLabel;
  final DateTime weekStart;
  final bool isCurrentWeek;
  final bool isDark;
  final double calendarHeight;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    final primary = isDark ? Colors.white : const Color(0xFF202328);
    final secondary = isDark
        ? const Color(0xFFABB7C7)
        : const Color(0xFF939BA8);
    final border = isDark ? const Color(0xFF384351) : const Color(0xFFC4CDDB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weekly Schedule',
          style: TextStyle(
            color: primary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(weekLabel, style: TextStyle(color: secondary, fontSize: 15)),
        const SizedBox(height: 25),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2530) : Colors.white,
            borderRadius: appSurfaceBorderRadius,
            border: Border.all(color: border, width: .5),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onPreviousWeek,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: 'Previous week',
              ),
              Expanded(
                child: Text(
                  isCurrentWeek ? 'This Week' : 'Selected Week',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                onPressed: onNextWeek,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: 'Next week',
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _ScheduleGrid(
          height: calendarHeight,
          isDark: isDark,
          weekStart: weekStart,
        ),
        const SizedBox(height: 20),
        const Wrap(
          spacing: 10,
          runSpacing: 2,
          children: [
            _LegendItem(color: Color(0xFF5AA1FA), label: 'Mathematics'),
            _LegendItem(color: Color(0xFF3FD487), label: 'Biology'),
            _LegendItem(color: Color(0xFFB46EFF), label: 'Comp Science'),
            _LegendItem(color: Color(0xFFFF657C), label: 'Physics'),
            _LegendItem(color: Color(0xFFFFB71E), label: 'History'),
          ],
        ),
      ],
    );
  }
}

class _ScheduleGrid extends StatelessWidget {
  const _ScheduleGrid({
    required this.height,
    required this.isDark,
    required this.weekStart,
  });

  final double height;
  final bool isDark;
  final DateTime weekStart;

  static const _startHour = 8;
  static const _endHour = 18;
  static const _headerHeight = 77.0;

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF3A4654) : const Color(0xFFC6CFDC);
    final gridLine = isDark ? const Color(0xFF293440) : const Color(0xFFE2E6EC);
    final label = isDark ? const Color(0xFFB7C1CF) : const Color(0xFF6E7887);

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF171F29) : Colors.white,
        borderRadius: appSurfaceBorderRadius,
        border: Border.all(color: border, width: .5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const timeWidth = 74.0;
          final dayWidth = (constraints.maxWidth - timeWidth) / 2;
          final hourHeight = (height - _headerHeight) / (_endHour - _startHour);

          return Stack(
            children: [
              Positioned(
                left: timeWidth,
                right: 0,
                top: 0,
                height: _headerHeight,
                child: Row(
                  children: [
                    Expanded(child: _DayHeader(date: weekStart)),
                    Expanded(
                      child: _DayHeader(
                        date: weekStart.add(const Duration(days: 1)),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: timeWidth,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: border),
              ),
              Positioned(
                left: timeWidth + dayWidth,
                top: 0,
                bottom: 0,
                child: Container(width: 1, color: border),
              ),
              for (var index = 0; index <= _endHour - _startHour; index++)
                Positioned(
                  left: timeWidth,
                  right: 0,
                  top: _headerHeight + hourHeight * index,
                  child: Container(height: 1, color: gridLine),
                ),
              for (var hour = _startHour; hour < _endHour; hour++)
                Positioned(
                  left: 0,
                  width: timeWidth - 10,
                  top: _headerHeight + hourHeight * (hour - _startHour) - 8,
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: label,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _CalendarEvent(
                day: 0,
                start: 8,
                duration: 2,
                time: '08:00 - 10:00',
                title: 'Mathematics',
                detail: 'Calculus II',
                color: const Color(0xFF5AA1FA),
                background: const Color(0xFFEAF3FF),
                dayWidth: dayWidth,
                hourHeight: hourHeight,
              ),
              _CalendarEvent(
                day: 1,
                start: 9,
                duration: 2,
                time: '09:00 - 11:00',
                title: 'Comp Sci',
                detail: 'Algorithms',
                color: const Color(0xFFB46EFF),
                background: const Color(0xFFF7EEFF),
                dayWidth: dayWidth,
                hourHeight: hourHeight,
              ),
              _CalendarEvent(
                day: 0,
                start: 11,
                duration: 1,
                time: '11:00 - 12:00',
                title: 'Biology',
                detail: 'Lab Report',
                color: const Color(0xFF3FD487),
                background: const Color(0xFFEAFBF2),
                dayWidth: dayWidth,
                hourHeight: hourHeight,
              ),
              _CalendarEvent(
                day: 0,
                start: 13,
                duration: 2,
                time: '13:00 - 15:00',
                title: 'Study Group',
                detail: 'Library Hall',
                color: const Color(0xFF9AAAC0),
                background: const Color(0xFFF2F5F8),
                dayWidth: dayWidth,
                hourHeight: hourHeight,
              ),
              _CalendarEvent(
                day: 1,
                start: 14,
                duration: 1.5,
                time: '14:00 - 15:30',
                title: 'Physics',
                detail: 'Quantum Intro',
                color: const Color(0xFFFF657C),
                background: const Color(0xFFFFEEF0),
                dayWidth: dayWidth,
                hourHeight: hourHeight,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          day,
          style: const TextStyle(
            color: Color(0xFF707988),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${date.day}',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }

  String get day {
    const names = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return names[date.weekday - 1];
  }
}

class _CalendarEvent extends StatelessWidget {
  const _CalendarEvent({
    required this.day,
    required this.start,
    required this.duration,
    required this.time,
    required this.title,
    required this.detail,
    required this.color,
    required this.background,
    required this.dayWidth,
    required this.hourHeight,
  });

  final int day;
  final double start;
  final double duration;
  final String time;
  final String title;
  final String detail;
  final Color color;
  final Color background;
  final double dayWidth;
  final double hourHeight;

  @override
  Widget build(BuildContext context) {
    const timeWidth = 74.0;
    const headerHeight = 77.0;
    final top = headerHeight + (start - 8) * hourHeight + 4;
    final eventHeight = duration * hourHeight - 8;

    return Positioned(
      left: timeWidth + day * dayWidth + 3,
      top: top,
      width: dayWidth - 6,
      height: eventHeight,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 11, 8, 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: appSurfaceBorderRadius,
          border: Border(left: BorderSide(color: color, width: 5)),
        ),
        child: DefaultTextStyle(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(height: 1.25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (duration > 1.25) ...[
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(color: color, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3E4755),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
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
