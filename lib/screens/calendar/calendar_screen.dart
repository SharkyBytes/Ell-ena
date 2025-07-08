import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../tasks/create_task_screen.dart';
import '../tickets/create_ticket_screen.dart';
import '../meetings/create_meeting_screen.dart';
import '../../services/supabase_service.dart';
import '../meetings/meeting_detail_screen.dart';
import '../tasks/task_detail_screen.dart';
import '../tickets/ticket_detail_screen.dart';

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
  final _supabaseService = SupabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Clear existing events
      _events.clear();
      
      // Load tasks
      final tasks = await _supabaseService.getTasks();
      for (var task in tasks) {
        if (task['due_date'] != null) {
          final dueDate = DateTime.parse(task['due_date']);
          final dateOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
          
          if (!_events.containsKey(dateOnly)) {
            _events[dateOnly] = [];
          }
          
          _events[dateOnly]!.add(CalendarEvent(
            title: task['title'] ?? 'Untitled Task',
            startTime: const TimeOfDay(hour: 23, minute: 0),
            endTime: const TimeOfDay(hour: 23, minute: 59),
            type: EventType.task,
            id: task['id'],
          ));
        }
      }
      
      // Load tickets
      final tickets = await _supabaseService.getTickets();
      for (var ticket in tickets) {
        if (ticket['created_at'] != null) {
          final createdAt = DateTime.parse(ticket['created_at']);
          final dateOnly = DateTime(createdAt.year, createdAt.month, createdAt.day);
          
          if (!_events.containsKey(dateOnly)) {
            _events[dateOnly] = [];
          }
          
          _events[dateOnly]!.add(CalendarEvent(
            title: ticket['title'] ?? 'Untitled Ticket',
            startTime: TimeOfDay(hour: createdAt.hour, minute: createdAt.minute),
            endTime: TimeOfDay(hour: createdAt.hour + 1, minute: createdAt.minute),
            type: EventType.ticket,
            id: ticket['id'],
          ));
        }
      }
      
      // Load meetings
      final meetings = await _supabaseService.getMeetings();
      for (var meeting in meetings) {
        if (meeting['meeting_date'] != null) {
          final meetingDate = DateTime.parse(meeting['meeting_date']);
          final dateOnly = DateTime(meetingDate.year, meetingDate.month, meetingDate.day);
          
          if (!_events.containsKey(dateOnly)) {
            _events[dateOnly] = [];
          }
          
          // For meetings, assume 1 hour duration
          _events[dateOnly]!.add(CalendarEvent(
            title: meeting['title'] ?? 'Untitled Meeting',
            startTime: TimeOfDay(hour: meetingDate.hour, minute: meetingDate.minute),
            endTime: TimeOfDay(hour: meetingDate.hour + 1, minute: meetingDate.minute),
            type: EventType.meeting,
            id: meeting['id'],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
    return GestureDetector(
      onTap: () => _handleEventTap(event),
      child: Container(
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
            const SizedBox(width: 4),
            Icon(
              Icons.edit,
              color: event.type.color,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEventTap(CalendarEvent event) async {
    dynamic result;
    
    switch (event.type) {
      case EventType.meeting:
        // Navigate to meeting detail screen
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingDetailScreen(meetingId: event.id),
          ),
        );
        break;
      case EventType.task:
        // Navigate to task detail screen
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailScreen(taskId: event.id),
          ),
        );
        break;
      case EventType.ticket:
        // Navigate to ticket detail screen
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketDetailScreen(ticketId: event.id),
          ),
        );
        break;
    }
    
    // Refresh events if something was updated
    if (result == true) {
      await _loadEvents();
    }
  }

  void _showCreateDialog(TimeOfDay selectedTime) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
              () => _handleCreate(EventType.meeting, selectedTime),
            ),
            const SizedBox(height: 8),
            _buildDialogOption(
              'Create a Task',
              Icons.task,
              Colors.green,
              () => _handleCreate(EventType.task, selectedTime),
            ),
            const SizedBox(height: 8),
            _buildDialogOption(
              'Create a Ticket',
              Icons.confirmation_number,
              Colors.orange,
              () => _handleCreate(EventType.ticket, selectedTime),
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

  Future<void> _handleCreate(EventType type, TimeOfDay selectedTime) async {
    Navigator.of(context).pop(); // Close dialog
    
    if (_selectedDay == null) return;
    
    final selectedDateTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    
    dynamic result;
    
    switch (type) {
      case EventType.meeting:
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateMeetingScreen(),
          ),
        );
        break;
      case EventType.task:
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateTaskScreen(),
          ),
        );
        break;
      case EventType.ticket:
        result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CreateTicketScreen(),
          ),
        );
        break;
    }
    
    // Refresh events if something was created
    if (result == true) {
      await _loadEvents();
    }
  }
}

class CalendarEvent {
  final String title;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final EventType type;
  final String id;

  CalendarEvent({
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.id,
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
