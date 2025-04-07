import 'package:flutter/material.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  final List<Ticket> _tickets = [
    Ticket(
      id: 'TKT-001',
      title: 'App crashes on startup',
      description:
          'Users reporting app crashes when opening on Android devices',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: TicketStatus.open,
      priority: TicketPriority.high,
      category: TicketCategory.bug,
    ),
    Ticket(
      id: 'TKT-002',
      title: 'Add dark mode support',
      description: 'Implement system-wide dark mode theme',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: TicketStatus.inProgress,
      priority: TicketPriority.medium,
      category: TicketCategory.feature,
    ),
    Ticket(
      id: 'TKT-003',
      title: 'Update documentation',
      description: 'Add missing API endpoints to documentation',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      status: TicketStatus.resolved,
      priority: TicketPriority.low,
      category: TicketCategory.documentation,
    ),
  ];

  TicketStatus _selectedStatus = TicketStatus.open;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatusTabs(),
          Expanded(child: _buildTicketList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final openTickets =
        _tickets.where((t) => t.status == TicketStatus.open).length;
    final inProgressTickets =
        _tickets.where((t) => t.status == TicketStatus.inProgress).length;
    final resolvedTickets =
        _tickets.where((t) => t.status == TicketStatus.resolved).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Open',
                openTickets,
                Icons.error_outline,
                Colors.red.shade400,
              ),
              _buildStatCard(
                'In Progress',
                inProgressTickets,
                Icons.pending_actions,
                Colors.orange.shade400,
              ),
              _buildStatCard(
                'Resolved',
                resolvedTickets,
                Icons.check_circle_outline,
                Colors.green.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children:
            TicketStatus.values.map((status) {
              final isSelected = status == _selectedStatus;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedStatus = status),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? status.color.withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? status.color : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        color: isSelected ? status.color : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildTicketList() {
    final filteredTickets =
        _tickets.where((ticket) => ticket.status == _selectedStatus).toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredTickets.length,
      itemBuilder: (context, index) {
        final ticket = filteredTickets[index];
        return _TicketCard(ticket: ticket);
      },
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;

  const _TicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: ticket.priority.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      ticket.priority.icon,
                      color: ticket.priority.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.priority.label,
                      style: TextStyle(
                        color: ticket.priority.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: ticket.category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ticket.category.icon,
                        color: ticket.category.color,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ticket.category.label,
                        style: TextStyle(
                          color: ticket.category.color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      ticket.id,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ticket.formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Ticket {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketCategory category;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
    required this.priority,
    required this.category,
  });

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

enum TicketStatus {
  open(Colors.red, 'Open'),
  inProgress(Colors.orange, 'In Progress'),
  resolved(Colors.green, 'Resolved');

  final MaterialColor color;
  final String label;

  const TicketStatus(this.color, this.label);
}

enum TicketPriority {
  high(Icons.priority_high, Colors.red, 'High'),
  medium(Icons.radio_button_checked, Colors.orange, 'Medium'),
  low(Icons.arrow_downward, Colors.green, 'Low');

  final IconData icon;
  final MaterialColor color;
  final String label;

  const TicketPriority(this.icon, this.color, this.label);
}

enum TicketCategory {
  bug(Icons.bug_report, Colors.red, 'Bug'),
  feature(Icons.lightbulb, Colors.green, 'Feature'),
  documentation(Icons.description, Colors.blue, 'Docs');

  final IconData icon;
  final MaterialColor color;
  final String label;

  const TicketCategory(this.icon, this.color, this.label);
}
