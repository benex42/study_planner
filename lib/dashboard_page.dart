part of 'main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
    this.taskRepository,
    this.sessionRepository,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final TaskRepository? taskRepository;
  final StudySessionRepository? sessionRepository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late final AnimationController _welcomeController;
  late final TaskRepository _taskRepository;
  late final StudySessionRepository _sessionRepository;
  String? _loadedToken;
  List<StoredTask> _tasks = [];
  List<StoredStudySession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..forward();
    _taskRepository = widget.taskRepository ?? ApiTaskRepository();
    _sessionRepository =
        widget.sessionRepository ?? ApiStudySessionRepository();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = context
        .dependOnInheritedWidgetOfExactType<AuthScope>()
        ?.notifier
        ?.accessToken;
    if (token != null && token != _loadedToken) {
      _loadedToken = token;
      _loadDashboardData(token);
    }
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentPage() async {
    if (_selectedTab == 0) {
      _welcomeController.forward(from: 0);
      final token = context
          .dependOnInheritedWidgetOfExactType<AuthScope>()
          ?.notifier
          ?.accessToken;
      if (token != null) await _loadDashboardData(token);
    }
  }

  Future<void> _loadDashboardData(String token) async {
    try {
      final results = await Future.wait([
        _taskRepository.fetchTasks(token),
        _sessionRepository.fetchUpcomingSessions(token),
      ]);
      if (!mounted || token != _loadedToken) return;
      setState(() {
        _tasks = results[0] as List<StoredTask>;
        _sessions = results[1] as List<StoredStudySession>;
      });
    } catch (_) {
      // Each linked page can still show its own error. An empty dashboard is
      // preferable to displaying invented progress or demo data.
      if (mounted && token == _loadedToken) {
        setState(() {
          _tasks = [];
          _sessions = [];
        });
      }
    }
  }

  Future<void> _setTaskCompletion(StoredTask task, bool selected) async {
    final token = context
        .dependOnInheritedWidgetOfExactType<AuthScope>()
        ?.notifier
        ?.accessToken;
    if (token == null) return;
    try {
      final updated = await _taskRepository.updateStatus(
        token,
        task.id,
        selected ? 'done' : 'todo',
      );
      if (!mounted) return;
      setState(() {
        _tasks = _tasks
            .map(
              (candidate) => candidate.id == updated.id ? updated : candidate,
            )
            .toList();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update this task.')),
        );
      }
    }
  }

  void _selectTab(int index) {
    setState(() => _selectedTab = index);
    if (index != 0) return;
    final token = context
        .dependOnInheritedWidgetOfExactType<AuthScope>()
        ?.notifier
        ?.accessToken;
    if (token != null) _loadDashboardData(token);
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = _formatSystemDate(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authScope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    final welcomeMessage = _welcomeMessageFor(authScope?.notifier?.user?.name);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF11161D)
          : const Color(0xFFF9FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  StudyHubAppBar(
                    themeMode: widget.themeMode,
                    onThemeModeChanged: widget.onThemeModeChanged,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: const Color(0xFF0768BB),
                      backgroundColor: isDark
                          ? const Color(0xFF1E252F)
                          : Colors.white,
                      onRefresh: _refreshCurrentPage,
                      child: _selectedTab == 1
                          ? const SchedulePage(embedded: true)
                          : _selectedTab == 2
                          ? const FocusPage(embedded: true)
                          : _selectedTab == 3
                          ? const TasksPage(embedded: true)
                          : ListView(
                              // Keep the content beneath the floating navigation so
                              // its rounded edge visibly crosses the cards.
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                19,
                                16,
                                16,
                              ),
                              children: [
                                Text(
                                  currentDate,
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFFACC6DE)
                                        : const Color(0xFF376182),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                _buildWelcomeMessage(isDark, welcomeMessage),
                                const SizedBox(height: 22),
                                _ProgressCard(
                                  tasks: _tasks,
                                  onViewTasks: () => _selectTab(3),
                                ),
                                const SizedBox(height: 15),
                                _SessionsCard(
                                  sessions: _sessions,
                                  onViewCalendar: () => _selectTab(1),
                                ),
                                const SizedBox(height: 15),
                                _PriorityTasksCard(
                                  tasks: _tasks,
                                  onTaskChanged: _setTaskCompletion,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _DashboardNavigation(
              selectedIndex: _selectedTab,
              isDark: isDark,
              onDestinationSelected: _selectTab,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(bool isDark, String welcomeMessage) {
    final textStyle = TextStyle(
      color: isDark ? Colors.white : const Color(0xFF23262C),
      fontSize: 33,
      fontWeight: FontWeight.w800,
      height: 1.2,
      letterSpacing: -.8,
    );

    return SizedBox(
      height: 80,
      child: AnimatedBuilder(
        animation: _welcomeController,
        builder: (context, child) {
          final progress = MediaQuery.disableAnimationsOf(context)
              ? 1.0
              : _welcomeController.value;
          final typedLength = (welcomeMessage.length * progress).floor();
          final typedMessage = welcomeMessage.substring(0, typedLength);
          final isTyping = typedLength < welcomeMessage.length;

          return Text.rich(
            _welcomeTextSpan(
              typedMessage,
              welcomeMessage,
              textStyle,
              showCursor: isTyping,
            ),
          );
        },
      ),
    );
  }

  TextSpan _welcomeTextSpan(
    String message,
    String welcomeMessage,
    TextStyle textStyle, {
    bool showCursor = false,
  }) {
    const productive = 'Productive';
    final productiveStart = welcomeMessage.indexOf(productive);
    final productiveEnd = productiveStart + productive.length;
    final normalBefore = message.substring(
      0,
      message.length.clamp(0, productiveStart),
    );
    final productiveText = message.length > productiveStart
        ? message.substring(
            productiveStart,
            message.length.clamp(productiveStart, productiveEnd),
          )
        : '';
    final normalAfter = message.length > productiveEnd
        ? message.substring(productiveEnd)
        : '';

    return TextSpan(
      style: textStyle,
      children: [
        TextSpan(text: normalBefore),
        TextSpan(
          text: productiveText,
          style: const TextStyle(color: Color(0xFF0569BC)),
        ),
        TextSpan(text: normalAfter),
        if (showCursor)
          const TextSpan(
            text: '│',
            style: TextStyle(color: Color(0xFF0569BC)),
          ),
      ],
    );
  }
}

/// Returns the first word in a user's full name for the dashboard greeting.
///
/// The fallback keeps the preview and unauthenticated dashboard friendly.
String dashboardFirstName(String? fullName) {
  final trimmedName = fullName?.trim() ?? '';
  if (trimmedName.isEmpty) return 'Aaron';
  return trimmedName.split(RegExp(r'\s+')).first;
}

String _welcomeMessageFor(String? fullName) =>
    'Let’s become\nmore Productive, ${dashboardFirstName(fullName)}';

String _formatSystemDate(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
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

  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E252F) : Colors.white,
        borderRadius: appSurfaceBorderRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF333E4D) : const Color(0xFFE5E7EC),
          width: .5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.tasks, required this.onViewTasks});

  final List<StoredTask> tasks;
  final VoidCallback onViewTasks;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completedCount = tasks.where((task) => task.status == 'done').length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;
    final message = tasks.isEmpty
        ? 'Add your first task\nto begin planning'
        : completedCount == tasks.length
        ? 'All your tasks\nare complete'
        : '${tasks.length - completedCount} task${tasks.length - completedCount == 1 ? '' : 's'}\nleft to complete';

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Progress",
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF25272C),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(22, 20, 16, 18),
            decoration: const BoxDecoration(
              borderRadius: appSurfaceBorderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0866A8), Color(0xFF034B7B)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 17),
                      _ProgressAction(onPressed: onViewTasks),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ProgressRing(progress: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 94,
            height: 94,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 13,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0x337FC6FA),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFBFE3FF)),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: 1),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressAction extends StatelessWidget {
  const _ProgressAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFBFE3FF),
          foregroundColor: const Color(0xFF075E9D),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        child: const Text('View Tasks'),
      ),
    );
  }
}

class _SessionsCard extends StatelessWidget {
  const _SessionsCard({required this.sessions, required this.onViewCalendar});

  final List<StoredStudySession> sessions;
  final VoidCallback onViewCalendar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _DashboardCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Upcoming Study\nSessions',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF25272C),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onViewCalendar,
                child: const Text(
                  'View\nCalendar',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF006CC5),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (sessions.isEmpty)
            const _DashboardEmptyMessage(
              message: 'No upcoming sessions. Plan one in your calendar.',
            )
          else
            for (final session in sessions.take(3)) ...[
              _SessionTile(session: session),
              const SizedBox(height: 9),
            ],
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final StoredStudySession session;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = session.scheduledStart.toLocal();
    final duration = session.scheduledEnd.difference(session.scheduledStart);
    final icon = switch (session.type) {
      'review' => Icons.menu_book_outlined,
      'practice' => Icons.edit_note_rounded,
      'break' => Icons.coffee_outlined,
      _ => Icons.school_outlined,
    };
    final iconColor = switch (session.type) {
      'review' => const Color(0xFF0D1846),
      'practice' => const Color(0xFF406EB7),
      'break' => const Color(0xFFE95623),
      _ => const Color(0xFF075E9D),
    };
    final iconBackgroundColor = switch (session.type) {
      'review' => const Color(0xFFE7E9F0),
      'practice' => const Color(0xFFE7EEF9),
      'break' => const Color(0xFFFDE9E1),
      _ => const Color(0xFFDDEEFF),
    };
    final title = session.notes?.trim().isNotEmpty == true
        ? session.notes!.trim()
        : '${session.type[0].toUpperCase()}${session.type.substring(1)} study';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A333F) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2A2D33),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.04,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.status == 'planned'
                      ? 'Planned study session'
                      : session.status,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFB7C1CF)
                        : const Color(0xFF687384),
                    fontSize: 10,
                    height: 1.18,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MaterialLocalizations.of(
                  context,
                ).formatTimeOfDay(TimeOfDay.fromDateTime(start)),
                style: const TextStyle(
                  color: Color(0xFF006CC5),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${duration.inMinutes} mins',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFB7C1CF)
                      : const Color(0xFF687384),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardEmptyMessage extends StatelessWidget {
  const _DashboardEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(
      message,
      style: TextStyle(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFFB7C1CF)
            : const Color(0xFF687384),
        fontSize: 13,
      ),
    ),
  );
}

class _DeadlineBanner extends StatelessWidget {
  const _DeadlineBanner({required this.task});

  final StoredTask task;

  @override
  Widget build(BuildContext context) {
    final dueDate = task.dueDate!.toLocal();
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDay = DateUtils.dateOnly(dueDate);
    final daysUntil = dueDay.difference(today).inDays;
    final timeLabel = switch (daysUntil) {
      < 0 => 'Overdue',
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $daysUntil days',
    };
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF1779D0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NEXT DEADLINE',
                  style: TextStyle(
                    color: Color(0xFFD5ECFF),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .6,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x449BD1FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              timeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityTasksCard extends StatelessWidget {
  const _PriorityTasksCard({required this.tasks, required this.onTaskChanged});
  final List<StoredTask> tasks;
  final void Function(StoredTask task, bool selected) onTaskChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final openTasks = tasks.where((task) => task.status != 'done').toList()
      ..sort((first, second) {
        const priorityOrder = {'urgent': 0, 'high': 1, 'medium': 2, 'low': 3};
        final priorityComparison = (priorityOrder[first.priority] ?? 4)
            .compareTo(priorityOrder[second.priority] ?? 4);
        if (priorityComparison != 0) return priorityComparison;
        return (first.dueDate ?? DateTime(9999)).compareTo(
          second.dueDate ?? DateTime(9999),
        );
      });
    StoredTask? nextDeadline;
    for (final task in openTasks) {
      if (task.dueDate != null) {
        nextDeadline = task;
        break;
      }
    }

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Priority Tasks',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF25272C),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          if (openTasks.isEmpty)
            const _DashboardEmptyMessage(
              message: 'No priority tasks. Add one from the Tasks tab.',
            )
          else ...[
            for (final task in openTasks.take(3))
              _TaskRow(
                task: task,
                onChanged: (value) => onTaskChanged(task, value ?? false),
              ),
            if (nextDeadline != null) ...[
              const SizedBox(height: 16),
              _DeadlineBanner(task: nextDeadline),
            ],
          ],
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onChanged});
  final StoredTask task;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 27,
            child: Checkbox(
              value: task.status == 'done',
              onChanged: onChanged,
              activeColor: const Color(0xFF0567B9),
              side: const BorderSide(color: Color(0xFF9EA9B9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                color: task.status == 'done'
                    ? const Color(0xFF9EAAB9)
                    : isDark
                    ? const Color(0xFFE7EDF5)
                    : const Color(0xFF30343B),
                fontSize: 13,
                decoration: task.status == 'done'
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardNavigation extends StatelessWidget {
  const _DashboardNavigation({
    required this.selectedIndex,
    required this.isDark,
    required this.onDestinationSelected,
  });
  final int selectedIndex;
  final bool isDark;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return FloatingTabBar(
      selectedIndex: selectedIndex,
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
