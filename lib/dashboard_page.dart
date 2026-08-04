part of 'main.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final Set<int> _completedTasks = {2};
  static const _welcomeMessage = 'Let’s become\nmore Productive, Aaron';
  int _selectedTab = 0;
  late final AnimationController _welcomeController;

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    )..forward();
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _refreshCurrentPage() async {
    if (_selectedTab == 0) {
      _welcomeController.forward(from: 0);
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentDate = _formatSystemDate(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                                _buildWelcomeMessage(isDark),
                                const SizedBox(height: 22),
                                _ProgressCard(
                                  onViewTasks: () =>
                                      setState(() => _selectedTab = 3),
                                ),
                                const SizedBox(height: 15),
                                _SessionsCard(
                                  onViewCalendar: () =>
                                      setState(() => _selectedTab = 1),
                                ),
                                const SizedBox(height: 15),
                                _PriorityTasksCard(
                                  completedTasks: _completedTasks,
                                  onTaskChanged: (index, value) {
                                    setState(() {
                                      if (value ?? false) {
                                        _completedTasks.add(index);
                                      } else {
                                        _completedTasks.remove(index);
                                      }
                                    });
                                  },
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
              onDestinationSelected: (index) {
                setState(() => _selectedTab = index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeMessage(bool isDark) {
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
          final typedLength = (_welcomeMessage.length * progress).floor();
          final typedMessage = _welcomeMessage.substring(0, typedLength);
          final isTyping = typedLength < _welcomeMessage.length;

          return Text.rich(
            _welcomeTextSpan(typedMessage, textStyle, showCursor: isTyping),
          );
        },
      ),
    );
  }

  TextSpan _welcomeTextSpan(
    String message,
    TextStyle textStyle, {
    bool showCursor = false,
  }) {
    const productive = 'Productive';
    final productiveStart = _welcomeMessage.indexOf(productive);
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
  const _ProgressCard({required this.onViewTasks});

  final VoidCallback onViewTasks;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      const Text(
                        'Great, your plan\nis almost done',
                        style: TextStyle(
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
                const _ProgressRing(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing();

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
              value: .8,
              strokeWidth: 13,
              strokeCap: StrokeCap.round,
              backgroundColor: const Color(0x337FC6FA),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFBFE3FF)),
            ),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '80%',
                style: TextStyle(
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
  const _SessionsCard({required this.onViewCalendar});

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
          const _SessionTile(
            icon: Icons.menu_book_outlined,
            iconColor: Color(0xFF0D1846),
            iconBackgroundColor: Color(0xFFE7E9F0),
            title: 'Data Structures &\nAlgorithms',
            subtitle: 'Group Review • Library\nHall B',
            time: '14:00',
            duration: '60 mins',
          ),
          const SizedBox(height: 9),
          const _SessionTile(
            icon: Icons.functions_rounded,
            iconColor: Color(0xFF406EB7),
            iconBackgroundColor: Color(0xFFE7EEF9),
            title: 'Calculus III:\nIntegration',
            subtitle: 'Solo Session • Home\nOffice',
            time: '16:30',
            duration: '90 mins',
          ),
          const SizedBox(height: 9),
          const _SessionTile(
            icon: Icons.history_edu_outlined,
            iconColor: Color(0xFFE95623),
            iconBackgroundColor: Color(0xFFFDE9E1),
            title: 'Modern History\nSeminar',
            subtitle: 'Online Workshop',
            time: '19:00',
            duration: '45 mins',
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.duration,
  });
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final String subtitle;
  final String time;
  final String duration;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  subtitle,
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
                time,
                style: const TextStyle(
                  color: Color(0xFF006CC5),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                duration,
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

class _PriorityTasksCard extends StatelessWidget {
  const _PriorityTasksCard({
    required this.completedTasks,
    required this.onTaskChanged,
  });
  final Set<int> completedTasks;
  final void Function(int index, bool? value) onTaskChanged;

  @override
  Widget build(BuildContext context) {
    const tasks = [
      'Complete Physics Lab Report',
      'Read Chapter 4 of Sociology',
      'Submit French Essay',
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          for (var index = 0; index < tasks.length; index++)
            _TaskRow(
              label: tasks[index],
              complete: completedTasks.contains(index),
              onChanged: (value) => onTaskChanged(index, value),
            ),
          const SizedBox(height: 16),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1779D0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT DEADLINE',
                        style: TextStyle(
                          color: Color(0xFFD5ECFF),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: .6,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Final Project',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x449BD1FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '2 Days Left',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.label,
    required this.complete,
    required this.onChanged,
  });
  final String label;
  final bool complete;
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
              value: complete,
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
              label,
              style: TextStyle(
                color: complete
                    ? const Color(0xFF9EAAB9)
                    : isDark
                    ? const Color(0xFFE7EDF5)
                    : const Color(0xFF30343B),
                fontSize: 13,
                decoration: complete ? TextDecoration.lineThrough : null,
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
