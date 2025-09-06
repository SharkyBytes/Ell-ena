import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class MeetingInsightsScreen extends StatefulWidget {
  final String meetingId;
  final String initialTab; // 'transcript' or 'summary'

  const MeetingInsightsScreen({super.key, required this.meetingId, this.initialTab = 'transcript'});

  @override
  State<MeetingInsightsScreen> createState() => _MeetingInsightsScreenState();
}

class _MeetingInsightsScreenState extends State<MeetingInsightsScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();
  bool _isLoading = true;
  Map<String, dynamic>? _meeting; // includes final_transcription and meeting_summary_json
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTab == 'summary' ? 1 : 0);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final details = await _supabase.getMeetingDetails(widget.meetingId);
      if (mounted) {
        setState(() {
          _meeting = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load meeting: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Meeting Insights'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Transcription'),
            Tab(text: 'AI Summary'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTranscriptView(),
                _buildSummaryView(),
              ],
            ),
    );
  }

  Widget _buildTranscriptView() {
    final segments = _meeting?['final_transcription'];
    if (segments == null || segments is! List || segments.isEmpty) {
      return Center(
        child: Text(
          'No transcription available',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: segments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final Map seg = Map<String, dynamic>.from(segments[index] as Map);
        final speaker = (seg['speaker']?.toString() ?? 'Speaker');
        final text = (seg['text']?.toString() ?? '');
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.green.shade700,
                child: Text(
                  speaker.isNotEmpty ? speaker[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      text,
                      style: const TextStyle(color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryView() {
    final summary = _meeting?['meeting_summary_json'];
    if (summary == null || summary is! Map || summary.isEmpty) {
      return Center(
        child: Text(
          'No AI summary generated yet',
          style: TextStyle(color: Colors.grey.shade400),
        ),
      );
    }

    List<Widget> section(String title, List<Widget> children) => [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...children,
          const SizedBox(height: 16),
        ];

    Widget bullets(List list) {
      if (list.isEmpty) return const SizedBox();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List<Widget>.generate(list.length, (i) {
          final text = list[i]?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(color: Colors.white70)),
                Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
              ],
            ),
          );
        }),
      );
    }

    Widget actionItems(List items) {
      if (items.isEmpty) return const SizedBox();
      return Column(
        children: items.map<Widget>((it) {
          final map = Map<String, dynamic>.from(it as Map);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(map['item']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        'Owner: ${map['owner'] ?? '—'}   •   Deadline: ${map['deadline'] ?? 'N/A'}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    final keyPoints = (summary['key_discussion_points'] as List?) ?? [];
    final decisions = (summary['important_decisions'] as List?) ?? [];
    final actions = (summary['action_items'] as List?) ?? [];
    final highlights = (summary['meeting_highlights'] as List?) ?? [];
    final followUps = (summary['follow_up_tasks'] as List?) ?? [];
    final overall = summary['overall_summary']?.toString() ?? '';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...section('Key Discussion Points', [bullets(keyPoints)]),
        ...section('Important Decisions', [bullets(decisions)]),
        ...section('Action Items', [actionItems(actions)]),
        ...section('Meeting Highlights', [bullets(highlights)]),
        ...section('Follow-up Tasks', [actionItems(followUps.map((e) => {'item': e['task'], 'owner': '', 'deadline': e['deadline']}).toList())]),
        Text('Overall Summary', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF2D2D2D), borderRadius: BorderRadius.circular(8)),
          child: Text(overall, style: const TextStyle(color: Colors.white70, height: 1.4)),
        ),
      ],
    );
  }
}


