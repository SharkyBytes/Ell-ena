import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  final Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Add sample events
    final today = DateTime.now();
    _events[today] = [
      CalendarEvent(
        title: 'Team Meeting',
        startTime: TimeOfDay(hour: 10, minute: 0),
        endTime: TimeOfDay(hour: 11, minute: 0),
        type: EventType.meeting,
      ),
      CalendarEvent(
        title: 'Design Review',
        startTime: TimeOfDay(hour: 14, minute: 0),
        endTime: TimeOfDay(hour: 15, minute: 30),
        type: EventType.task,
      ),
    ];
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [_buildCalendar(), Expanded(child: _buildTimeScale())],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2025, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: _getEventsForDay,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        calendarStyle: const CalendarStyle(
          defaultTextStyle: TextStyle(color: Colors.white),
          weekendTextStyle: TextStyle(color: Colors.white70),
          selectedTextStyle: TextStyle(color: Colors.black),
          todayTextStyle: TextStyle(color: Colors.black),
          outsideTextStyle: TextStyle(color: Colors.white38),
          selectedDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: Colors.greenAccent,
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: Colors.white),
          weekendStyle: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildTimeScale() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 24,
      itemBuilder: (context, index) {
        final hour = index;
        final time = TimeOfDay(hour: hour, minute: 0);
        final events = _getEventsForHour(hour);

        return InkWell(
          onTap: () {
            setState(() => _selectedTime = time);
            _showCreateDialog(time);
          },
          child: Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 1),
            child: Row(
              children: [
                SizedBox(
                  width: 50,
                  child: Text(
                    '${time.format(context).toLowerCase()}',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.grey.shade800,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Stack(
                      children: [
                        ...events.map((event) => _buildEventCard(event)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<CalendarEvent> _getEventsForHour(int hour) {
    if (_selectedDay == null) return [];
    final dayEvents = _getEventsForDay(_selectedDay!);
    return dayEvents.where((event) => event.startTime.hour == hour).toList();
  }

  Widget _buildEventCard(CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: event.type.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: event.type.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(event.type.icon, color: event.type.color, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              event.title,
              style: TextStyle(
                color: event.type.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${event.startTime.format(context)} - ${event.endTime.format(context)}',
            style: TextStyle(color: event.type.color, fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(TimeOfDay selectedTime) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D2D),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Create at ${selectedTime.format(context)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogOption(
                  'Schedule a Meeting',
                  Icons.people,
                  Colors.blue,
                  () => _handleCreate(EventType.meeting),
                ),
                const SizedBox(height: 8),
                _buildDialogOption(
                  'Create a Task',
                  Icons.task,
                  Colors.green,
                  () => _handleCreate(EventType.task),
                ),
                const SizedBox(height: 8),
                _buildDialogOption(
                  'Create a Ticket',
                  Icons.confirmation_number,
                  Colors.orange,
                  () => _handleCreate(EventType.ticket),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildDialogOption(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCreate(EventType type) {
    // TODO: Implement creation logic based on type
    Navigator.of(context).pop();
  }
}

class CalendarEvent {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final EventType type;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
  });
}

enum EventType {
  meeting(Icons.people, Colors.blue, 'Meeting'),
  task(Icons.task, Colors.green, 'Task'),
  ticket(Icons.confirmation_number, Colors.orange, 'Ticket');

  final IconData icon;
  final MaterialColor color;
  final String label;

  const EventType(this.icon, this.color, this.label);
}
